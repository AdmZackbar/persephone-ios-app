//
//  CommercialFood.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/13/24.
//

import Foundation
import SwiftData

typealias CommercialFood = SchemaV1.CommercialFood

extension SchemaV1 {
    @Model
    final class CommercialFood: Hashable, Equatable {
        var name: String
        var seller: String
        var cost: FoodItem.Cost
        var nutrients: [Nutrient : FoodAmount]
        var metaData: MetaData
        
        init(name: String, seller: String, cost: FoodItem.Cost, nutrients: [Nutrient : FoodAmount], metaData: MetaData) {
            self.name = name
            self.seller = seller
            self.cost = cost
            self.nutrients = nutrients
            self.metaData = metaData
        }
        
        struct MetaData: Codable, Hashable, Equatable {
            var timestamp: Date
            var notes: String
            var rating: Double?
            var tags: [String]
            
            init(timestamp: Date = Date(), notes: String, rating: Double? = nil, tags: [String]) {
                self.timestamp = timestamp
                self.notes = notes
                self.rating = rating
                self.tags = tags
            }
        }
    }
}
