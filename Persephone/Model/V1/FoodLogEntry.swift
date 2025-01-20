//
//  FoodLogEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import Foundation
import SwiftData

typealias FoodLogEntry = SchemaV1.FoodLogEntry

extension SchemaV1 {
    @Model
    final class FoodLogEntry {
        var date: Date = Date()
        var food: Food! = nil
        var amount: Amount = Amount(value: .one)
        var meal: String = ""
        var servingCost: Currency? = nil
        
        init(date: Date = .now,
             food: Food? = nil,
             amount: Amount = .init(value: .one),
             meal: String = "",
             servingCost: Currency? = nil) {
            self.date = date
            self.food = food
            self.amount = amount
            self.meal = meal
            self.servingCost = servingCost
        }
    }
}
