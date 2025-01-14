//
//  LogEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/23/24.
//

import Foundation
import SwiftData

typealias LogFoodItemEntry = SchemaV1.LogFoodItemEntry

extension SchemaV1 {
    @Model
    final class LogFoodItemEntry {
        var date: Date = Date()
        var item: FoodItem! = nil
        var amount: Quantity.Magnitude = Quantity.Magnitude.Raw(1)
        var amountUnit: Unit? = nil
        var category: String = ""
        var unitPrice: Price? = nil
        var nutrients: NutritionDict {
            item.ingredients.nutrients * amount.value
        }
        var price: Price? {
            if let unitPrice {
                unitPrice * (amount.value / item.size.numServings)
            } else {
                nil
            }
        }
        
        init(date: Date = Date(),
             item: FoodItem,
             amount: Quantity.Magnitude = .Raw(1),
             amountUnit: Unit? = nil,
             category: String = "",
             unitPrice: Price? = nil) {
            self.date = date
            self.item = item
            self.amount = amount
            self.amountUnit = amountUnit
            self.category = category
            self.unitPrice = unitPrice
        }
    }
}
