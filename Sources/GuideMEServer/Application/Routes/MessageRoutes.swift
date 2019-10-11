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

  app.router.post(Paths.approveConversation, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post(Paths.approveConversation, handler: app.approveConversation)

  app.router.post(Paths.denyConversation, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post(Paths.denyConversation, handler: app.denyConversation)

  app.router.post(Paths.createConversation, middleware: BodyParser())
  app.router.post(Paths.createConversation, allowPartialMatch: false, middleware: app.tokenCredentials)
  app.router.post(Paths.createConversation, handler: app.createConversation)
}

extension Backend {

  fileprivate func getMessages(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard request.authorizedUser != nil,
      let conversationId = request.parameters["conversationId"],
      let conversationIdInt = Int(conversationId) else {
        return
    }
    //TODO: ELLENŐRZÉS HOGY A SAJÁT CONVOJA E AZ EMAILNEK
    if let messages = DBMessageModel.getMessagesAscending(for: conversationIdInt) {
      try response.send(json: messages).end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func readMessages(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser,
      let conversationIdString = request.parameters["conversationId"],
      let conversationId = Int(conversationIdString) else {
        return
    }

    if DBMessageModel.updateReadMessages(for: conversationId, email: email) {
      try response.send("Success").end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func getConversations(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      return
    }

    if let dbConversations = DBConversationModel.getConversations(forEmail: email, approved: nil) {
      var conversations: [ConversationDTO] = []
      try dbConversations.forEach { dbConversation in
        let otherEmail = dbConversation.user1 == email ? dbConversation.user2 : dbConversation.user1
        guard let otherUser = self.getUserData(for: otherEmail),
          let conversationId = dbConversation.id,
          let lastMessage = DBMessageModel.getLastMessage(for: conversationId) else {
            try response.send(status: .internalServerError).end(); next()
            return
        }
        let conversation = ConversationDTO(dbConversation: dbConversation, user: otherUser, dbLastMessage: lastMessage)
        conversations.append(conversation)
      }
      conversations.sort(by: { $0.lastMessage.timestamp > $1.lastMessage.timestamp })
      try response.send(json: conversations).end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func approveConversation(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let conversationIdString = request.parameters["conversationId"],
      let conversationId = Int(conversationIdString) else {
      response.send("").status(.badRequest); next()
      return
    }

    if var unapprovedConversation = DBConversationModel.getUnapprovedConversation(conversationId: conversationId, email: email),
      let conversationId = unapprovedConversation.id {
      unapprovedConversation.approved = 1
      unapprovedConversation.update(id: conversationId) { result, error in
        if let error = error {
          print(error)
          try? response.send(status: .internalServerError).end(); next()
        } else if result != nil {
          try? response.send(status: .OK).end(); next()
        }
      }
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func denyConversation(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let conversationIdString = request.parameters["conversationId"],
      let conversationId = Int(conversationIdString) else {
        response.send("").status(.badRequest); next()
        return
    }

    if let unapprovedConversation = DBConversationModel.getUnapprovedConversation(conversationId: conversationId, email: email),
      let conversationId = unapprovedConversation.id {
      DBConversationModel.delete(id: conversationId) { error in
        if let error = error {
          print(error)
          try? response.send(status: .internalServerError).end(); next()
        } else {
          try? response.send(status: .OK).end(); next()
        }
      }
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func createConversation(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let email = request.authorizedUser else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let otherEmail = request.parameters["email"],
      let message: MessageDTO = request.body?.asObject() else {
        response.send("").status(.badRequest); next()
        return
    }

    let dbConversation = DBConversationModel(id: nil, user1: email, user2: otherEmail, approved: 0)
    dbConversation.save { (id: Int?, result: DBConversationModel?, error: RequestError?) in
      if let error = error {
        print(error)
        try? response.send(status: .internalServerError).end(); next()
      } else if let id = id {
        let dbMessage = DBMessageModel(messageId: nil,
                                       conversationId: id,
                                       senderEmail: email,
                                       messageBody: message.message,
                                       timestamp: Date().millisecondsSince1970,
                                       read: 0)
        dbMessage.save { result, error in
          if let error = error {
            print(error)
            try? response.send(status: .internalServerError).end(); next()
          } else {
            try? response.send(status: .OK).end(); next()
          }
        }
      } else {
        try? response.send(status: .internalServerError).end(); next()
      }
    }
  }
}
