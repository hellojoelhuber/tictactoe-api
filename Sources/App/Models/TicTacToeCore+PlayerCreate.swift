//
//  File.swift
//  
//
//  Created by Joel Huber on 6/18/22.
//

import Vapor
import TicTacToeCore

extension PlayerCreateDTO: Content {}

extension PlayerCreateDTO {
    init(_ player: Player) throws {
        self.init(firstName: player.firstName,
                      lastName: player.lastName,
                      username: player.username,
                      password: player.password,
                      email: player.email,
                      profileIcon: player.profileIcon)
    }
}

extension PlayerCreateDTO {
    func convertToPlayer() -> Player {
        Player(firstName: firstName,
               lastName: lastName,
               username: username,
               password: password,
               email: email,
               profileIcon: profileIcon)
    }
}
