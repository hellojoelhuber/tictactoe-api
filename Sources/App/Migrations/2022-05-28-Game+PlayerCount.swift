//
//  File.swift
//
//
//  Created by Joel Huber on 5/28/22.
//

import Fluent

extension Game {
    struct AddPlayerCount: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Game.schema)
                .field(Game.v20220529.playerCount, .int)
                .update()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Game.schema)
                .deleteField(Game.v20220529.playerCount)
                .update()
        }
    }
}

extension Game {
    enum v20220529 {
        static let playerCount = FieldKey(stringLiteral: "playerCount")
    }
}
