//
//  File.swift
//
//
//  Created by Joel Huber on 5/23/22.
//

@testable import App
import Fluent
import Vapor

extension Player {
    static func create(firstName: String = "Luke",
                       lastName: String = "Skywalker",
                       username: String? = nil,
                       on database: Database
    ) throws -> Player {
        let createUsername: String
        if let suppliedUsername = username {
            createUsername = suppliedUsername
        } else {
            createUsername = UUID().uuidString
        }

        let password = try Bcrypt.hash("password")
        let user = Player(firstName: firstName,
                        lastName: lastName,
                        username: createUsername,
                        password: password,
                        email: "\(createUsername)@test.com")

        try user.save(on: database).wait()
        return user
    }
}

extension Game {
    static func create(createdBy: Player.IDValue, on database: Database) throws -> Game {
        let game = Game(createdBy: createdBy)

        try game.save(on: database).wait()
        return game
    }
}
