
import Fluent

extension Game {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Game.schema)
                .id()
                .field(v20220524.nextTurn, .uuid,
                       .references(Player.schema, Player.v20220101.id))
                .field(v20220524.completeTurnsCount, .int)
                .field(v20220524.isComplete, .bool, .required, .sql(.default(false)))
                .field(v20220524.winner, .uuid,
                    .references(Player.schema, Player.v20220101.id))
                .field(v20220524.createdAt, .datetime)
                .field(v20220524.createdBy, .uuid, .required,
                    .references(Player.schema, Player.v20220101.id))
                .field(v20220524.updatedAt, .datetime)
                .field(v20220524.deletedAt, .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Game.schema)
                .delete()
        }
    }
}

extension Game {
    enum v20220524 {
        static let schemaName = "game"
        static let id = FieldKey(stringLiteral: "id")
        static let isComplete = FieldKey(stringLiteral: "isComplete")
        static let nextTurn = FieldKey(stringLiteral: "nextTurn")
        static let completeTurnsCount = FieldKey(stringLiteral: "completeTurnsCount")
        static let winner = FieldKey(stringLiteral: "winner")
        static let createdAt = FieldKey(stringLiteral: "createdAt")
        static let createdBy = FieldKey(stringLiteral: "createdBy")
        static let updatedAt = FieldKey(stringLiteral: "updatedAt")
        static let deletedAt = FieldKey(stringLiteral: "deletedAt")
    }
}
