//
//  File.swift
//
//
//  Created by Joel Huber on 5/29/22.
//

import Vapor
import Fluent

final class PlayerFollowing: Model, Content {
    static let schema = PlayerFollowing.v20220531.schemaName
    
    @ID
    var id: UUID?
    
    @Parent(key: v20220531.playerID)
    var player: Player
    
    @Parent(key: v20220531.followingID)
    var following: Player
    
    // createdAt on the relationship helps us order the list of followed players.
    // Is there any sense in adding updatedAt and deletedAt, especially since there's a unique constraint on player/following?
    @Timestamp(key: v20220601.createdAt, on: .create)
    var createdAt: Date?
    
    init() {}
}
