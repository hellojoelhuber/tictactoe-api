//
//  File.swift
//
//
//  Created by Joel Huber on 5/23/22.
//

import Fluent
import Vapor

final class TokenResetPassword: Model, Content {
    static let schema = v20220101.schemaName

    @ID
    var id: UUID?

    @Field(key: v20220101.token)
    var token: String

    @Parent(key: v20220101.playerID)
    var player: Player

    init() {}

    init(id: UUID? = nil, token: String, playerID: Player.IDValue) {
        self.id = id
        self.token = token
        self.$player.id = playerID
    }
}
