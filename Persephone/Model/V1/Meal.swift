//
//  Meal.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/17/25.
//

import Foundation
import SwiftData

typealias Meal = SchemaV1.Meal
typealias MealItem = SchemaV1.MealItem

extension SchemaV1 {
    @Model
    final class Meal {
        var name: String = ""
        var notes: String = ""
        var creationDate: Date = Date()
        
        @Relationship(deleteRule: .cascade, inverse: \MealItem.meal)
        var items: [MealItem]! = []
        
        init(name: String = "",
             notes: String = "",
             creationDate: Date = .init(),
             items: [MealItem] = []) {
            self.name = name
            self.notes = notes
            self.creationDate = creationDate
            self.items = items
        }
    }
    
    @Model
    final class MealItem {
        var meal: Meal! = nil
        var food: Food! = nil
        var defaultAmount: Amount = Amount(value: .one)
        var servingCost: Currency? = nil
        
        init(meal: Meal? = nil,
             food: Food? = nil,
             defaultAmount: Amount = .init(value: .one),
             servingCost: Currency? = nil) {
            self.meal = meal
            self.food = food
            self.defaultAmount = defaultAmount
            self.servingCost = servingCost
        }
    }
}
