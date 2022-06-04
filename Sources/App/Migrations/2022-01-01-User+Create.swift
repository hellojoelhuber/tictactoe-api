//
//  File.swift
//
//
//  Created by Joel Huber on 1/01/22.
//

import Fluent
import SQLKit

extension Player {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            let userType = try await database.enum("userType")
                .case("admin")
                .case("standard")
    //            .case("restricted")
                .create()

            return try await database.schema(Player.schema)
                .id()
                .field(Player.v20220101.firstName, .string, .required)
                .field(Player.v20220101.lastName, .string, .required)
                .field(Player.v20220101.username, .string, .required)
                .field(Player.v20220101.password, .string, .required)
                .field(Player.v20220101.email, .string, .required)
                .field(Player.v20220101.profilePicture, .string)
    //            .field(User.v20210114.twitterURL, .string)
                .field(Player.v20220101.createdAt, .datetime)
                .field(Player.v20220101.updatedAt, .datetime)
                .field(Player.v20220101.deletedAt, .datetime)
                .field(Player.v20220101.userType, userType, .required, .sql(SQLColumnConstraintAlgorithm.default("standard")))
                .unique(on: Player.v20220101.email)
                .unique(on: Player.v20220101.username)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database
                .schema(Player.schema)
                .delete()

            return try await database.enum("userType")
                .delete()
        }
    }
}

extension Player {
    enum v20220101 {
        static let schemaName = "app_user"
        static let id = FieldKey(stringLiteral: "id")
        static let firstName = FieldKey(stringLiteral: "firstName")
        static let lastName = FieldKey(stringLiteral: "lastName")
        static let username = FieldKey(stringLiteral: "username")
        static let password = FieldKey(stringLiteral: "password")
        static let email = FieldKey(stringLiteral: "email")
        static let profilePicture = FieldKey(stringLiteral: "profilePicture")
        static let createdAt = FieldKey(stringLiteral: "created_at")
        static let updatedAt = FieldKey(stringLiteral: "updated_at")
        static let deletedAt = FieldKey(stringLiteral: "deleted_at")
        static let userType = FieldKey(stringLiteral: "userType")
    }
}
