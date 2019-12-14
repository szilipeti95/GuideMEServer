//
//  DBDTOConverter.swift
//  Application
//
//  Created by Szili Péter on 2019. 10. 12..
//

import Foundation

extension MessageDTO {
  private init(dbMessage: DBMessageModel) {
    self.message = dbMessage.messageBody
    self.timestamp = dbMessage.timestamp / 1000
    self.sender = dbMessage.senderEmail
  }
  
  public static func builder(dbMessage: DBMessageModel) -> MessageDTO {
    return MessageDTO(dbMessage: dbMessage)
  }
}

extension ConversationDTO {
  private init(dbConversation: DBConversationModel,
               user: UserDTO,
               lastMessage: MessageDTO,
               read: Bool) {
    self.id = dbConversation.id ?? -1 // TODO: REMOVE?
    self.user = user
    self.lastMessage = lastMessage
    self.approved = dbConversation.approved == 1
    self.read = read
  }

  public static func builder(dbConversation: DBConversationModel, forUser user: UserDTO) throws -> ConversationDTO {
    let otherEmail = dbConversation.user1 == user.email ? dbConversation.user2 : dbConversation.user1
    guard let otherUser = UserDTO.builder(email: otherEmail),
      let conversationId = dbConversation.id,
      let dbLastMessage = DBMessageModel.getLastMessage(for: conversationId) else {
        throw BuilderError.unknownError
    }
    let lastMessage = MessageDTO.builder(dbMessage: dbLastMessage)
    let conversation = ConversationDTO(dbConversation: dbConversation, user: otherUser, lastMessage: lastMessage, read: dbLastMessage.read == 1)

    return conversation
  }
}

extension CityDTO {
  private init(dbCity: DBCitiesModel) {
    self.city = dbCity.city
    self.country = dbCity.country
    self.imageUri = dbCity.imageUri
  }

  public static func builder(dbCity: DBCitiesModel) -> CityDTO {
    return CityDTO(dbCity: dbCity)
  }
}


extension UserDTO {
  public static func builder(email: String) -> UserDTO? {
    guard let user = DBUserModel.getUserWith(email: email) else { return nil }

    var userResponse = UserDTO(dbUser: user)
    userResponse.photos = DBUserPhotosModel.getUploadedPhotosFor(userEmail: email)?.map({ PhotoDTO(dbPhoto: $0) })
    userResponse.friendCount = DBConversationModel.getFriendCount(for: email)

    if let selectLocal = DBGuidesModel.getLocalGuide(for: email),
      let localCity = DBCitiesModel.getCity(with: selectLocal.cityId) {
      userResponse.local = CityDTO.builder(dbCity: localCity)

    }
    if let selectNext = DBGuidesModel.getNextGuide(for: email),
      let nextCity = DBCitiesModel.getCity(with: selectNext.cityId) {
      userResponse.next = CityDTO.builder(dbCity: nextCity)
    }

    return userResponse
  }
}

extension GuideDTO {
  private init(dbGuide: DBGuidesModel, city: CityDTO, prefTypes: [Int]) {
    self.city = city
    self.type = dbGuide.type
    if let from = dbGuide.from, let to = dbGuide.to {
      self.from = from / 1000
      self.to = to / 1000
    } else {
      self.from = nil
      self.to = nil
    }
    self.preferenceType = prefTypes
  }

  public static func builder(dbGuide: DBGuidesModel) throws -> GuideDTO {
    guard let dbCity = DBCitiesModel.getCity(with: dbGuide.cityId) else {
      throw BuilderError.unknownError
    }
    let dbGuidePrefs = DBGuidePreferencesModel.getPreferences(guideId: dbGuide.guideId) ?? []
    let city = CityDTO.builder(dbCity: dbCity)
    let types = dbGuidePrefs.map( { $0.prefTypeId } )
    return GuideDTO(dbGuide: dbGuide, city: city, prefTypes: types)
  }
}
