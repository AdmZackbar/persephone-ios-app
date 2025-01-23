//
//  RecipeLogEntry.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/20/25.
//

import Foundation
import SwiftData

typealias RecipeLogEntry = SchemaV1.RecipeLogEntry

extension SchemaV1 {
    @Model
    final class RecipeLogEntry {
        var date: Date = Date()
        var recipe: RecipeEntry! = nil
        var amountScale: Double = 1
        var meal: String = ""
        
        init(date: Date = .now,
             recipe: RecipeEntry? = nil,
             amountScale: Double = 1,
             meal: String = "") {
            self.date = date
            self.recipe = recipe
            self.amountScale = amountScale
            self.meal = meal
        }
    }
}
