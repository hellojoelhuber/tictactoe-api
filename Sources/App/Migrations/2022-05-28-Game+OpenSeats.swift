
import Fluent

extension Game {
    struct AddOpenSeats: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Game.schema)
                .field(Game.v20220528.openSeats, .int)
                .update()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Game.schema)
                .deleteField(Game.v20220528.openSeats)
                .update()
        }
    }
}

extension Game {
    enum v20220528 {
        static let openSeats = FieldKey(stringLiteral: "openSeats")
    }
}
