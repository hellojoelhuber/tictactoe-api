//
//  File.swift
//  
//
//  Created by Joel Huber on 6/4/22.
//

import Vapor
import TicTacToeCore

extension PlayerDTO: Content {}

extension PlayerDTO {
    init(_ player: Player) throws {
        try self.init(id: player.requireID(),
                      username: player.username,
                      profileIcon: player.profileIcon)
    }
}
