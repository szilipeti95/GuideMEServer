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
    guard let user = request.authorizedUser,
      let conversationId = Int(request.parameters["conversationId"] ?? "error") else {
        return
    }

    guard let conversations = DBConversationModel.getConversations(forEmail: user.email),
          conversations.first(where: { $0.id == conversationId }) != nil else {
      try response.send(status: .badRequest).end(); next()
      return
    }
    if let dbMessages = DBMessageModel.getMessages(for: conversationId) {
      let messages = dbMessages.map { MessageDTO.builder(dbMessage: $0) }.sorted(by: { $0.timestamp < $1.timestamp })
      try response.send(json: messages).end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func readMessages(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let user = request.authorizedUser,
      let conversationId = Int(request.parameters["conversationId"] ?? "error") else {
        return
    }
    if DBMessageModel.updateReadMessages(for: conversationId, email: user.email) {
      try response.send("Success").end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func getConversations(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let user = request.authorizedUser else { return }

    if let dbConversations = DBConversationModel.getConversations(forEmail: user.email, approved: nil) {
      var conversations: [ConversationDTO] = []
      try dbConversations.forEach { dbConversation in
        let conversation = try ConversationDTO.builder(dbConversation: dbConversation, forUser: user)
        conversations.append(conversation)
      }
      conversations.sort(by: { $0.lastMessage.timestamp > $1.lastMessage.timestamp })
      try response.send(json: conversations).end(); next()
    } else {
      try response.send(status: .internalServerError).end(); next()
    }
  }

  fileprivate func approveConversation(request: RouterRequest, response: RouterResponse, next: @escaping (() -> Void)) throws {
    guard let user = request.authorizedUser else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let conversationId = Int(request.parameters["conversationId"] ?? "error") else {
      response.send("").status(.badRequest); next()
      return
    }

    if var unapprovedConversation = DBConversationModel.getUnapprovedConversation(conversationId: conversationId, email: user.email),
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
    guard let user = request.authorizedUser else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let conversationId = Int(request.parameters["conversationId"] ?? "error") else {
        response.send("").status(.badRequest); next()
        return
    }

    if let unapprovedConversation = DBConversationModel.getUnapprovedConversation(conversationId: conversationId, email: user.email),
      let conversationId = unapprovedConversation.id {
      DBConversationModel.delete(id: conversationId) { error in
        if let error = error {
          print(error.reason)
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
    guard let user = request.authorizedUser else {
      response.send("").status(.unauthorized); next()
      return
    }
    guard let otherEmail = request.parameters["email"],
      let message: MessageDTO = request.body?.asObject() else {
        response.send("").status(.badRequest); next()
        return
    }

    let dbConversation = DBConversationModel(id: nil, user1: user.email, user2: otherEmail, approved: 0)
    dbConversation.save { (id: Int?, result: DBConversationModel?, error: RequestError?) in
      if let error = error {
        print(error.reason)
        try? response.send(status: .internalServerError).end(); next()
      } else if let id = id {
        let dbMessage = DBMessageModel(messageId: nil,
                                       conversationId: id,
                                       senderEmail: user.email,
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
