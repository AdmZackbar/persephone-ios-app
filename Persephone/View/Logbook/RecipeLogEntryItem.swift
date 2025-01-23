//
//  RecipeLogEntryItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

import Foundation

struct RecipeLogEntryItem {
    private var entry: RecipeLogEntry?
    var isEdit: Bool {
        entry != nil
    }
    
    var isInvalid: Bool {
        recipe == nil ||
        amountScale <= 0 ||
        amountScale > 1 ||
        meal == ""
    }
    
    var date: Date
    var recipe: RecipeEntry?
    var amountScale: Double
    var meal: String
    
    init(entry: RecipeLogEntry) {
        self.entry = entry
        self.date = entry.date
        self.recipe = entry.recipe
        self.amountScale = entry.amountScale
        self.meal = entry.meal
    }
    
    init(date: Date = .now,
         meal: String = "") {
        self.entry = nil
        self.date = date
        self.recipe = nil
        self.amountScale = 1
        self.meal = meal
    }
    
    mutating func save() -> RecipeLogEntry? {
        if let entry {
            entry.date = date
            entry.recipe = recipe
            entry.amountScale = amountScale
            entry.meal = meal
            return nil
        }
        entry = .init(date: date, recipe: recipe, amountScale: amountScale, meal: meal)
        return entry!
    }
}
