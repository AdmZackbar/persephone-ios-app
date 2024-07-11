//
//  FoodItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import Foundation
import SwiftData

@Model
final class FoodItem {
    // When this item was recorded
    var timestamp: Date
    // The UPC barcode of the item
    var barcode: String?
    // The described name of the item
    var name: String
    // The name of the brand that makes the item
    var brand: String
    // Describes this item in more detail
    var details: String
    // The price of the item in its entirity (in US cents)
    var price: Int
    // Where the item was purchased from
    var store: String
    // The total number of servings that the item contains
    var numServings: Int
    // Describes what the serving is
    var servingSize: String
    // The total 'size' of the item (described by sizeType)
    //  - Mass: in grams (g)
    //  - Volume: in milliliters (mL)
    var totalSize: Int
    // The type of item this is (by weight or volume)
    var sizeType: SizeType
    // TODO nutrients
    
    init(timestamp: Date, barcode: String? = nil, name: String, brand: String, details: String, price: Int, store: String, numServings: Int, servingSize: String, totalSize: Int, sizeType: SizeType) {
        self.timestamp = timestamp
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.details = details
        self.price = price
        self.store = store
        self.numServings = numServings
        self.servingSize = servingSize
        self.totalSize = totalSize
        self.sizeType = sizeType
    }
}

enum SizeType: Codable {
    case Mass, Volume
}
