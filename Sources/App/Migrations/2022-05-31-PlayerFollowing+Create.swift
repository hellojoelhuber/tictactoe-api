//
//  File.swift
//
//
//  Created by Joel Huber on 5/29/22.
//

import Fluent

extension PlayerFollowing {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(PlayerFollowing.schema)
                .id()
                .field(v20220531.playerID,
                    .uuid,
                    .required,
                    .references(Player.schema,
                                Player.v20220101.id))
                .field(v20220531.followingID,
                       .uuid,
                       .required,
                       .references(Player.schema,
                                   Player.v20220101.id))
                .unique(on: v20220531.playerID, v20220531.followingID)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(PlayerFollowing.schema)
                .delete()
        }
    }
}

extension PlayerFollowing {
    enum v20220531 {
        static let schemaName = "player_following"
        static let playerID = FieldKey(stringLiteral: "playerID")
        static let followingID = FieldKey(stringLiteral: "followingID")
    }
}
