//
//  File.swift
//
//
//  Created by Joel Huber on 5/24/22.
//

import Fluent

extension GamePlayer {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(GamePlayer.schema)
                .id()
                .field(GamePlayer.v20220524.playerID,
                    .uuid,
                    .required,
                    .references(Player.schema,
                                Player.v20220101.id))
                .field(GamePlayer.v20220524.gameID,
                       .uuid,
                       .required,
                       .references(Game.schema,
                                   Game.v20220524.id))
                .field(GamePlayer.v20220524.turnOrder, .int)
            
                .unique(on: GamePlayer.v20220524.gameID, GamePlayer.v20220524.playerID)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(GamePlayer.schema)
                .delete()
        }
    }
}

extension GamePlayer {
    enum v20220524 {
        static let schemaName = "game_player"
        static let playerID = FieldKey(stringLiteral: "playerID")
        static let gameID = FieldKey(stringLiteral: "gameID")
        static let turnOrder = FieldKey(stringLiteral: "turnOrder")
    }
}
