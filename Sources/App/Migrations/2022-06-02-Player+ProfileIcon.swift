
import Fluent

extension Player {
    struct AddPlayerIcon: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Player.schema)
                .deleteField(v20220101.profilePicture)
                .field(v20220602.profileIcon, .string, .sql(.default("hare")))
                .update()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Player.schema)
                .deleteField(v20220602.profileIcon)
                .field(v20220101.profilePicture, .string)
                .update()
        }
    }
}

extension Player {
    enum v20220602 {
        static let profileIcon = FieldKey(stringLiteral: "profileIcon")
    }
}
