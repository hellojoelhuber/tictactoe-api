
import Fluent
import Vapor

struct CreateAdminUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        let passwordHash: String
//        do {
        passwordHash = try Bcrypt.hash("password")
            // TODO: Turn password into a secret during deployment
//        } catch {
//            return database.eventLoop.future(error: error)
//        }
        let player = Player(firstName: "Admin",
                          lastName: "Admin",
                          username: "admin",
                          password: passwordHash,
                          email: "admin@localhost.local",
                          // Can I turn admin email into a secret too?
                          userType: .admin)
        return try await player.save(on: database)
    }

    func revert(on database: Database) async throws {
        try await Player.query(on: database)
            .filter(\.$username == "admin")
            .delete()
    }
}
