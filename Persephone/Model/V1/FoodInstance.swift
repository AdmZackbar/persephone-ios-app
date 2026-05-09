//
//  FoodInstance.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/8/26.
//

import Foundation
import SwiftData

typealias FoodInstance = SchemaV1.FoodInstance

extension SchemaV1 {
    @Model
    final class FoodInstance {
        var food: Food! = nil
        var acquireDate: Date = Date()
        var source: String = ""
        var cost: Currency = Currency.zero
        var total: FoodSize = FoodSize()
        var remainder: Double = 1.0
        
        init(food: Food! = nil,
             acquireDate: Date = .now,
             source: String = "",
             cost: Currency = .zero,
             total: FoodSize = .init(),
             remainder: Double = 1.0) {
            self.food = food
            self.acquireDate = acquireDate
            self.source = source
            self.cost = cost
            self.total = total
            self.remainder = remainder
        }
    }
}
