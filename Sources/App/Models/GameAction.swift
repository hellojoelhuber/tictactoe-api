//
//  File.swift
//
//
//  Created by Joel Huber on 5/24/22.
//

import Fluent
import Vapor

final class GameAction: Model, Content {
    static let schema = v20220527.schemaName
    
    @ID
    var id: UUID?
    
    @Parent(key: v20220527.gameID)
    var game: Game
    
    @Parent(key: v20220527.playerID)
    var player: Player
    
    @Field(key: v20220527.turnNumber)
    var turnNumber: Int
    
    @Field(key: v20220527.actionNumber)
    var actionNumber: Int // For TicTacToe, actionNumber will always == 1
    
    @Timestamp(key: v20220527.createdAt, on: .create)
    var createdAt: Date?
    
    @Field(key: v20220527.action)
    var action: Int
    // Using 0-8 for action, to indicate the target square.
    // The view should interpret the int as either 0-8 or as row = FLOOR(action/3), col = action %% 3. The int is fine for TTT's complexity.
    
    // need to think about action.
    // Probably varies by game. For TTT, is it Int -> 0..8 on the board? Or is it tuple (row, col)?
    // For RPS, is it an enum of r, p, s?
    // For other games, it's going to be multiple types of actions. May need more than 1 field to capture it.
    // e.g., an enum of .draw, .move, etc.; and a target field, which points to units?; and gosh, all this gets so complicated.
    
    init() {}
    
    init(gameID: Game.IDValue, playerID: Player.IDValue,
         turnNumber: Int, actionNumber: Int, action: Int) {
        self.$game.id = gameID
        self.$player.id = playerID
        self.turnNumber = turnNumber
        self.actionNumber = actionNumber
        self.action = action
    }
    
    final class Public: Content {
        let playerID: UUID
        let turnNumber: Int
        let action: Int
        
        init(playerID: UUID, turnNumber: Int, action: Int) {
            self.playerID = playerID
            self.turnNumber = turnNumber
            self.action = action
        }
    }
}

extension GameAction {
    func convertToPublic() -> GameAction.Public {
        return GameAction.Public(playerID: _player.id, turnNumber: turnNumber, action: action)
    }
}

extension Collection where Element: GameAction {
    func convertToPublic() -> [GameAction.Public] {
        return self.map { $0.convertToPublic() }
    }
}
