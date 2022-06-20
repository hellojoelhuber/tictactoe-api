//
//  File.swift
//  
//
//  Created by Joel Huber on 6/5/22.
//

import Vapor
import TicTacToeCore

extension GameActionDTO: Content {}

extension GameActionDTO {
    init(_ action: GameAction) throws {
        self.init(playerID: action.$player.id,
                      turnNumber: action.turnNumber,
                      action: action.action
        )
    }
}
