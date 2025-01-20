//
//  FoodItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/19/25.
//

import SwiftUI

struct FoodItem {
    private var entry: Food?
    var isEdit: Bool {
        entry != nil
    }
    
    var name: String
    var metaData: Food.MetaData
    var ingredients: FoodIngredients
    var servingSize: FoodSize
    var storeEntries: [Food.StoreEntry]
    
    var isInvalid: Bool {
        name.isEmpty || servingSize.str.isEmpty || servingSize.val <= 0
    }
    
    var rating: RatingTier? {
        get {
            if let value = metaData.rating {
                RatingTier.fromRating(rating: value)
            } else {
                nil
            }
        } set(value) {
            metaData.rating = value?.rating
        }
    }
    
    init(entry: Food? = nil) {
        self.entry = entry
        self.name = entry?.name ?? ""
        self.metaData = entry?.metaData ?? .init()
        self.ingredients = entry?.ingredients ?? .init()
        self.servingSize = entry?.servingSize ?? .init()
        self.storeEntries = entry?.storeEntries ?? []
    }
    
    mutating func save() -> Food? {
        if let entry {
            entry.name = name
            entry.metaData = metaData
            entry.ingredients = ingredients
            entry.servingSize = servingSize
            entry.storeEntries = storeEntries
            return nil
        }
        entry = .init(name: name, metaData: metaData, ingredients: ingredients, servingSize: servingSize, storeEntries: storeEntries)
        return entry
    }
}

struct StoreEntryItem {
    @Binding private var entry: Food.StoreEntry
    let isEdit: Bool
    
    var store: String
    var cost: Currency
    var amount: FoodSize
    var isAvailable: Bool
    var isSale: Bool
    
    var isInvalid: Bool {
        store.isEmpty || cost.cents <= 0 || amount.str.isEmpty || amount.val <= 0
    }
    
    init(entry: Binding<Food.StoreEntry>) {
        self._entry = entry
        self.isEdit = true
        self.store = entry.wrappedValue.store
        self.cost = entry.wrappedValue.cost
        self.amount = entry.wrappedValue.amount
        self.isAvailable = entry.wrappedValue.isAvailable
        self.isSale = entry.wrappedValue.isSale
    }
    
    init() {
        self._entry = .constant(.init())
        self.isEdit = false
        self.store = ""
        self.cost = .zero
        self.amount = .init()
        self.isAvailable = true
        self.isSale = false
    }
    
    mutating func save() -> Food.StoreEntry? {
        if isEdit {
            entry.store = store
            entry.cost = cost
            entry.amount = amount
            entry.isAvailable = isAvailable
            entry.isSale = isSale
            return nil
        }
        return .init(store: store, cost: cost, amount: amount, isAvailable: isAvailable, isSale: isSale)
    }
}
