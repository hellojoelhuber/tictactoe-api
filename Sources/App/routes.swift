import Fluent
import Vapor

func routes(_ app: Application) throws {
    let usersController = UsersController()
    try app.register(collection: usersController)
    
    let gameController = GameController()
    try app.register(collection: gameController)
}
