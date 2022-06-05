//
//  File.swift
//  
//
//  Created by Joel Huber on 6/5/22.
//

import Vapor
import TicTacToeCore

extension PlayerProfileDTO: Content {}

extension PlayerProfileDTO {
    init(_ player: Player, gamesPlayed: Int, gamesWon: Int) throws {
        try self.init(id: player.requireID(),
                      username: player.username,
                      gamesPlayed: gamesPlayed,
                      gamesWon: gamesWon)
    }
}
