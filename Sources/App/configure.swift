import Fluent
import FluentPostgresDriver
import Vapor
//import Leaf

// configures your application
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
    
    // docker run --name postgres -e POSTGRES_DB=vapor_database  -e POSTGRES_USER=vapor_username  -e POSTGRES_PASSWORD=vapor_password  -p 5432:5432 -d postgres
    
    // LIST DOCKER CONTAINERS
    // docker container ls -a
    
    // VIEW POSTGRES DB
    // docker exec -it postgres psql -U vapor_username vapor_database
    
    // STOP & REMOVE CONTAINER
    // docker stop postgres
    // docker rm postgres
    
    // TEST
    // docker run --name postgres-test -e POSTGRES_DB=vapor_test  -e POSTGRES_USER=vapor_username  -e POSTGRES_PASSWORD=vapor_password  -p 5433:5432 -d postgres
    

    
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
    
    #warning("TODO: Refactor the migrations into a smaller set for the templatization of this project.")
    
    switch app.environment {
    case .development, .testing:
        app.migrations.add(CreateAdminUser())
    default:
        break
    }
    
//    app.databases.middleware.use(UserMiddleware(), on: .psql)
    
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()
    
//    app.views.use(.leaf)
    

    // register routes
    try routes(app)
}
