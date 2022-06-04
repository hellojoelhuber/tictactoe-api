//
//  File.swift
//
//
//  Created by Joel Huber on 5/24/22.
//

import Vapor
import Fluent

struct GameController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let gameRoute = routes.grouped("api","game")
        
        let tokenAuthMiddleware = TokenAuth.authenticator()
        let guardAuthMiddleware = Player.guardMiddleware()
        let tokenAuthGroup = gameRoute.grouped(tokenAuthMiddleware,
                                               guardAuthMiddleware)
        tokenAuthGroup.get("my", use: getMyGamesHandler)
        tokenAuthGroup.get("my",":active", use: getMyGamesHandler)
        
        tokenAuthGroup.get(use: getJoinableGamesHandler)
        tokenAuthGroup.post("create", use: createGameHandler)
        tokenAuthGroup.post(":gameID","join", use: joinGameHandler)
        tokenAuthGroup.post(":gameID","action", use: submitTurnHandler)
        
        tokenAuthGroup.get(":gameID", use: getGameActionsHandler)
        tokenAuthGroup.get(":gameID",":turn", use: getGameActionsHandler)
        
        tokenAuthGroup.post(":gameID","resign", use: resignGameHandler)
    }
    
    // MARK: - GETs
    func getAllGamesHandler(_ req: Request) async throws -> [Game.Public] {
        try await Game.query(on: req.db)
                      .filter(\.$isComplete == false)
                      .sort(\.$createdAt)
                      .all()
                      .convertToPublic()
    }
    
    func getMyGamesHandler(_ req: Request) async throws -> [Game.Public] {
        let player = try req.auth.require(Player.self)
        
        let searchSettings: GameSettings.Search
        if let decodedSettings = try? req.content.decode(GameSettings.Search.self) {
            searchSettings = decodedSettings
        } else {
            searchSettings = GameSettings.Search(myGames: true)
        }
        
        let query = Game.query(on: req.db)
        if searchSettings.active != nil { query.filter(\.$isComplete != searchSettings.active!) }
        
        return try await query.join(GamePlayer.self, on: \Game.$id == \GamePlayer.$game.$id)
                              .filter(GamePlayer.self, \.$player.$id == player.id!)
                              .sort(\.$createdAt)
                              .all()
                              .convertToPublic()
    }
    
    func getJoinableGamesHandler(_ req: Request) async throws -> [Game.Public] {
        let player = try req.auth.require(Player.self)
        
        let searchSettings: GameSettings.Search
        if let decodedSettings = try? req.content.decode(GameSettings.Search.self) {
            searchSettings = decodedSettings
        } else {
            searchSettings = GameSettings.Search(active: true)
        }
        
        // This query filters by games which the player created.
        // This only works for 2p games, since the player either created the game or the game has 0 seats remaining. More than 2p will require filter by players already sitting at game.
        #warning("TODO: Filter by players sitting at the game.")

        let query = Game.query(on: req.db).filter(\.$isComplete == false)
                                          .filter(\.$createdBy.$id != player.id!)
                                          .filter(\.$openSeats > 0)
        if searchSettings.isPasswordProtected != nil { query.filter(\.$password != nil) }
        if searchSettings.minColumns != nil, searchSettings.minColumns! > 3 { query.filter(\.$boardColumns >= searchSettings.minColumns!) }
        if searchSettings.maxColumns != nil { query.filter(\.$boardColumns <= searchSettings.maxColumns!) }
        if searchSettings.minRows != nil, searchSettings.minRows! > 3 { query.filter(\.$boardRows >= searchSettings.minRows!) }
        if searchSettings.maxRows != nil { query.filter(\.$boardRows <= searchSettings.maxRows!) }
        #warning("TODO: Hide games where not Mutual Follows & locked to Mutuals Only.")
//        if searchSettings.isMutualFollowsOnly
        #warning("TODO: Add option to search for games created by players you follow.")
//        if searchSettings.following
        
        return try await query.sort(\.$createdAt)
                              .all()
                              .convertToPublic()
    }

    func getGameActionsHandler(_ req: Request) async throws -> [GameAction.Public] {
        guard let game = try await Game.find(req.parameters.get("gameID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // If turnParameter is provided, then return only actions since X; else, return all by setting turnFilter = 0
        let turnFilter: Int
        if let turnParameter = req.parameters.get("turn", as: Int.self) {
            turnFilter = turnParameter
        } else {
            turnFilter = 0
        }
        
        let player = try req.auth.require(Player.self)
        
        let gameActions = try await GameAction.query(on: req.db)
                                              .sort(\.$turnNumber)
                                              .sort(\.$actionNumber)
                                              .filter(\.$game.$id == game.id!)
                                              .all()
        
        guard gameActions.count > 0 else {
            throw Abort(.accepted)
        }
        
        // Player must be admin or in the game, and since we already retrieved the gameActions, we can check that the player submitted an action to determine they're in the game. EXCEPT if they were second player and playing their first turn, so then we have to check if they were the nextTurn player.
        // This only works for 2p game.
        #warning("TODO: Figure out how to get the playerIDs so that I can more easily check that the player is in the game without yet another query. I don't really want to do a JOIN with GamePlayer, but may have to?")
        guard (game.$nextTurn.id == player.id!) || (game.$createdBy.id == player.id!) || gameActions.compactMap({ $0.$player.id }).contains(player.id!) || (player.userType == .admin) else {
            throw Abort(.forbidden)
        }
        
        return gameActions.filter( { $0.turnNumber > turnFilter } ).convertToPublic()
    }

    
    // MARK: - POSTs
    func createGameHandler(_ req: Request) async throws -> Game.Public {
        let player = try req.auth.require(Player.self)
        let gameSettings: GameSettings
        if let decodedSettings = try? req.content.decode(GameSettings.self) {
            gameSettings = decodedSettings
        } else {
            gameSettings = GameSettings(rows: 3, columns: 3)
        }
        
        #warning("TODO: Support asymmetical board sizes, e.g. 3x4")
        // Involves add a winLengthInARow setting on the game
        // Max length = min(row, col), because the longest diagonal == min(row, col)
        // Involves reworking the win checks, because they're currently hardcoded to winLength == row, col
        guard gameSettings.columns == gameSettings.rows else {
            throw Abort(.notImplemented)
        }
        
        let game = Game(boardRows: gameSettings.rows,
                        boardColumns: gameSettings.columns,
                        password: gameSettings.password,
                        isMutualFollowsOnly: gameSettings.isMutualFollowsOnly,
                        createdBy: player.id!)
        
        try await game.save(on: req.db)
        try await game.$players.attach(player, method: .ifNotExists, on: req.db)
        
        return game.convertToPublic()
    }
    
    func joinGameHandler(_ req: Request) async throws -> HTTPStatus {
        guard let game = try await Game.find(req.parameters.get("gameID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let player = try req.auth.require(Player.self)
        
        // VALIDATION: There must be an open seat to join the game.
        guard game.openSeats > 0 else {
            throw Abort(.conflict) // message: "Game full."
        }
        
        // VALIDATION: If password-protected, was the password provided?
        if game.password != nil {
            guard let joinPassword = try? req.content.decode(GameSettings.Join.self) else {
                throw Abort(.forbidden)
            }
            guard joinPassword.password == game.password else {
                throw Abort(.forbidden)
            }
        }
        
        // VALIDATION: If locked to Mutual Follows Only, are players mutual follows?
        if game.isMutualFollowsOnly {
            guard
                try await PlayerFollowing.query(on: req.db)
                                    .filter(\.$player.$id == player.id!)
                                    .filter(\.$following.$id == game.$createdBy.id)
                                    .first() != nil,
                try await PlayerFollowing.query(on: req.db)
                                    .filter(\.$player.$id == game.$createdBy.id)
                                    .filter(\.$following.$id == player.id!)
                                    .first() != nil
            else {
                throw Abort(.forbidden)
            }
        }
        
        // You're cool; join the game.
        try await game.$players.attach(player, method: .ifNotExists, on: req.db, { _ in
            game.$openSeats.value! -= 1
        })
        // isAttached to check if already in the game; but method:.ifNotExists is a good way to do it too.
        
        // This check should always pass if reached, in a 2p game like TTT.
        // Query players, shuffle the returned order, assign turn order based on the new ordering.
        if game.$openSeats.value == 0 {
            var players = try await GamePlayer.query(on: req.db).filter(\.$game.$id == game.id!).all()
            players.shuffle()
            for index in 0..<players.count {
                players[index].turnOrder = (index+1)
                try await players[index].update(on: req.db)
            }
            
            game.$nextTurn.id = players[0].$player.id
            try await game.update(on: req.db)
        }
        
        return .created
    }
    
    func submitTurnHandler(_ req: Request) async throws -> HTTPStatus {
        // should this be let actions = try ... [SubmitGameAction] for a multi-action turn?
        // How does it work to interrupt a turn with new information, e.g., drawing a card or rolling dice?
        let action = try req.content.decode(SubmitGameAction.self)
        guard let game = try await Game.find(req.parameters.get("gameID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let player = try req.auth.require(Player.self)
        
        // VALIDATION: The game must be in progress
        guard !game.isComplete else {
            throw Abort(.notFound)
        }
        
        // Attempt at async validation
//        print(game.isComplete)
//        let validator = GameValidator.init([
//            KeyedContentValidator<Bool>.init("isComplete", "Game is already complete") { !game.isComplete },
//        ])
//        guard validator.validate(req) else {
////            throw ValidationAbort(abort: <#T##<<error type>>#>, message: "Game is already complete.", details: <#T##[ValidationErrorDetail]#>)
//            throw Abort(.notFound)
//        }
        
        
        // VALIDATION: Must be the current player's turn
        guard player.id! == game.$nextTurn.id else {
            throw Abort(.forbidden)
        }
        
        // VALIDATION: Action must be within bounds
        // For TTT, actions are 0..<(rows*cols), so action < (row*cols), >= 0.
        guard action.action < (game.boardRows * game.boardColumns) && action.action >= 0 else {
            throw Abort(.notAcceptable)
        }
        
        // VALIDATION: Must play on a square which is empty.
        let playedSquares = try await GameAction.query(on: req.db)
                                                .field(\.$action)
                                                .filter(\.$game.$id == game.id!)
                                                .all()
                                                .compactMap { move in
                                                    move.action
                                                }
        for index in 0..<playedSquares.count {
            if action.action == playedSquares[index] {
                throw Abort(.conflict)
            }
        }
        
        
        // You're cool; action happened.
        let gameAction = GameAction(gameID: game.id!,
                                    playerID: player.id!,
                                    turnNumber: (game.completeTurnsCount+1),
                                    actionNumber: 1, // actionNumber always = 1 in TicTacToe
                                    action: action.action)
        try await gameAction.save(on: req.db)
        
        
        
        // UPDATE GAME STATE: Is current action a WINNING action?
        let actionsOnly = try await GameAction.query(on: req.db).field(\.$action)
                                            .filter(\.$game.$id == game.id!)
                                            .filter(\.$player.$id == player.id!)
                                            .all()
                                            .compactMap { move in
                                                move.action
                                            }
                                            .sorted()
        let row = Int(action.action/game.boardColumns)
        let col = action.action % game.boardColumns
        if game.checkWin(row: row, col: col, actions: actionsOnly) {
            game.$winner.id = player.id!
            game.isComplete = true
        }
        
        
        // UPDATE GAME STATE: Increment completed turn count
        game.completeTurnsCount += 1
        // UPDATE GAME STATE: check if game ends due to turn count
        if game.completeTurnsCount == (game.boardRows * game.boardColumns) {
            game.isComplete = true
        }
        
        // UPDATE GAME STATE: if game is NOT complete, increment turn order.
        if !game.isComplete {
            let playerOrder = try await GamePlayer.query(on: req.db)
                                                        .filter(\.$game.$id == game.id!)
                                                        .sort(\.$turnOrder)
                                                        .all()
            guard let currentTurn = playerOrder.firstIndex(where: { $0.$player.id == player.id! }) else {
                // Player not in game.
                throw Abort(.notFound)
            }
            game.$nextTurn.id = playerOrder[ (currentTurn+1) % game.playerCount ].$player.id
        }
        
        // Save changes to db.
        try await game.update(on: req.db)
        
        return .created
    }
    
    func resignGameHandler(_ req: Request) async throws -> HTTPStatus {
//        // Something like this for resignation, to undo the joinGame.
//        // Except that resignation USUALLY doesn't reopen the seat for someone to join. That's more of a >2 player thing, like Diplomacy, and not a 2p thing, like chess.
//        // So resignation for 2p should instead set the winner flag to the player who did not resign.
//        try await game.$players.detach(player, method: .ifNotExists, on: req.db, { pivot in
//            pivot.turnOrder = (playerCount + 1)
//        })
        
        guard let game = try await Game.find(req.parameters.get("gameID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let player = try req.auth.require(Player.self)
        
        // Borrowing the "increment turn" logic from above, since we have 2 players,
        // and resignation by 1 player implies the other player wins.
        // In this case, we get players, check that player is in players,
        // then set winner as the next player by turn order.
        if game.$nextTurn.id != nil {
            let players = try await GamePlayer.query(on: req.db)
                                              .filter(\.$game.$id == game.id!)
                                              .sort(\.$turnOrder)
                                              .all()
            guard let currentTurn = players.firstIndex(where: { $0.$player.id == player.id! }) else {
                // Player not in game.
                throw Abort(.notFound)
            }
            game.$winner.id = players[ (currentTurn+1) % game.playerCount ].$player.id
        }
        
        game.isComplete = true
        try await game.update(on: req.db)
        
        return .ok
    }
}

struct SubmitGameAction: Content {
    // Game Action could be as simple as an additional request parameter
    // (cf. my above implementation for getActionsSince),
    // but that's only because TTT is a simple game.
    // Games with more complex actions than a simple int will need this extra complexity in implementation.

    let action: Int
}

