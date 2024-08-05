//
//  RecipeIngredientSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/4/24.
//

import SwiftUI

struct RecipeIngredientSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let ingredient: RecipeIngredient?
    
    @State private var name: String = ""
    @State private var amount: String = ""
    private var amountValue: Double? {
        get {
            if let match = amount.wholeMatch(of: /([\d.]+)\s+(.+)/) {
                return Double(match.1)
            } else if !amount.trimmingCharacters(in: .whitespaces).isEmpty {
                return 1
            }
            return nil
        }
    }
    private var amountUnit: FoodUnit? {
        get {
            var unitName: String?
            if let match = amount.wholeMatch(of: /([\d.]+)\s+(.+)/) {
                unitName = match.2.string
            } else if !amount.trimmingCharacters(in: .whitespaces).isEmpty {
                unitName = amount.trimmingCharacters(in: .whitespaces)
            } else {
                return nil
            }
            return tryConvertToUnit(unitName: unitName!)
        }
    }
    @State private var notes: String = ""
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    private func tryConvertToUnit(unitName: String) -> FoodUnit? {
        switch unitName.trimmingCharacters(in: .punctuationCharacters).lowercased() {
        case "c", "cup", "cups":
            return .Cup
        case "fl oz", "fluid ounce", "fluid ounces":
            return .FluidOunce
        case "gal", "gallon", "gallons":
            return .Gallon
        case "g", "gram", "grams":
            return .Gram
        case "kg", "kilogram", "kilograms":
            return .Kilogram
        case "l", "liter", "liters":
            return .Liter
        case "mcg", "microgram", "micrograms":
            return .Microgram
        case "mg", "milligram", "milligrams":
            return .Milligram
        case "ml", "milliliter", "milliliters":
            return .Milliliter
        case "oz", "ounce", "ounces":
            return .Ounce
        case "pt", "pint", "pints":
            return .Pint
        case "lb", "pound", "pounds":
            return .Pound
        case "qt", "quart", "quarts":
            return .Quart
        case "tbsp", "tablespoon", "tablespoons":
            return .Tablespoon
        case "tsp", "teaspoon", "teaspoons":
            return .Teaspoon
        default:
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Name:")
                    TextField("required", text: $name)
                }
                // TODO add link to food item
                HStack {
                    Text("Amount:")
                    TextField("required", text: $amount)
                }
                Section("Notes") {
                    TextField("optional", text: $notes, axis: .vertical).textInputAutocapitalization(.sentences).lineLimit(3...5)
                }
            }.navigationTitle(ingredient == nil ? "Add Ingredient" : "Edit Ingredient")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .onAppear {
                    if let ingredient {
                        name = ingredient.name
                        amount = "\(formatter.string(for: ingredient.amount.value)!) \(ingredient.amount.unit.getAbbreviation())"
                        notes = ingredient.notes ?? ""
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let ingredient {
                                ingredient.name = name
                                ingredient.amount = FoodAmount(value: amountValue!, unit: amountUnit!)
                                ingredient.notes = notes.isEmpty ? nil : notes
                            }
                            dismiss()
                        }.disabled(amountValue == nil || amountUnit == nil)
                    }
                }
        }.presentationDetents([.medium])
    }
}

#Preview {
    RecipeIngredientSheet(ingredient: nil)
}
