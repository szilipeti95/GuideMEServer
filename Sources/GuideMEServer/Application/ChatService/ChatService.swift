//
//  ChatService.swift
//  Application
//
//  Created by Szili Péter on 2018. 10. 06..
//

/*
 TODO: RENAME SENDER / RECEIVER
 */

import Dispatch
import Foundation
import KituraWebSocket
import SwiftKuery
import SwiftKueryMySQL

public class ChatService: WebSocketService {

  private let connectionsLock = DispatchSemaphore(value: 1)

  #if os(Linux)
  let sqlUser = "app"
  let sqlPassword = "ppa"
  let sqlHost = "localhost"
  #else
  let sqlUser = "internalAPI"
  let sqlPassword = "IPAlanretni"
  let sqlHost = "127.0.0.1"
  #endif
  let sqlPort = 4306
  let sqlDatabase = "guideme_new"
  let pool: ConnectionPool!

  internal var connections = [String: ChatConnectionData]()

  public init() {
    pool = MySQLConnection.createPool(url: URL(string: "mysql://\(sqlUser):\(sqlPassword)@\(sqlHost):\(sqlPort)/\(sqlDatabase)")!,
                                      poolOptions: ConnectionPoolOptions(initialCapacity: 10,
                                                                         maxCapacity: 50))
  }

  enum MessageType: String {
    case becomeOnline = "becomeOnline"
    case onlinePeople = "onlinePeople"
    case openedChat = "openedChat"  
    case startedWriting = "startedWriting"
    case stoppedWriting = "stoppedWriting"
    case closedChat = "closedChat"
    case becameOffline = "becameOffline"
    case wroteMessage = "wroteMessage"
  }

  public func connected(connection: WebSocketConnection) {
    print("Socket connected: \(connection.id)")
  }

  public func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
    guard let senderEmail = connections[connection.id]?.email else {
      return
    }
    print("Socket disconneted: \(senderEmail)")
    let receivers = getOnlineFriends(forEmail: senderEmail)
    lockConnectionsLock()
    if connections.removeValue(forKey: connection.id) != nil {
      for connectionData in receivers {
        let message = ServiceObjectDTO(type: MessageType.becameOffline.rawValue,
                                    sender: senderEmail,
                                    timestamp: Int(Date().timeIntervalSince1970),
                                    payload: nil)
        if let data = try? JSONEncoder().encode(message) {
          connectionData.connection.send(message: data)
        }
      }
    }
    unlockConnectionsLock()
  }

  public func received(message: Data, from connection: WebSocketConnection) {
    guard let serviceObject = try? JSONDecoder().decode(ServiceObjectDTO.self, from: message) else {
      print("Error decoding object")
      return
    }
    print("Socket received: \(serviceObject.description)")
    if let payload = serviceObject.payload {
      switch serviceObject.type {
      case MessageType.openedChat.rawValue:
        openedChatHandler(otherEmail: payload, from: connection)
      case MessageType.wroteMessage.rawValue:
        wroteMessageHandler(message: payload, from: connection)
      default:
        invalidData(from: connection, description: "Invalid message")
      }
    } else {
      switch serviceObject.type {
      case MessageType.becomeOnline.rawValue:
        becomeOnlineHandler(email: serviceObject.sender, from: connection)
      case MessageType.onlinePeople.rawValue:
        onlinePeopleHandler(email: serviceObject.sender, from: connection)
      case MessageType.startedWriting.rawValue:
        startedWritingHandler(from: connection)
      case MessageType.stoppedWriting.rawValue:
        stoppedWritingHandler(from: connection)
      case MessageType.closedChat.rawValue:
        closedChatHandler(from: connection)
      default:
        invalidData(from: connection, description: "Invalid message")
      }
    }
  }

  public func received(message: String, from connection: WebSocketConnection) {
    print(message)
  }

  public func becomeOnlineHandler(email: String, from connection: WebSocketConnection) {
    lockConnectionsLock()
    connections[connection.id] = ChatConnectionData(email: email,
                                                    connectedToEmail: nil,
                                                    connection: connection)
    unlockConnectionsLock()
    let onlineFriendsData = getOnlineFriends(forEmail: email)
    let serviceObject = ServiceObjectDTO(type: MessageType.becomeOnline.rawValue,
                                      sender: email,
                                      timestamp: Int(Date().timeIntervalSince1970),
                                      payload: nil)
    guard let serviceData = try? JSONEncoder().encode(serviceObject) else {
      return
    }
    for connectionData in onlineFriendsData {
      connectionData.connection.send(message: serviceData)
    }
  }

  private func onlinePeopleHandler(email: String, from connection: WebSocketConnection) {
    let onlineFriendsData = getOnlineFriends(forEmail: email)
    var responseObject = ServiceObjectDTO(type: MessageType.onlinePeople.rawValue,
                                       sender: email,
                                       timestamp: Int(Date().timeIntervalSince1970),
                                       payload: nil)
    responseObject.payload = generatePayloadString(array: onlineFriendsData)
    guard let responseData = try? JSONEncoder().encode(responseObject) else {
      return
    }
    connection.send(message: responseData)
  }

  private func generatePayloadString(array: [ChatConnectionData]) -> String {
    var string = ""
    for item in array {
      string.append("\(item.email),")
    }
    if !string.isEmpty {
      string.removeLast()
    }
    return string
  }

  public func openedChatHandler(otherEmail: String, from connection: WebSocketConnection) {
    lockConnectionsLock()
    connections[connection.id]?.connectedToEmail = otherEmail
    unlockConnectionsLock()
    guard let senderEmail = connections[connection.id]?.email else {
      return
    }
    let otherConnectionData = getConnectionByEmail(email: otherEmail)
    let serviceObject = ServiceObjectDTO(type: MessageType.openedChat.rawValue,
                                      sender: senderEmail,
                                      timestamp: Int(Date().timeIntervalSince1970),
                                      payload: nil)
    if let serviceData = try? JSONEncoder().encode(serviceObject) {
      otherConnectionData?.connection.send(message: serviceData)
    }
  }

  public func startedWritingHandler(from connection: WebSocketConnection) {
    guard let otherEmail = connections[connection.id]?.connectedToEmail,
      let senderEmail = connections[connection.id]?.email else {
        return
    }
    let otherConnectionData = getConnectionByEmail(email: otherEmail)
    let serviceObject = ServiceObjectDTO(type: MessageType.startedWriting.rawValue,
                                      sender: senderEmail,
                                      timestamp: Int(Date().timeIntervalSince1970),
                                      payload: nil)
    if let data = try? JSONEncoder().encode(serviceObject) {
      otherConnectionData?.connection.send(message: data)
    }
  }

  public func stoppedWritingHandler(from connection: WebSocketConnection) {
    guard let otherEmail = connections[connection.id]?.connectedToEmail,
      let senderEmail = connections[connection.id]?.email else {
        return
    }

    let otherConnectionData = getConnectionByEmail(email: otherEmail)
    let serviceObject = ServiceObjectDTO(type: MessageType.stoppedWriting.rawValue,
                                      sender: senderEmail,
                                      timestamp: Int(Date().timeIntervalSince1970),
                                      payload: nil)
    if let data = try? JSONEncoder().encode(serviceObject) {
      otherConnectionData?.connection.send(message: data)
    }
  }

  public func closedChatHandler(from: WebSocketConnection) {
    guard let otherEmail = connections[from.id]?.connectedToEmail,
      let senderEmail = connections[from.id]?.email else {
        return
    }
    lockConnectionsLock()
    connections[from.id]?.connectedToEmail = nil
    unlockConnectionsLock()

    let otherConnectionData = getConnectionByEmail(email: otherEmail)
    let serviceObject = ServiceObjectDTO(type: MessageType.closedChat.rawValue,
                                      sender: senderEmail,
                                      timestamp: Int(Date().timeIntervalSince1970),
                                      payload: nil)
    if let data = try? JSONEncoder().encode(serviceObject) {
      otherConnectionData?.connection.send(message: data)
    }
  }

  public func wroteMessageHandler(message: String, from connection: WebSocketConnection) {
    guard let otherEmail = connections[connection.id]?.connectedToEmail,
      let senderEmail = connections[connection.id]?.email else {
        return
    }

    let otherConnectionData = getConnectionByEmail(email: otherEmail)

    if let dbConversations = DBConversationModel.getConversations(forEmail: senderEmail, otherEmail: otherEmail, approved: 1),
      let dbConversation = dbConversations.first,
      let dbConversationId = dbConversation.id {
      let dbMessage = DBMessageModel(messageId: nil,
                                     conversationId: dbConversationId,
                                     senderEmail: senderEmail,
                                     messageBody: message,
                                     timestamp: Date().millisecondsSince1970,
                                     read: 0)
      dbMessage.save { result, error in
        if let result = result { print(result) }
        else if let error = error { print(error) }
      }
    }
    
    if let connectionData = otherConnectionData {
      var serviceObject = ServiceObjectDTO(type: MessageType.wroteMessage.rawValue,
                                        sender: senderEmail,
                                        timestamp: Int(Date().timeIntervalSince1970),
                                        payload: nil)
      serviceObject.payload = message
      if let data = try? JSONEncoder().encode(serviceObject) {
        connectionData.connection.send(message: data)
      }
    } else {
      //pushnotification
    }
  }

  public func echo(message: String) {
    lockConnectionsLock()
    for connection in connections {
      connection.value.connection.send(message: message)
    }
    unlockConnectionsLock()
  }

  public func invalidData(from: WebSocketConnection, description: String) {
    from.close(reason: .invalidDataContents, description: description)
    lockConnectionsLock()
    let connectionData = connections.removeValue(forKey: from.id)
    unlockConnectionsLock()

    if connectionData != nil {
      //echo(message: "\(MessageType.disconnected.rawValue):\(clientName)")
    }
  }

  // MARK: helper functions

  private func getOnlineFriends(forEmail email: String) -> [ChatConnectionData] {
    var connectionDatas = [ChatConnectionData]()
    if let conversations = DBConversationModel.getConversations(forEmail: email, approved: 1) {
      conversations.forEach {
        let otherEmail = $0.user1 == email ? $0.user2 : $0.user1
        if let connection = getConnectionByEmail(email: otherEmail) {
          connectionDatas.append(connection)
        }
      }
    }
    return connectionDatas
  }

  private func getConnectionByEmail(email: String) -> ChatConnectionData? {
    lockConnectionsLock()
    for data in connections {
      if email == data.value.email {
        unlockConnectionsLock()
        return data.value
      }
    }
    unlockConnectionsLock()
    return nil
  }

  public func lockConnectionsLock() {
    _ = connectionsLock.wait(timeout: DispatchTime.distantFuture)
  }

  public func unlockConnectionsLock() {
    connectionsLock.signal()
  }
}
