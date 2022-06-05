//
//  File.swift
//
//
//  Created by Joel Huber on 5/23/22.
//

@testable import App
import XCTVapor
import TicTacToeCore

final class UserTests: XCTestCase {
    let usersFirstName = "Alice"
    let usersLastName = "Tester"
    let usersUsername = "alicea"
    let usersURI = "/api/users/"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func test_AllUsers_CanBeRetrieved() throws {
        let user = try Player.create(firstName: usersFirstName,
                                   lastName: usersLastName,
                                   username: usersUsername,
                                   on: app.db)
        _ = try Player.create(on: app.db)
        
        try app.test(.GET, usersURI, loggedInUser: user, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let users = try response.content.decode([PlayerAPIModel].self)
            
            XCTAssertEqual(users.count, 3)
            // Must get the second element in the array because of the admin user.
            XCTAssertEqual(users[1].username, usersUsername)
            XCTAssertEqual(users[1].id, user.id)
        })
    }
    
    func test_SingleUser_CanBeRetrieved() throws {
        let user = try Player.create(firstName: usersFirstName,
                                   lastName: usersLastName,
                                   username: usersUsername,
                                   on: app.db)
        
        try app.test(.GET, "\(usersURI)\(user.id!)", loggedInUser: user, afterResponse: { response in
            let receivedUser = try response.content.decode(PlayerAPIModel.self)
            
            XCTAssertEqual(receivedUser.username, usersUsername)
            XCTAssertEqual(receivedUser.id, user.id)
        })
    }
    
    func test_UserProfile_CanBeRetrieved() throws {
        let user = try Player.create(firstName: usersFirstName,
                                     lastName: usersLastName,
                                     username: usersUsername,
                                     on: app.db)
        
        try app.test(.GET, "\(usersURI)\(user.id!)/profile", loggedInUser: user, afterResponse: { response in
            let receivedUser = try response.content.decode(PlayerProfileDTO.self)
            
            XCTAssertEqual(receivedUser.username, usersUsername)
            XCTAssertEqual(receivedUser.id, user.id)
            XCTAssertEqual(receivedUser.gamesPlayed, 0)
            XCTAssertEqual(receivedUser.gamesWon, 0)
        })
        
        let game = Game(createdBy: user.id!)
        try app.test(.POST, "/api/game/create", loggedInUser: user, beforeRequest: { req in
            try req.content.encode(game)
        }, afterResponse: { response in
            let receivedGame = try response.content.decode(GameAPIModel.self)
            try app.test(.POST, "/api/game/\(receivedGame.id)/join", loggedInRequest: true, afterResponse: { response in
                XCTAssertEqual(response.status, .created)
            })
            try app.test(.GET, "\(usersURI)\(user.id!)/profile", loggedInUser: user, afterResponse: { response in
                let receivedUser = try response.content.decode(PlayerProfileDTO.self)
                
                XCTAssertEqual(receivedUser.username, usersUsername)
                XCTAssertEqual(receivedUser.id, user.id)
                XCTAssertEqual(receivedUser.gamesPlayed, 1)
                XCTAssertEqual(receivedUser.gamesWon, 0)
            })
            
            
            try app.test(.POST, "/api/game/\(receivedGame.id)/resign", loggedInRequest: true, afterResponse: { response in
                XCTAssertEqual(response.status, .ok)
            })

            try app.test(.POST, "/api/game/create", loggedInUser: user, beforeRequest: { req in
                try req.content.encode(game)
            }, afterResponse: { response in
                let receivedSecondGame = try response.content.decode(GameAPIModel.self)
                try app.test(.POST, "/api/game/\(receivedSecondGame.id)/join", loggedInRequest: true, afterResponse: { response in
                    XCTAssertEqual(response.status, .created)
                })

                try app.test(.GET, "\(usersURI)\(user.id!)/profile", loggedInUser: user, afterResponse: { response in
                    let receivedUser = try response.content.decode(PlayerProfileDTO.self)

                    XCTAssertEqual(receivedUser.username, usersUsername)
                    XCTAssertEqual(receivedUser.id, user.id)
                    XCTAssertEqual(receivedUser.gamesPlayed, 2)
                    XCTAssertEqual(receivedUser.gamesWon, 1)
                })
            })
        })
    }
    
    func test_User_CanFollow_AnotherUser() throws {
        let sally = try Player.create(firstName: "sally", lastName: "fields", username: "sally", on: app.db)
        let timmy = try Player.create(firstName: "timmy", lastName: "wilds", username: "timmy", on: app.db)
        
        try app.test(.POST, "\(usersURI)\(sally.id!)/follow", loggedInUser: timmy, afterResponse: { response in
            let receivedUser = try response.content.decode(PlayerAPIModel.self)
            
            XCTAssertEqual(receivedUser.username, sally.username)
            XCTAssertEqual(receivedUser.id, sally.id)
        })
    }
    
    func test_User_CanRetrieve_FollowedPlayers() throws {
        let sally = try Player.create(firstName: "sally", lastName: "fields", username: "sally", on: app.db)
        let timmy = try Player.create(firstName: "timmy", lastName: "wilds", username: "timmy", on: app.db)
        
        try app.test(.POST, "\(usersURI)\(sally.id!)/follow", loggedInUser: timmy, afterResponse: { response in
            let receivedUser = try response.content.decode(PlayerAPIModel.self)
            
            try app.test(.GET, "\(usersURI)following", loggedInUser: timmy, afterResponse: { secondResponse in
                let followedPlayers = try secondResponse.content.decode([PlayerAPIModel].self)
                XCTAssertEqual(followedPlayers.count, 1)
                
                XCTAssertEqual(followedPlayers[0].username, receivedUser.username)
                XCTAssertEqual(followedPlayers[0].id, receivedUser.id)
            })
        })
    }
    
    func test_User_CanBeCreated() throws {
        let user = Player(firstName: usersFirstName,
                        lastName: usersLastName,
                        username: usersUsername,
                        password: "password",
                        email: "\(usersUsername)@test.com")

        
        try app.test(.POST, usersURI, loggedInRequest: true, beforeRequest: { req in
            try req.content.encode(user)
        }, afterResponse: { response in
            let receivedUser = try response.content.decode(PlayerAPIModel.self)
            
            XCTAssertEqual(receivedUser.username, usersUsername)
            XCTAssertNotNil(receivedUser.id)
            
            try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { secondResponse in
                let users = try secondResponse.content.decode([PlayerAPIModel].self)
                XCTAssertEqual(users.count, 2)
                XCTAssertEqual(users[1].username, usersUsername)
                XCTAssertEqual(users[1].id, receivedUser.id)
            })
        })
    }
    
    func test_User_CanBeSoftDeleted() throws {
        let user = try Player.create(on: app.db)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let users = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(users.count, 2)
        })
        
        try app.test(.DELETE, "\(usersURI)\(user.id!)", loggedInRequest: true)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let newUsers = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(newUsers.count, 1)
        })
    }
    
    func test_DeletedUser_CanBeRestored() throws {
        let user = try Player.create(on: app.db)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let users = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(users.count, 2)
        })
        
        try app.test(.DELETE, "\(usersURI)\(user.id!)", loggedInRequest: true)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let newUsers = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(newUsers.count, 1)
        })
        
        try app.test(.POST, "\(usersURI)\(user.id!)/restore", loggedInRequest: true)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let users = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(users.count, 2)
        })
    }
    
    func test_User_CanBeHardDeleted() throws {
        //tokenAuthGroup.delete(":userID","force", use: forceDeleteHandler)
        let user = try Player.create(on: app.db)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let users = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(users.count, 2)
        })
        
        try app.test(.DELETE, "\(usersURI)\(user.id!)/force", loggedInRequest: true)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let newUsers = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(newUsers.count, 1)
        })
        
        try app.test(.POST, "\(usersURI)\(user.id!)/restore", loggedInRequest: true)
        
        try app.test(.GET, usersURI, loggedInRequest: true, afterResponse: { response in
            let users = try response.content.decode([PlayerAPIModel].self)
            XCTAssertEqual(users.count, 1)
        })
    }
    
    // TODO: Write test for UserCanLogin
//    func test_UserCanLogIn() throws {
////        let basicAuthMiddleware = User.authenticator()
////        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
////        basicAuthGroup.post("login", use: loginHandler)
//    }
}
