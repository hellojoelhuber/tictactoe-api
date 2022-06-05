//
//  File.swift
//
//
//  Created by Joel Huber on 5/23/22.
//

import Vapor
import Fluent
import TicTacToeCore

#warning("TODO: Migrate as much code as possible to the TicTacToe package to share code between API, App.")

final class Player: Model, Content {
    static let schema = v20220101.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v20220101.firstName)
    var firstName: String
    
    @Field(key: v20220101.lastName)
    var lastName: String
    
    @Field(key: v20220101.username)
    var username: String
    
    @Field(key: v20220101.email)
    var email: String
    
    @Field(key: v20220101.password)
    var password: String

    // Sign-In With Apple
//    @OptionalField(key: "siwaIdentifier")
//    var siwaIdentifier: String?
    
    @OptionalField(key: v20220101.profilePicture)
    var profilePicture: String?
    #warning("TODO: Provide option to upload Profile Pictures.")
    
//    @Timestamp(key: "last_login")
//    var lastLogin: Date?
    
    @Timestamp(key: v20220101.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: v20220101.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: v20220101.deletedAt, on: .delete)
    var deletedAt: Date?

    @Enum(key: v20220101.userType)
    var userType: UserType
    
    @Siblings(through: GamePlayer.self,
              from: \.$player,
              to: \.$game)
    var games: [Game]
    
    @Siblings(through: PlayerFollowing.self,
              from: \.$player,
              to: \.$following)
    var following: [Player]
    
    init() {}
    
    init(id: UUID? = nil, firstName: String, lastName: String,
         username: String, password: String, email: String,
         profilePicture: String? = nil, userType: UserType = .standard
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.password = password
        self.email = email
        self.profilePicture = profilePicture
        self.userType = userType
    }
}

extension Player {
    func convertToPublic() -> PlayerAPIModel {
        return PlayerAPIModel(id: id!, username: username)
    }
}

extension Collection where Element: Player {
    func convertToPublic() -> [PlayerAPIModel] {
        return self.map { $0.convertToPublic() }
    }
}

extension Player: ModelAuthenticatable {
    static let usernameKey = \Player.$username
    static let passwordHashKey = \Player.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension Player: ModelSessionAuthenticatable {}
extension Player: ModelCredentialsAuthenticatable {}
