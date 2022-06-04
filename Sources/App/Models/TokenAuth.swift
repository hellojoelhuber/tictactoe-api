//
//  File.swift
//
//
//  Created by Joel Huber on 5/23/22.
//

import Vapor
import Fluent

final class TokenAuth: Model, Content {
    static let schema = v20220101.schemaName

    @ID
    var id: UUID?

    @Field(key: v20220101.value)
    var value: String

    @Parent(key: v20220101.playerID)
    var player: Player

    init() {}

    init(id: UUID? = nil, value: String, playerID: Player.IDValue) {
        self.id = id
        self.value = value
        self.$player.id = playerID
    }
}

extension TokenAuth {
    static func generate(for player: Player) throws -> TokenAuth {
        let random = [UInt8].random(count: 16).base64
        return try TokenAuth(value: random, playerID: player.requireID())
    }
}

extension TokenAuth: ModelTokenAuthenticatable {
    static let valueKey = \TokenAuth.$value
    static let userKey = \TokenAuth.$player
    typealias User = Player
    var isValid: Bool {
        true
    }
}

