//
//  File.swift
//
//
//  Created by Joel Huber on 5/28/22.
//

import Fluent

extension Game {
    struct AddBoardSize: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Game.schema)
                .field(Game.v20220530.boardRows, .int)
                .field(Game.v20220530.boardColumns, .int)
                .update()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Game.schema)
                .deleteField(Game.v20220530.boardRows)
                .deleteField(Game.v20220530.boardColumns)
                .update()
        }
    }
}

extension Game {
    enum v20220530 {
        static let boardRows = FieldKey(stringLiteral: "boardRows")
        static let boardColumns = FieldKey(stringLiteral: "boardColumns")
    }
}
