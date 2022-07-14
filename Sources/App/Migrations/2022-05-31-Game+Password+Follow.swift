
import Fluent

extension Game {
    struct AddPasswordAndFollowSettings: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Game.schema)
                .field(Game.v20220531.password, .string)
                .field(Game.v20220531.isMutualFollowsOnly, .bool)
                .update()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Game.schema)
                .deleteField(Game.v20220531.password)
                .deleteField(Game.v20220531.isMutualFollowsOnly)
                .update()
        }
    }
}

extension Game {
    enum v20220531 {
        static let password = FieldKey(stringLiteral: "password")
        static let isMutualFollowsOnly = FieldKey(stringLiteral: "isMutualFollowsOnly")
    }
}
