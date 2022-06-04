//
//  File.swift
//
//
//  Created by Joel Huber on 5/30/22.
//

import Vapor

struct GameSettings: Content {
    let rows: Int
    let columns: Int
    let password: String?
    let isMutualFollowsOnly: Bool
    
    init(rows: Int = 3, columns: Int = 3, password: String? = nil, isMutualFollowsOnly: Bool = false) {
        self.rows = rows
        self.columns = columns
        self.password = password
        self.isMutualFollowsOnly = isMutualFollowsOnly
    }
    
    final class Join: Content {
        var password: String

        init(password: String) {
            self.password = password
        }
    }
    
    final class Search: Content {
        var myGames: Bool?
        var active: Bool?
        var minRows: Int?
        var maxRows: Int?
        var minColumns: Int?
        var maxColumns: Int?
        var isPasswordProtected: Bool?
        var isMutualFollowsOnly: Bool?
        var following: Bool?
        
        init(myGames: Bool? = nil, active: Bool? = nil,
             minRows: Int? = 3,  maxRows: Int? = nil,
             minColumns: Int? = 3, maxColumns: Int? = nil,
             isPasswordProtected: Bool? = nil,
             isMutualFollowsOnly: Bool? = nil, following: Bool? = nil) {
            self.myGames = myGames
            self.active = active
            self.minRows = minRows
            self.maxRows = maxRows
            self.minColumns = minColumns
            self.maxColumns = maxColumns
            self.isPasswordProtected = isPasswordProtected
            self.isMutualFollowsOnly = isMutualFollowsOnly
            self.following = following
        }
    }
}
