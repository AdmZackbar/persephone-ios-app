//
//  FoodLogEntryItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/18/25.
//

import Foundation
import SwiftData

struct FoodLogEntryItem {
    private var entry: FoodLogEntry?
    var isEdit: Bool {
        entry != nil
    }
    
    var isInvalid: Bool {
        food == nil ||
        amount.value.raw <= 0 ||
        meal == ""
    }
    
    var numServings: Double {
        // Amount / Serving Amount
        if let food {
            if let modifier = amount.unit?.modifier {
                return (amount.value.raw * modifier) / food.servingSize.val
            }
            return amount.value.raw / food.servingSize.amount.value.raw
        }
        return amount.value.raw
    }
    
    var size: FoodSize? {
        if let food {
            return food.servingSize * numServings
        }
        return nil
    }
    
    var date: Date
    var food: Food?
    var amount: Amount
    var meal: String
    var servingCost: Currency?
    
    init(entry: FoodLogEntry) {
        self.entry = entry
        self.date = entry.date
        self.food = entry.food
        self.amount = entry.amount
        self.meal = entry.meal
        self.servingCost = entry.servingCost
    }
    
    init(date: Date = .now,
         food: Food? = nil,
         amount: Amount = .init(),
         meal: String = "",
         servingCost: Currency? = nil) {
        self.entry = nil
        self.date = date
        self.food = food
        self.amount = amount
        self.meal = meal
        self.servingCost = servingCost
    }
    
    mutating func save(_ modelContext: ModelContext) {
        if !isEdit {
            entry = .init()
            modelContext.insert(entry!)
        }
        let entry = entry!
        entry.date = date
        entry.food = food
        entry.amount = amount
        entry.meal = meal
        entry.servingCost = servingCost
    }
}
