
import Fluent

extension TokenResetPassword {
    struct Create: AsyncMigration {
      func prepare(on database: Database) async throws {
          try await database.schema(TokenResetPassword.schema)
              .id()
              .field(TokenResetPassword.v20220101.token, .string, .required)
              .field(TokenResetPassword.v20220101.playerID, .uuid, .required, .references(Player.schema, Player.v20220101.id))
              .unique(on: TokenResetPassword.v20220101.token)
              .create()
      }

      func revert(on database: Database) async throws {
          try await database.schema(TokenResetPassword.schema).delete()
      }
    }
}

extension TokenResetPassword {
    enum v20220101 {
        static let schemaName = "tokenResetPassword"
        static let id = FieldKey(stringLiteral: "id")
        static let token = FieldKey(stringLiteral: "token")
        static let playerID = FieldKey(stringLiteral: "playerID")
    }
}
