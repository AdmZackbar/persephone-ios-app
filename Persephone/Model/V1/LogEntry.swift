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
        var amount: Quantity = Quantity.grams(0)
        var category: String = ""
        var type: LogType = LogType.actual
        var price: Price? = nil
        
        init(date: Date = Date(),
             item: FoodItem,
             amount: Quantity = .grams(0),
             category: String = "",
             type: LogType = .actual,
             price: Price? = nil) {
            self.date = date
            self.item = item
            self.amount = amount
            self.category = category
            self.type = type
            self.price = price
        }
    }
    
    enum LogType: Codable {
        case actual
        case plan
    }
}
