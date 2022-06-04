//
//  File.swift
//
//
//  Created by Joel Huber on 5/31/22.
//

import Foundation

extension Game {
    private func checkWinRow(row: Int, actions: [Int]) -> Bool {
        for col in 0..<boardColumns {
            if !actions.contains((boardColumns * row) + col) {
                return false
            }
        }
        return true
    }
    
    private func checkWinColumn(column: Int, actions: [Int]) -> Bool {
        for row in 0..<boardRows {
            if !actions.contains(column + (boardRows * row)) {
                return false
            }
        }
        return true
    }
    
    // These two Validate Diagonal funcs only work for fixed AxA sized boards right now.
    private func checkWinDiagonalZero(actions: [Int]) -> Bool {
        for row in 0..<boardRows {
            if !actions.contains(row * (boardColumns+1)) {
                return false
            }
        }
        return true
    }
    
    private func checkWinDiagonalMid(actions: [Int]) -> Bool {
        for row in 0..<boardRows {
            if !actions.contains((boardColumns-1) * (1+row)) {
                return false
            }
        }
        return true
    }
    
    func checkWin(row: Int, col: Int, actions: [Int]) -> Bool {
        if checkWinRow(row: row, actions: actions)
        || checkWinColumn(column: col, actions: actions)
        || checkWinDiagonalZero(actions: actions)
        || checkWinDiagonalMid(actions: actions)
        {
            return true
        }
        return false
    }
}
