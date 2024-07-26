//
//  ShoppingList.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/22/24.
//

import Foundation
import SwiftData

typealias ShoppingList = SchemaV1.ShoppingList
typealias ShoppingListEntry = SchemaV1.ShoppingListEntry

extension SchemaV1 {
    @Model
    final class ShoppingList {
        // The store that this list is for
        var store: Store!
        // The date that we want to go shopping on
        var targetDate: Date
        
        // All entries for this list
        @Relationship(deleteRule: .cascade, inverse: \ShoppingListEntry.shoppingList)
        var entries: [ShoppingListEntry] = []
        
        init(store: Store, targetDate: Date) {
            self.store = store
            self.targetDate = targetDate
        }
    }
    
    @Model
    final class ShoppingListEntry {
        // The shopping list of this entry
        var shoppingList: ShoppingList!
        // The item of this entry
        var storeItem: StoreItem!
        // The amount of items to buy
        var amount: Int
        // Any additional notes about the item
        var notes: String?
        
        init(shoppingList: ShoppingList, storeItem: StoreItem, amount: Int, notes: String? = nil) {
            self.shoppingList = shoppingList
            self.storeItem = storeItem
            self.amount = amount
            self.notes = notes
        }
    }
}
