//
//  Store.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/22/24.
//


import Foundation
import SwiftData

typealias Store = SchemaV1.Store
typealias StoreItem = SchemaV1.StoreItem
typealias PriceHistoryEntry = SchemaV1.PriceHistoryEntry
typealias Price = SchemaV1.Price

extension SchemaV1 {
    @Model
    final class Store {
        // The name of the store
        @Attribute(.unique) var name: String
        // An image of the store
        @Attribute(.externalStorage) var imageData: Data?
        
        // All items that this store carries
        @Relationship(deleteRule: .cascade, inverse: \StoreItem.store)
        var items: [StoreItem] = []
        // The shopping list for this store
        @Relationship(deleteRule: .cascade, inverse: \ShoppingList.store)
        var shoppingList: ShoppingList? = nil
        
        init(name: String, imageData: Data? = nil) {
            self.name = name
            self.imageData = imageData
        }
    }
    
    @Model
    final class StoreItem {
        // The store of this item
        var store: Store!
        // The food
        var foodItem: FoodItem!
        // The number of items that are sold (i.e. sold in a pack of 2 -> quantity: 2)
        var quantity: Int
        // The price of the overall item
        var price: Price
        // Currently available to purchase
        var available: Bool
        // Previous prices over time (date it changed to be different and the price up until that point)
        var priceHistory: [PriceHistoryEntry]
        
        @Relationship(deleteRule: .cascade, inverse: \ShoppingListEntry.storeItem)
        var shoppingListEntries: [ShoppingListEntry] = []
        
        init(store: Store, foodItem: FoodItem, quantity: Int, price: Price, available: Bool, priceHistory: [PriceHistoryEntry] = []) {
            self.store = store
            self.foodItem = foodItem
            self.quantity = quantity
            self.price = price
            self.available = available
            self.priceHistory = priceHistory
        }
    }
    
    struct PriceHistoryEntry: Codable, Equatable, Hashable {
        // The date that the item changed to a DIFFERENT price (from this price)
        var dateChanged: Date
        // The price of the item up until the date change
        var price: Price
    }
    
    struct Price: Codable, Equatable, Hashable {
        // The price of an item in US cents
        var cents: Int
        
        func toString() -> String {
            let formatter: NumberFormatter = {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.maximumFractionDigits = 2
                return formatter
            }()
            return formatter.string(for: (Double(cents) / 100.0))!
        }
    }
}
