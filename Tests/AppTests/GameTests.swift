//
//  File.swift
//
//
//  Created by Joel Huber on 5/25/22.
//

@testable import App
import XCTVapor

final class GameTests: XCTestCase {
    var app: Application!
    let gameURI = "/api/game/"
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func test_Game_CanBeCreated() throws {
        let player = try Player.create(on: app.db)
        let game = Game(createdBy: player.id!)

        try app.test(.POST, "\(gameURI)create", loggedInUser: player, beforeRequest: { req in
            try req.content.encode(game)
        }, afterResponse: { response in
            let receivedGame = try response.content.decode(Game.Public.self)
            XCTAssertNotNil(receivedGame.id)
            
            // Testing GET gameURI here works because the PLAYER created the game, and the Admin is basically looking for joinable games.
            try app.test(.GET, gameURI, loggedInRequest: true, afterResponse: { secondResponse in
                let games = try secondResponse.content.decode([Game.Public].self)
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].isComplete, false)
                XCTAssertNil(games[0].nextTurn)
                XCTAssertNil(games[0].winner)
                XCTAssertEqual(games[0].id, receivedGame.id)
            })
        })
    }
    
    func test_GameCustomSize_CanBeCreated() throws {
        let game = GameSettings(rows: 4, columns: 4)
        
        try app.test(.POST, "\(gameURI)create", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(game)
        }, afterResponse: { response in
            let receivedGame = try response.content.decode(Game.Public.self)
            XCTAssertNotNil(receivedGame.id)
            
            // Testing GET gameURI/my here because the ADMIN created the game, so the Admin is a player, so the Admin cannot find the game by searching for joinable games.
            try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { secondResponse in
                let games = try secondResponse.content.decode([Game.Public].self)
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].isComplete, false)
                XCTAssertEqual(games[0].boardColumns, game.columns)
                XCTAssertEqual(games[0].boardRows, game.rows)
                XCTAssertNil(games[0].nextTurn)
                XCTAssertNil(games[0].winner)
                XCTAssertEqual(games[0].id, receivedGame.id)
            })
        })
    }
    
    func test_GamePasswordProtected_CanBeCreated() throws {
        let testPassword = "tictactoe"
        let game = GameSettings(password: testPassword)

        try app.test(.POST, "\(gameURI)create", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(game)
        }, afterResponse: { response in
            let receivedGame = try response.content.decode(Game.Public.self)
            XCTAssertNotNil(receivedGame.id)
            
            // Testing GET gameURI/my here because the ADMIN created the game, so the Admin is a player, so the Admin cannot find the game by searching for joinable games.
            try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { secondResponse in
                let games = try secondResponse.content.decode([Game.Public].self)
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].isComplete, false)
                XCTAssertEqual(games[0].isPasswordProtected, true)
                XCTAssertEqual(games[0].boardColumns, game.columns)
                XCTAssertEqual(games[0].boardRows, game.rows)
                XCTAssertNil(games[0].nextTurn)
                XCTAssertNil(games[0].winner)
                XCTAssertEqual(games[0].id, receivedGame.id)
            })
        })
    }
    
    func test_JoinableGames_CanBeRetrieved() throws {
        let player = try Player.create(on: app.db)
        let game = try Game.create(createdBy: player.id!, on: app.db)
        let gameCustom = GameSettings(rows: 4, columns: 4)
        
        try app.test(.POST, "\(gameURI)create", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(gameCustom)
        })
        
        try app.test(.GET, gameURI, loggedInRequest: true, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let games = try response.content.decode([Game.Public].self)
            
            XCTAssertEqual(games.count, 1)
            XCTAssertEqual(games[0].isComplete, false)
            XCTAssertEqual(games[0].boardColumns, game.boardColumns)
            XCTAssertEqual(games[0].boardRows, game.boardRows)
            XCTAssertNil(games[0].nextTurn)
            XCTAssertNil(games[0].winner)
            XCTAssertEqual(games[0].id, game.id)
        })
    }
    
    func test_MyGames_CanBeRetrieved() throws {
        let player = try Player.create(on: app.db)
        let game = try Game.create(createdBy: player.id!, on: app.db)
        
        let customGame = GameSettings(rows: 4, columns: 4)
        try app.test(.POST, "\(gameURI)create", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(customGame)
        })
        
        try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let games = try response.content.decode([Game.Public].self)
            
            XCTAssertEqual(games.count, 2)
        })
    }
    
    func test_MyActiveGames_CanBeRetrieved() throws {
        let player = try Player.create(on: app.db)
        let game = try Game.create(createdBy: player.id!, on: app.db)
        
        let customGame = GameSettings(rows: 4, columns: 4)
        try app.test(.POST, "\(gameURI)create", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(customGame)
        })
        
        try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        game.$isComplete.value = true
        _ = game.update(on: app.db)
        
        let searchSettings = GameSettings.Search(myGames: true, active: true)
        
        try app.test(.GET, "\(gameURI)my", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(searchSettings)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let games = try response.content.decode([Game.Public].self)
            
            XCTAssertEqual(games.count, 1)
            XCTAssertEqual(games[0].isComplete, false)
        })
    }
    
    func test_MyCompleteGames_CanBeRetrieved() throws {
        let player = try Player.create(on: app.db)
        let game = try Game.create(createdBy: player.id!, on: app.db)
        
        let customGame = GameSettings(rows: 4, columns: 4)
        try app.test(.POST, "\(gameURI)create", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(customGame)
        })
        
        try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        game.isComplete = true
        _ = game.update(on: app.db)
        
        let searchSettings = GameSettings.Search(myGames: true, active: false)
        
        try app.test(.GET, "\(gameURI)my", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(searchSettings)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let games = try response.content.decode([Game.Public].self)
            
            XCTAssertEqual(games.count, 1)
            XCTAssertEqual(games[0].isComplete, true)
        })
    }
    
    func test_Player_CanJoin_Game() throws {
        let player = try Player.create(on: app.db)
        let game = try Game.create(createdBy: player.id!, on: app.db)
        
        try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
            
        try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { response in
            let games = try response.content.decode([Game.Public].self)
            
            XCTAssertEqual(games.count, 1)
            XCTAssertEqual(games[0].id, game.id)
            XCTAssertEqual(games[0].isComplete, false)
            XCTAssertEqual(games[0].openSeats, 0)
            XCTAssertEqual(games[0].playerCount, 2)
            XCTAssertEqual(games[0].boardColumns, game.boardColumns)
            XCTAssertEqual(games[0].boardRows, game.boardRows)
            XCTAssertNotNil(games[0].nextTurn)
            XCTAssertNil(games[0].winner)
            
        })
    }
    
    func test_Player_CanResign_Game() throws {
        let sally = try Player.create(firstName: "sally", lastName: "fields", username: "sally", on: app.db)
        let timmy = try Player.create(firstName: "timmy", lastName: "wilds", username: "timmy", on: app.db)
        
        let customGame = GameSettings(rows: 3, columns: 3)
        
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy, afterResponse: { response in
                XCTAssertEqual(response.status, .created)
            })
            
            try app.test(.POST, "\(gameURI)\(game.id!)/resign", loggedInUser: timmy, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
            })
            
            try app.test(.GET, "\(gameURI)my", loggedInUser: timmy, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].id, game.id)
                XCTAssertEqual(games[0].isComplete, true)
                XCTAssertEqual(games[0].openSeats, 0)
                XCTAssertEqual(games[0].playerCount, 2)
                XCTAssertEqual(games[0].boardColumns, game.boardColumns)
                XCTAssertEqual(games[0].boardRows, game.boardRows)
                XCTAssertNotNil(games[0].nextTurn)
                XCTAssertEqual(games[0].winner, sally.id)
            })
        })
    }
    
    func test_Player_CanResign_UnstartedGame() throws {
        let sally = try Player.create(firstName: "sally", lastName: "fields", username: "sally", on: app.db)
        
        let customGame = GameSettings(rows: 3, columns: 3)
        
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            
            try app.test(.POST, "\(gameURI)\(game.id!)/resign", loggedInUser: sally, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
            })
            
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { response in
                let games = try response.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].id, game.id)
                XCTAssertEqual(games[0].isComplete, true)
                XCTAssertEqual(games[0].boardColumns, game.boardColumns)
                XCTAssertEqual(games[0].boardRows, game.boardRows)
                XCTAssertNil(games[0].nextTurn)
                XCTAssertNil(games[0].winner)
            })
        })
    }
    
    func test_Player_CanJoin_PasswordProtectedGame() throws {
        let player = try Player.create(on: app.db)
        let testPassword = "tictactoe"
        let customGame = GameSettings(password: testPassword)
        
        try app.test(.POST, "\(gameURI)create", loggedInUser: player, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, beforeRequest: { reqJoin in
                let joinGame = GameSettings.Join(password: testPassword)
                try reqJoin.content.encode(joinGame)
            }, afterResponse: { responseJoin in
                XCTAssertEqual(responseJoin.status, .created)
            })
                
            try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { responseGet in
                let games = try responseGet.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].id, game.id)
                XCTAssertEqual(games[0].isComplete, false)
                XCTAssertEqual(games[0].openSeats, 0)
                XCTAssertEqual(games[0].playerCount, 2)
                XCTAssertEqual(games[0].boardColumns, game.boardColumns)
                XCTAssertEqual(games[0].boardRows, game.boardRows)
                XCTAssertNotNil(games[0].nextTurn)
                XCTAssertNil(games[0].winner)
                
            })
        })
    }
    
    func test_PlayerWithoutGamePassword_CannotJoin_PasswordProtectedGame() throws {
        let player = try Player.create(on: app.db)
        let testPassword = "tictactoe"
        let customGame = GameSettings(password: testPassword)
        
        try app.test(.POST, "\(gameURI)create", loggedInUser: player, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, afterResponse: { responseJoin in
                XCTAssertEqual(responseJoin.status, .forbidden)
            })
                
            try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { responseGet in
                let games = try responseGet.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 0)
            })
        })
    }
    
    func test_PlayerWithWrongGamePassword_CannotJoin_PasswordProtectedGame() throws {
        let player = try Player.create(on: app.db)
        let testPassword = "tictactoe"
        let customGame = GameSettings(password: testPassword)
        
        try app.test(.POST, "\(gameURI)create", loggedInUser: player, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, beforeRequest: { reqJoin in
                let joinGame = GameSettings.Join(password: "wrongPassword")
                try reqJoin.content.encode(joinGame)
            }, afterResponse: { responseJoin in
                XCTAssertEqual(responseJoin.status, .forbidden)
            })
                
            try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { responseGet in
                let games = try responseGet.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 0)
            })
        })
    }
    
    func test_PlayerMutuallyFollowingGameCreator_CanJoin_MutualFollowsOnlyGame() throws {
        let sally = try Player.create(firstName: "sally", lastName: "fields", username: "sally", on: app.db)
        let timmy = try Player.create(firstName: "timmy", lastName: "wilds", username: "timmy", on: app.db)
        try app.test(.POST, "/api/users/\(sally.id!)/follow", loggedInUser: timmy)
        try app.test(.POST, "/api/users/\(timmy.id!)/follow", loggedInUser: sally)
        
        let customGame = GameSettings(isMutualFollowsOnly: true)
        
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            XCTAssertEqual(game.isMutualFollowsOnly, true)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy, afterResponse: { responseJoin in
                XCTAssertEqual(responseJoin.status, .created)
            })
                
            try app.test(.GET, "\(gameURI)my", loggedInUser: timmy, afterResponse: { responseGet in
                let games = try responseGet.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 1)
            })
        })
    }
    
    func test_PlayersNotMutuallyFollowing_CannotJoin_MutualFollowsOnlyGame() throws {
        // This test is bad form because it covers 3 separate cases of Mutual Follow:
        // 1. when neither player follows,
        // 2. when the user follows the host,
        // 3. when the host follows the user.
        // All three cases should fail if the isMutualFollowsOnly option == true.
        
        // Test Setup.
        let sally = try Player.create(firstName: "sally", lastName: "fields", username: "sally", on: app.db)
        let timmy = try Player.create(firstName: "timmy", lastName: "wilds", username: "timmy", on: app.db)
        
        let customGame = GameSettings(isMutualFollowsOnly: true)
        // fin Test Setup.
        
        try app.test(.POST, "\(gameURI)create", loggedInUser: sally, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            XCTAssertEqual(game.isMutualFollowsOnly, true)
            
            // 1. Neither player follows the other. Timmy tries to join Sally's game, is rejected.
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy, afterResponse: { responseJoin in
                XCTAssertEqual(responseJoin.status, .forbidden)
            })
                
            try app.test(.GET, "\(gameURI)my", loggedInUser: timmy, afterResponse: { responseGet in
                let games = try responseGet.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 0)
            })
            
            // 2. Timmy Follows Sally, tries to join game, is rejected.
            try app.test(.POST, "/api/users/\(sally.id!)/follow", loggedInUser: timmy)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: timmy, afterResponse: { responseJoin in
                XCTAssertEqual(responseJoin.status, .forbidden)
            })
                
            try app.test(.GET, "\(gameURI)my", loggedInUser: timmy, afterResponse: { responseGet in
                let games = try responseGet.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 0)
            })
        })
        

        // 3. Timmy creates a game, Sally tries to join, is rejected.
        try app.test(.POST, "\(gameURI)create", loggedInUser: timmy, beforeRequest: { reqCreate in
            try reqCreate.content.encode(customGame)
        }, afterResponse: { response in
            let game = try response.content.decode(Game.Public.self)
            XCTAssertEqual(game.isMutualFollowsOnly, true)
            try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInUser: sally, afterResponse: { responseJoin in
                XCTAssertEqual(responseJoin.status, .forbidden)
            })
                
            try app.test(.GET, "\(gameURI)my", loggedInUser: sally, afterResponse: { responseGet in
                let games = try responseGet.content.decode([Game.Public].self)
                
                XCTAssertEqual(games.count, 1)
            })
        })
    }
    
    func test_Player_CannotJoin_GameWithoutOpenSeat() throws {
        let player = try Player.create(on: app.db)
        let game = try Game.create(createdBy: player.id!, on: app.db)
        
        try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true)
        
        // This would be better if I could test joining a game that someone else had already joined.
        try app.test(.POST, "\(gameURI)\(game.id!)/join", loggedInRequest: true, afterResponse: { response in
            XCTAssertEqual(response.status, .conflict)
        })
    }
    
    func test_Player_CanCreate_GameWithSettings_CustomSize_Password_MutualsOnly() throws {
        let testPassword = "oopsiedaisy"
        let game = GameSettings(rows: 4, columns: 4,
                                      password: testPassword,
                                      isMutualFollowsOnly: true)

        try app.test(.POST, "\(gameURI)create", loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(game)
        }, afterResponse: { response in
            let receivedGame = try response.content.decode(Game.Public.self)
            XCTAssertNotNil(receivedGame.id)
            
            // Testing GET gameURI/my here because the ADMIN created the game, so the Admin is a player, so the Admin cannot find the game by searching for joinable games.
            try app.test(.GET, "\(gameURI)my", loggedInRequest: true, afterResponse: { secondResponse in
                let games = try secondResponse.content.decode([Game.Public].self)
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].isComplete, false)
                XCTAssertEqual(games[0].boardColumns, game.columns)
                XCTAssertEqual(games[0].boardRows, game.rows)
                XCTAssertEqual(games[0].isPasswordProtected, true)
                XCTAssertEqual(games[0].isMutualFollowsOnly, true)
                XCTAssertNil(games[0].nextTurn)
                XCTAssertNil(games[0].winner)
                XCTAssertEqual(games[0].id, receivedGame.id)
            })
        })
    }
    
    func test_Player_CanSearch_CustomSizeGames() throws {
        let player = try Player.create(on: app.db)
        let game = GameSettings(rows: 4, columns: 4)
        
        let searchSettings = GameSettings.Search(active: true,
                                                 minRows: 4, maxRows: 4,
                                                 minColumns: 4, maxColumns: 4)

        try app.test(.POST, "\(gameURI)create", loggedInUser: player, beforeRequest: { req in
            try req.content.encode(game)
        }, afterResponse: { response in
            let receivedGame = try response.content.decode(Game.Public.self)
            XCTAssertNotNil(receivedGame.id)
            
            try app.test(.GET, "\(gameURI)", loggedInRequest: true, beforeRequest: { req in
                try req.content.encode(searchSettings)
            }, afterResponse: { secondResponse in
                let games = try secondResponse.content.decode([Game.Public].self)
                XCTAssertEqual(games.count, 1)
                XCTAssertEqual(games[0].isComplete, false)
                XCTAssertEqual(games[0].boardColumns, game.columns)
                XCTAssertEqual(games[0].boardRows, game.rows)
                XCTAssertNil(games[0].nextTurn)
                XCTAssertNil(games[0].winner)
                XCTAssertEqual(games[0].id, receivedGame.id)
            })
        })
    }
}
