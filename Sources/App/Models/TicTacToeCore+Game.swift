//
//  File.swift
//  
//
//  Created by Joel Huber on 6/4/22.
//

import Vapor
import TicTacToeCore

extension GameAPIModel: Content {}

extension GameAPIModel {
    init(_ game: Game, nextTurn: Player?, winner: Player?, createdBy: Player, players: [Player]) throws {
        try self.init(id: game.requireID(),
                      boardRows: game.boardRows,
                      boardColumns: game.boardColumns,
                      isPasswordProtected: game.password != nil ? true : false,
                      isMutualFollowsOnly: game.isMutualFollowsOnly,
                      playerCount: game.playerCount,
                      openSeats: game.openSeats,
                      completeTurnsCount: game.completeTurnsCount,
                      nextTurn: nextTurn?.convertToPublic(),
                      isComplete: game.isComplete,
                      winner: winner?.convertToPublic(),
                      createdBy: createdBy.convertToPublic(),
                      createdAt: game.createdAt!,
                      updatedAt: game.updatedAt!,
                      players: players.convertToPublic())
    }
}
