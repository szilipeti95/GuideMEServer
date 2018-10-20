//
//  MessageRoutes.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 13..
//

import Foundation
import Kitura
import SwiftJWT
import SwiftKuery
import SwiftKueryMySQL

func addMessageRoutes(app: Backend) {
  app.router.get(Paths.conversation, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.conversation, handler: app.getConversations)

  app.router.get(Paths.message, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.message, handler: app.getMessages)

  app.router.put(Paths.messagesRead, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.put(Paths.messagesRead, handler: app.readMessages)
}

extension Backend {

  fileprivate func getMessages(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
          let conversationId = request.parameters["conversationId"] else {
      return
    }
    //TODO: ELLENŐRZÉS HOGY A SAJÁT CONVOJA E AZ EMAILNEK
    let messageTable = DBMessage()
    let selectQuery = Select(from: messageTable).where(messageTable.conversationId == conversationId).order(by: .ASC(messageTable.timestamp))

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard let messages = Message.arrayFrom(queryResult: selectResult) else {
          response.send("").status(.internalServerError); next()
          return
        }
        guard let jsonData = try? JSONEncoder().encode(messages) else {
          print("Error during JSON decoding")
          response.send("").status(.internalServerError); next()
          return
        }
        let jsonString = String(data: jsonData, encoding: .utf8)!
        response.send(jsonString); next()
      }
    }
  }

  fileprivate func readMessages(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
          let conversationId = request.parameters["conversationId"] else {
      return
    }
    let messageTable = DBMessage()
    let updateQuery = Update(messageTable, set: [(messageTable.read, 1)]).where(messageTable.conversationId == conversationId && messageTable.senderEmail != email)
    if let connection = pool.getConnection() {
      connection.execute(query: updateQuery) { updateResult in
        if updateResult.asError != nil {
          response.send("Error").status(.internalServerError); next()
        } else {
          response.send("Ok").status(.internalServerError); next()
        }
      }
    }
  }

  fileprivate func newConvos(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    let messageTable = DBMessage()
    let conversationTable = DBConversation()
    let selectQuery = Select(from: messageTable).leftJoin(conversationTable).on(messageTable.conversationId == conversationTable.conversationId).where(conversationTable.user1 == email || conversationTable.user2 == email)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard let rows = selectResult.asRows else {
          return
        }
        var convos = [Conversation]()
        for row in rows {
          guard let user1 = row["user_1"] as? String else {
            return
          }
          guard let otherEmail = (user1 == email ? row[DBConversationColumnNames.user2] : row[DBConversationColumnNames.user1]) as? String else {
            return
          }
          let userTable = DBUser()
          let selectUserQuery = Select(from: userTable).where(userTable.email == otherEmail)
          connection.execute(query: selectUserQuery) { selectUserResult in
            guard let user = selectUserResult.asRows?.first else {
              return
            }
            let otherUser = User(dict: user)
            let lastMessage = Message(dict: row)
            let conversationId = Int(row["conversation_id"] as! Int64)
            let conversation = Conversation(id: conversationId,
                                            user: otherUser,
                                            lastMessage: lastMessage,
                                            approved: true,
                                            read: true)
            convos.append(conversation)
          }
        }
        guard let jsonData = try? JSONEncoder().encode(convos) else {
          print("Error during JSON decoding")
          response.send("").status(.internalServerError)
          next()
          return
        }
        let jsonString = String(data: jsonData, encoding: .utf8)!
        response.send(jsonString)
        next()
      }
    }
  }
  fileprivate func getConversations(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    let conversationTable = DBConversation()
    let messageTable = DBMessage()
    let userTable = DBUser()
    let selectQuery = Select(from: conversationTable).where(conversationTable.user1 == email || conversationTable.user2 == email)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        if let rows = selectResult.asRows {
          var conversations = [Conversation]()
          for row in rows {
            guard let conversationId = row["conversation_id"] as? Int64,
                  let user1 = row["user_1"] as? String else {
              return
            }
            let selectMessageQuery = Select(from: messageTable).where(messageTable.conversationId == Int(conversationId)).order(by: .DESC(messageTable.timestamp))
            guard let otherEmail = (user1 == email ? row[DBConversationColumnNames.user2] : row[DBConversationColumnNames.user1]) as? String else {
              return
            }
            let selectUserQuery = Select(from: userTable).where(userTable.email == otherEmail)
            connection.execute(query: selectMessageQuery) { selectMessageResult in
              guard let messages = Message.arrayFrom(queryResult: selectMessageResult) else {
                return
              }
              connection.execute(query: selectUserQuery) { selectUserResult in
                guard let userDict = selectUserResult.asRows?.first else {
                  return
                }
                var read = true
                for msg in messages where msg.read == false && msg.sender == otherEmail {
                  read = false
                }
                guard let lastMessage = messages.first else {
                  return
                }
                let otherUser = User.init(dict: userDict)
                let approved = Bool(row["approved"] as! Int32)
                let conversation = Conversation(id: Int(conversationId),
                                                user: otherUser,
                                                lastMessage: lastMessage,
                                                approved: approved,
                                                read: read)
                conversations.append(conversation)
              }
            }
          }
          guard let jsonData = try? JSONEncoder().encode(conversations) else {
            print("Error during JSON decoding")
            response.send("").status(.internalServerError)
            next()
            return
          }
          let jsonString = String(data: jsonData, encoding: .utf8)!
          response.send(jsonString)
          next()
        }
      }
    }
  }
}
