//
//  File.swift
//
//
//  Created by Joel Huber on 5/27/22.
//

import Fluent

extension GameAction {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(GameAction.schema)
                .id()
                .field(v20220527.playerID, .uuid,
                       .references(Player.schema, Player.v20220101.id))
                .field(v20220527.gameID, .uuid,
                       .references(Game.schema, Game.v20220524.id))
                .field(v20220527.turnNumber, .int)
                .field(v20220527.actionNumber, .int)
                .field(v20220527.action, .int)
                .field(v20220527.createdAt, .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(GameAction.schema)
                .delete()
        }
    }
}

extension GameAction {
    enum v20220527 {
        static let schemaName = "game_action"
        static let playerID = FieldKey(stringLiteral: "playerID")
        static let gameID = FieldKey(stringLiteral: "gameID")
        static let turnNumber = FieldKey(stringLiteral: "turnNumber")
        static let actionNumber = FieldKey(stringLiteral: "actionNumber")
        static let action = FieldKey(stringLiteral: "action")
        static let createdAt = FieldKey(stringLiteral: "createdAt")
    }
}
