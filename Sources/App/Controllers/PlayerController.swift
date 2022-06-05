//
//  File.swift
//
//
//  Created by Joel Huber on 5/23/22.
//

import Vapor
import Crypto
import Fluent
import TicTacToeCore

struct UsersController: RouteCollection {
    // MARK: - ROUTES
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api","users")
        
        let tokenAuthMiddleware = TokenAuth.authenticator()
        let guardAuthMiddleware = Player.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware,
                                                guardAuthMiddleware)

        // I chose to set the getPlayer routes behind tokenAuth.
        // If you want to allow users to be retrieved without logging in, change tokenAuthGroup to usersRoute
        tokenAuthGroup.get(use: getAllHandler)
        tokenAuthGroup.get(":userID", use: getHandler)
        tokenAuthGroup.get(":userID","profile", use: getProfileHandler)
        tokenAuthGroup.get("self", use: getOwnDataHandler)

        
        // TASK: I need to research whether this can be confirmed to come from the app, maybe via sessions?
        tokenAuthGroup.post(use: createHandler)
        
//        tokenAuthGroup.put(":userID", use: updateHandler)
        
        tokenAuthGroup.get("following", use: getFollowedPlayersHandler)
        tokenAuthGroup.post(":userID","follow", use: followUserHandler)
        
        tokenAuthGroup.delete(":userID", use: deleteHandler)
        tokenAuthGroup.post(":userID","restore", use: restoreHandler)
        tokenAuthGroup.delete(":userID","force", use: forceDeleteHandler)
        
        
        let basicAuthMiddleware = Player.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    // MARK: - GETS
    func getAllHandler(_ req: Request) async throws -> [PlayerAPIModel] {
        let users = try await Player.query(on: req.db).all()
            
        return users.convertToPublic()
    }
    
    func getHandler(_ req: Request) async throws -> PlayerAPIModel {
        guard let user = try await Player.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return user.convertToPublic()
    }
    
    func getProfileHandler(_ req: Request) async throws -> PlayerProfileDTO {
        guard let player = try await Player.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let gamesPlayed = try await Game.query(on: req.db)
                                        .join(GamePlayer.self, on: \Game.$id == \GamePlayer.$game.$id)
                                        .filter(GamePlayer.self, \.$player.$id == player.id!)
                                        .count()
        
        let gamesWon = try await Game.query(on: req.db)
                                     .filter(\.$winner.$id == player.id!)
                                     .count()

        return PlayerProfileDTO(id: player.id!, username: player.username, gamesPlayed: gamesPlayed, gamesWon: gamesWon)
    }
    
    func getOwnDataHandler(_ req: Request) async throws -> PlayerAPIModel {
        let player = try req.auth.require(Player.self)
        
        return try await Player.find(player.id, on: req.db)!.convertToPublic()
    }
    
    func getFollowedPlayersHandler(_ req: Request) async throws -> [PlayerAPIModel] {
        let player = try req.auth.require(Player.self)
        
        let followedPlayers = try await PlayerFollowing.query(on: req.db)
                                                             .with(\.$following)
                                                             .filter(\.$player.$id == player.id!)
                                                             .all()
         
        return followedPlayers.map { $0.following.convertToPublic() }
    }
    
    func loginHandler(_ req: Request) async throws -> TokenAuth {
        let user = try req.auth.require(Player.self)
        let token = try TokenAuth.generate(for: user)
        try await token.save(on: req.db)
        return token
    }
    
    // MARK: - POSTS
    func createHandler(_ req: Request) async throws -> PlayerAPIModel {
        try Player.validate(content: req)
        let user = try req.content.decode(Player.self)
        user.password = try Bcrypt.hash(user.password)
        try await user.save(on: req.db)
        return user.convertToPublic()
    }
    
    //TODO: Need to add option to unfollow another player.
    func followUserHandler(_ req: Request) async throws -> PlayerAPIModel {
        let player = try req.auth.require(Player.self)
        
        guard let followed = try await Player.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await player.$following.attach([followed], on: req.db)
        
        return followed.convertToPublic()
    }
    
    
    
    // MARK: - PUTS
    #warning("TODO: Add PUT update profile options.")
//    func updateHandler(_ req: Request) async throws -> PlayerAPIModel {
//        let updateData = try req.content.decode(User.self)
//        updateData.password = try Bcrypt.hash(user.password)
//        return updateData.save(on: req.db).map { updateData.convertToPublic() }
//        return User.find(req.parameters.get("userID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//            .flatMap { user in
//                user.firstName = updateData.firstName
//                user.lastName = updateData.lastName
//                user.email = updateData.email
//                return user.save(on: req.db).map {
//                    user
//                }
//            }
//    }
    
    #warning("TODO: Add Reset Password option.")
    
    // MARK: - DELETES
    func deleteHandler(_ request: Request) async throws -> HTTPStatus {
        let requestUser = try request.auth.require(Player.self)
        guard requestUser.userType == .admin else {
            throw Abort(.forbidden)
        }
        guard let user = try await Player.find(request.parameters.get("userID"), on: request.db)
        else {
            throw Abort(.notFound)
        }
        try await user.delete(on: request.db)

        return .noContent
    }
    
    func restoreHandler(_ req: Request) async throws -> HTTPStatus {
        let userID = try req.parameters.require("userID", as: UUID.self)
        guard let user = try await Player.query(on: req.db)
            .withDeleted()
            .filter(\.$id == userID)
            .first()
        else {
            throw Abort(.notFound)
        }
        try await user.restore(on: req.db)

        return .ok
    }
    
    // NOTE: Force delete fails if the user has any existing records.
    // The force delete needs to be rewritten as a cascade if force delete should always, always work. Probably better to implement a new veryForcefulDelete that does the cascade when forceDelete fails.
    func forceDeleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let user = try await Player.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await user.delete(force: true, on: req.db)
        
        return .noContent
    }
}


extension Player: Validatable {
    // TASK: Is there a way to ensure the FieldKey and ValidationKey strings stay in sync?
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        
        validations.add("email", as: String.self, is: .email)
        validations.add("username", as: String.self, is: .alphanumeric && .count(3...))
        validations.add("password", as: String.self, is: .count(8...))
    }
}

