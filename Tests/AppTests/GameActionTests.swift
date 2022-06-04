//
//  File.swift
//
//
//  Created by Joel Huber on 5/29/22.
//

@testable import App
import XCTVapor

final class GameActionTests: XCTestCase {
    var app: Application!
    let gameURI = "/api/game/"
    var sally: Player!
    var timmy: Player!
    
    override func setUpWithError() throws {
        app = try Application.testable()
        sally = try Player.create(firstName: "sally", lastName: "fields", username: "sally", on: app.db)
        timmy = try Player.create(firstName: "timmy", lastName: "wilds", username: "timmy", on: app.db)
    }
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func test_Player_CanPost_Action() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            let action = SubmitGameAction(action: 4)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .created)
            })
        })
    }
    
    func test_Player_CannotPost_Action_ToCompletedGame() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
            
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 3)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 1)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 5)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 2)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .notFound)
            })
        })
        
    }
    
    func test_Player_CannotPost_Action_IfNotTheirTurn() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            let action = SubmitGameAction(action: 4)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .forbidden)
            })
        })
    }
    
    func test_Player_CannotPost_Action_OutsideGameBoundaries() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            let action = SubmitGameAction(action: 9)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .notAcceptable)
            })
        })
    }
    
    func test_Player_CannotPost_Action_OutsideCustomGameBoundaries() throws {
        let customGame = GameSettings(rows: 4, columns: 4)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            
            XCTAssertEqual(game.boardColumns, 4)
            XCTAssertEqual(game.boardRows, 4)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
            
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            let action = SubmitGameAction(action: 16)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .notAcceptable)
            })
        })
    }
    
    func test_Player_CannotPost_Action_WhichWasAlreadyPlayed() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            let action = SubmitGameAction(action: 4)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .created)
            })
            
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            }, afterResponse: { response in
                XCTAssertEqual(response.status, .conflict)
            })
        })
    }
    
    func test_Player_CanWin_ByRow() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 3)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 1)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 5)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let games = try response.content.decode([Game.Public].self)
                
                XCTAssertEqual(games[0].winner, firstPlayer)
            })
        })
    }
    
    func test_Player_CanWin_ByColumn() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 1)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 3)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 7)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let games = try response.content.decode([Game.Public].self)
                
                XCTAssertEqual(games[0].winner, firstPlayer)
            })
        })
    }
    
    func test_Player_CanWin_ByDiagonalZero() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 1)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 2)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 8)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let games = try response.content.decode([Game.Public].self)
                
                XCTAssertEqual(games[0].winner, firstPlayer)
            })
        })
    }
    
    func test_Player_CanWin_ByDiagonalMid() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 2)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 1)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 6)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
                let games = try response.content.decode([Game.Public].self)
                
                XCTAssertEqual(games[0].winner, firstPlayer)
            })
        })
    }
    
//    func test_CanWinByRowInCustomGame() throws {
//
//    }
//
//    func test_CanWinByColumnInCustomGame() throws {
//
//    }
//
//    func test_CanWinByDiagonalZeroInCustomGame() throws {
//
//    }
//
//    func test_CanWinByDiagonalMidInCustomGame() throws {
//
//    }
    
    func test_Player_CanRetrieve_AllActions() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
            
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)", loggedInUser: sally, afterResponse: { response in
                let actions = try response.content.decode([GameAction.Public].self)
                XCTAssertEqual(actions.count, 1)
                XCTAssertEqual(actions[0].action, 4)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 3)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)", loggedInUser: sally, afterResponse: { response in
                let actions = try response.content.decode([GameAction.Public].self)
                XCTAssertEqual(actions.count, 3)
                XCTAssertEqual(actions[0].action, 4)
                XCTAssertEqual(actions[1].action, 0)
                XCTAssertEqual(actions[2].action, 3)
            })
        })
        
    }
    
    func test_Player_CanRetrieve_ActionsSinceTurn() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)/0", loggedInUser: sally, afterResponse: { response in
                let actions = try response.content.decode([GameAction.Public].self)
                XCTAssertEqual(actions.count, 1)
                XCTAssertEqual(actions[0].action, 4)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 3)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)/2", loggedInUser: sally, afterResponse: { response in
                let actions = try response.content.decode([GameAction.Public].self)
                XCTAssertEqual(actions.count, 1)
                XCTAssertEqual(actions[0].action, 3)
            })
        })
    }
    
    func test_PlayerNotInGame_CannotRetrieve_Actions() throws {
        let bully = try Player.create(firstName: "bully", lastName: "snoop", username: "bully", on: app.db)
        
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
            
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            let action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)", loggedInUser: bully, afterResponse: { response in
                XCTAssertEqual(response.status, .forbidden)
            })
        })
    }
    
    func test_PlayerNotInGame_CannotRetrieve_ActionsSinceTurn() throws {
        let bully = try Player.create(firstName: "bully", lastName: "snoop", username: "bully", on: app.db)
        
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 3)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)/2", loggedInUser: bully, afterResponse: { response in
                XCTAssertEqual(response.status, .forbidden)
            })
        })
    }
    
    func test_AdminUser_CanRetrieve_Actions() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
        
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            let action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)", loggedInRequest: true, afterResponse: { response in
                let actions = try response.content.decode([GameAction.Public].self)
                XCTAssertEqual(actions.count, 1)
            })
        })
    }
    
    func test_AdminUser_CanRetrieve_ActionsSinceTurn() throws {
        let customGame = Game(createdBy: sally.id!)
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { req in
            try req.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy)
                
            var firstPlayer: Player.IDValue!
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                firstPlayer = games[0].nextTurn
            })
            
            var action = SubmitGameAction(action: 4)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 0)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? timmy : sally), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            action = SubmitGameAction(action: 3)
            try app.test(.POST, "\(gameURI)\(game.id!)/action", loggedInUser: (firstPlayer == sally.id! ? sally : timmy), beforeRequest: { req in
                try req.content.encode(action)
            })
            
            try app.test(.GET, "\(gameURI)\(game.id!)/1", loggedInRequest: true, afterResponse: { response in
                let actions = try response.content.decode([GameAction.Public].self)
                XCTAssertEqual(actions.count, 2)
                XCTAssertEqual(actions[0].action, 0)
                XCTAssertEqual(actions[1].action, 3)
            })
        })
    }
}
