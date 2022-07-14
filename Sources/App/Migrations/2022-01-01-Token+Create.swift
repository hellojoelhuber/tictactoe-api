
import Fluent

extension TokenAuth {
    struct Create: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(TokenAuth.schema)
                .id()
                .field(TokenAuth.v20220101.value, .string, .required)
                .field(TokenAuth.v20220101.playerID,
                       .uuid,
                       .required,
                       .references(Player.schema, Player.v20220101.id, onDelete: .cascade))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(TokenAuth.schema).delete()
        }
    }
}

extension TokenAuth {
    enum v20220101 {
        static let schemaName = "tokenAuth"
        static let id = FieldKey(stringLiteral: "id")
        static let value = FieldKey(stringLiteral: "value")
        static let playerID = FieldKey(stringLiteral: "playerID")
    }
}

