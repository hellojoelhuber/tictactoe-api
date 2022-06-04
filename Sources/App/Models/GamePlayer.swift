//
//  File.swift
//
//
//  Created by Joel Huber on 5/24/22.
//

import Fluent
import Vapor

final class GamePlayer: Model, Content {
    static let schema = GamePlayer.v20220524.schemaName
    
    @ID
    var id: UUID?
    
    @Parent(key: v20220524.playerID)
    var player: Player
    
    @Parent(key: v20220524.gameID)
    var game: Game
    
    @Field(key: v20220524.turnOrder)
    var turnOrder: Int
    
    init() {
        self.turnOrder = 1
    }
}
