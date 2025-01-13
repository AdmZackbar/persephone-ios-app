//
//  LogEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/23/24.
//

import Foundation
import SwiftData

typealias LogFoodItemEntry = SchemaV1.LogFoodItemEntry
typealias LogType = SchemaV1.LogType

extension SchemaV1 {
    @Model
    final class LogFoodItemEntry {
        var date: Date = Date()
        var item: FoodItem! = nil
        var amount: Quantity.Magnitude = Quantity.Magnitude.Raw(1)
        var category: String = ""
        var type: LogType = LogType.actual
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
             category: String = "",
             type: LogType = .actual,
             unitPrice: Price? = nil) {
            self.date = date
            self.item = item
            self.amount = amount
            self.category = category
            self.type = type
            self.unitPrice = unitPrice
        }
    }
    
    enum LogType: Codable {
        case actual
        case plan
    }
}
