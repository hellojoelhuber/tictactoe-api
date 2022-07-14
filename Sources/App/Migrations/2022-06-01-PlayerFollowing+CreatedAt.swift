
import Fluent

extension PlayerFollowing {
    struct AddCreatedAt: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(PlayerFollowing.schema)
                .field(v20220601.createdAt, .datetime)
                .update()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(PlayerFollowing.schema)
                .deleteField(v20220601.createdAt)
                .update()
        }
    }
}

extension PlayerFollowing {
    enum v20220601 {
        static let createdAt = FieldKey(stringLiteral: "createdAt")
    }
}
