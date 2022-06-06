//
//  File.swift
//
//
//  Created by Joel Huber on 5/24/22.
//

import Vapor
import Fluent
import TicTacToeCore

final class Game: Model, Content {
    static let schema = v20220524.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: v20220529.playerCount)
    var playerCount: Int // Max player count in a game.
    
    @Field(key: v20220530.boardRows)
    var boardRows: Int
    
    @Field(key: v20220530.boardColumns)
    var boardColumns: Int
    
    @Field(key: v20220531.password)
    var password: String?
    
    @Field(key: v20220531.isMutualFollowsOnly)
    var isMutualFollowsOnly: Bool
    
    @Field(key: v20220528.openSeats)
    var openSeats: Int
    
    @Field(key: v20220524.isComplete)
    var isComplete: Bool
    
    @OptionalParent(key: v20220524.nextTurn)
    var nextTurn: Player? // references the turn order
    
    @Field(key: v20220524.completeTurnsCount)
    var completeTurnsCount: Int // how many turns total have passed // for TTT, this will be 0 to 9.
    
    @OptionalParent(key: v20220524.winner)
    var winner: Player? // the turn order
    
    @Timestamp(key: v20220524.createdAt, on: .create)
    var createdAt: Date?
    
    @Parent(key: v20220524.createdBy)
    var createdBy: Player

    @Timestamp(key: v20220524.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: v20220524.deletedAt, on: .delete)
    var deletedAt: Date?
    
    @Siblings(through: GamePlayer.self,
              from: \.$game,
              to: \.$player)
    var players: [Player]
    
    init() {
        self.playerCount = 2    // For TTT, playerCount is always 2.
        self.openSeats = 1      // For TTT, playerCount = 2 & the creator is 1 seat.
        self.completeTurnsCount = 0
        self.isComplete = false
    }
    
    init(playerCount: Int = 2,
         boardRows: Int = 3, boardColumns: Int = 3,
         password: String? = nil, isMutualFollowsOnly: Bool = false,
         createdBy: Player.IDValue) {
        self.boardRows = boardRows
        self.boardColumns = boardColumns
        self.password = password
        self.isMutualFollowsOnly = isMutualFollowsOnly
        self.playerCount = playerCount  // For TTT, playerCount is always 2.
        self.openSeats = playerCount-1  // The creator is 1 seat, so playerCount-1.
        self.completeTurnsCount = 0
        self.isComplete = false
        self.$createdBy.id = createdBy
    }
}

extension Game {
    func convertToPublic() -> GameDTO {
        return GameDTO(id: id!,
                       boardRows: boardRows,
                       boardColumns: boardColumns,
                       isPasswordProtected: password != nil,
                       isMutualFollowsOnly: isMutualFollowsOnly,
                       playerCount: playerCount,
                       openSeats: openSeats,
                       completeTurnsCount: completeTurnsCount,
                       nextTurn: nextTurn?.convertToPublic(),
                       isComplete: isComplete,
                       winner: winner?.convertToPublic(),
                       createdBy: createdBy.convertToPublic(),
                       createdAt: createdAt!,
                       updatedAt: updatedAt!,
                       players: players.convertToPublic())
    }
}

extension Collection where Element: Game {
    func convertToPublic() -> [GameDTO] {
        return self.map { $0.convertToPublic() }
    }
}


extension Game {
    func convertToActiveDTO(playersEagerLoaded: Bool) -> GameActiveDTO {
        return GameActiveDTO(id: id!,
                             boardRows: boardRows,
                             boardColumns: boardColumns,
                             nextTurn: nextTurn?.convertToPublic(),
                             players: playersEagerLoaded ? players.convertToPublic() : []
        )
    }
}

extension Collection where Element: Game {
    func convertToActiveDTO(playersEagerLoaded: Bool) -> [GameActiveDTO] {
        return self.map { $0.convertToActiveDTO(playersEagerLoaded: playersEagerLoaded) }
    }
}
