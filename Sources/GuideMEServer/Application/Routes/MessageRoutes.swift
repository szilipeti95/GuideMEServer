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
  /*
  app.router.get(Paths.userSelf, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.get(Paths.userSelf, handler: app.getUserHandler)
  app.router.put(Paths.userSelfUpdate, middleware: BodyParser())
  app.router.put(Paths.userSelfUpdate, allowPartialMatch: false, middleware: JWTMiddleware())
  app.router.put(Paths.userSelfUpdate, handler: app.updateUserInfoHandler)
 */
}

extension Backend {


  fileprivate func getConversetions(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
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
            guard let conversationId = row["conversation_id"] as? String,
                  let user1 = row["user_1"] as? String else {
              return
            }
            let selectMessageQuery = Select(from: messageTable).where(messageTable.conversationId == conversationId).order(by: .DESC(messageTable.timestamp)).limit(to: 1)
            guard let otherEmail = (user1 == email ? row[DBConversationColumnNames.user2] : row[DBConversationColumnNames.user1]) as? String else {
              return
            }
            let selectUserQuery = Select(from: userTable).where(userTable.email == otherEmail)
            connection.execute(query: selectMessageQuery) { selectMessageResult in
              guard let message = selectMessageResult.asRows?.first else {
                return
              }
              connection.execute(query: selectUserQuery) { selectUserResult in
                guard let user = selectUserResult.asRows?.first else {
                  return
                }
                let otherUser = User(username: user[DBUserColumnNames.username] as! String,
                                     email: user[DBUserColumnNames.email] as! String,
                                     firstName: user[DBUserColumnNames.firstName] as! String,
                                     lastName: user[DBUserColumnNames.lastName] as! String,
                                     regDate: user[DBUserColumnNames.regDate] as! Int32,
                                     avatar: user[DBUserColumnNames.avatar] as? String,
                                     backgroundAvatar: user[DBUserColumnNames.backgroundAvatar] as? String)
                let lastMessage = Message(message: message[DBMessageColumnNames.messageBody] as! String,
                                          timestamp: message[DBMessageColumnNames.timestamp] as! Int32)
                let conversation = Conversation(user: otherUser,
                                                lastMessage: lastMessage,
                                                approved: true)
                conversations.append(conversation)
              }
            }
          }
          do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(conversations)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            response.send(jsonString)
            next()
          } catch let decodeError {
            print("Error during JSON decoding: \(decodeError.localizedDescription)")
            response.send("").status(.internalServerError)
            next()
          }
        }
      }
    }
  }
  /*
  fileprivate func getUserHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == email)

    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          print(selectResult.asError as Any)
          return
        }
        let userResponse = User(dict: selected)
        try? response.send(userResponse.toJson()).end()
      }
    } else {
      try? response.send("Error").status(.internalServerError).end()
    }
  }

  fileprivate func findUserByNameContaining(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authenticatedUser else {
      return

    }
  }

  fileprivate func updateUserInfoHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authenticatedUser else {
      return
    }
    let userTable = DBUser()
    let selectQuery = Select(from: userTable).where(userTable.email == email)

    guard let body = request.body?.asJSON else {
      response.send("Error").status(.badRequest)
      next()
      return
    }
    let updateUser = User(dict: body)
    if let connection = pool.getConnection() {
      connection.execute(query: selectQuery) { selectResult in
        guard selectResult.success, let selected = selectResult.asRows?.first else {
          response.send("Error").status(.internalServerError)
          return
        }
        var user = DBUserObject.convertFrom(dict: selected)
        user.firstName = updateUser.firstName
        user.lastName = updateUser.lastName
        user.username = updateUser.username
        user.email = updateUser.email
        let updateQuery = Update(userTable, set: user.foo()).where(userTable.email == email)
        connection.execute(query: updateQuery) { updateResult in
          guard updateResult.success else {
            response.send("Error").status(.internalServerError)
            next()
            return
          }
          response.send("sendUser.toJson()")
          next()
        }
      }
    }
  }
   fileprivate func updateUserPasswordHandler(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
   guard try validateJwtIn(request: request), let header = request.headers["Authorization"] else {
   response.send("Authorization Error")
   next()
   return
   }

   let username = try JWT.decode(header)?.claims[.nickname] as! String
   guard let password = request.body?.asJSON?["password"] as? String else {
   response.send("No body")
   next()
   return
   }

   let user = DBUser()
   let selectQuery = Select(from: user).where(user.username == username)
   }
   */
}
