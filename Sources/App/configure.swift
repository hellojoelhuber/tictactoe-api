import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) throws {
//    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
//    app.middleware.use(app.sessions.middleware)

    let databaseName: String
    let databasePort: Int
    if app.environment == .testing {
        databaseName = "vapor_test"
        databasePort = 5433
    } else {
        databaseName = "vapor_database"
        databasePort = 5432
    }
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: databasePort,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? databaseName
    ), as: .psql)
    
    
    app.migrations.add(Player.Create())
    app.migrations.add(TokenAuth.Create())
    app.migrations.add(TokenResetPassword.Create())
    app.migrations.add(Game.Create())
    app.migrations.add(GamePlayer.Create())
    app.migrations.add(GameAction.Create())
    app.migrations.add(Game.AddOpenSeats())
    app.migrations.add(Game.AddPlayerCount())
    app.migrations.add(Game.AddBoardSize())
    app.migrations.add(Game.AddPasswordAndFollowSettings())
    app.migrations.add(PlayerFollowing.Create())
    app.migrations.add(PlayerFollowing.AddCreatedAt())
    app.migrations.add(Player.AddPlayerIcon())
    
    switch app.environment {
    case .development, .testing:
        app.migrations.add(CreateAdminUser())
    default:
        break
    }
    
//    app.databases.middleware.use(UserMiddleware(), on: .psql)
    
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()
    
    try routes(app)
}
