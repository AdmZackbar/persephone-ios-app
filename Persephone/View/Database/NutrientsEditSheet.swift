//
//  NutrientsEditSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/25/24.
//

import SwiftData
import SwiftUI

struct NutrientsEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding private var nutrients: Nutrients
    @State private var nutrientAmounts: Nutrients
    
    init(nutrients: Binding<Nutrients>) {
        self._nutrients = nutrients
        self.nutrientAmounts = nutrients.wrappedValue
    }
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.zeroSymbol = ""
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            List {
                createNutrientEntry(.Energy).font(.title2).bold()
                createNutrientEntry(.TotalFat).bold()
                createNutrientEntry(.SaturatedFat).fontWeight(.light)
                createNutrientEntry(.TransFat).fontWeight(.light)
                createNutrientEntry(.PolyunsaturatedFat).fontWeight(.light)
                createNutrientEntry(.MonounsaturatedFat).fontWeight(.light)
                createNutrientEntry(.Cholesterol).bold()
                createNutrientEntry(.Sodium).bold()
                createNutrientEntry(.TotalCarbs).bold()
                createNutrientEntry(.DietaryFiber).fontWeight(.light)
                createNutrientEntry(.TotalSugars).fontWeight(.light)
                createNutrientEntry(.AddedSugars).fontWeight(.light)
                createNutrientEntry(.Protein).bold()
                createNutrientEntry(.VitaminD).italic().fontWeight(.light)
                createNutrientEntry(.Potassium).italic().fontWeight(.light)
                createNutrientEntry(.Calcium).italic().fontWeight(.light)
                createNutrientEntry(.Iron).italic().fontWeight(.light)
            }.navigationTitle("Edit Nutrients")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Revert") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            nutrients = nutrientAmounts
                            dismiss()
                        }
                    }
                }
        }
    }
    
    private func createNutrientEntry(_ nutrient: Nutrient) -> some View {
        HStack(spacing: 8) {
            Text(getFieldName(nutrient))
            TextField("", value: Binding<Double>(get: {
                nutrientAmounts[nutrient, default: 0]
            }, set: { value in
                nutrientAmounts[nutrient] = value
            }), formatter: formatter)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
            if (nutrient != .Energy && nutrientAmounts[nutrient, default: 0] > 0) {
                Text(nutrient.getCommonUnit().abbreviation)
            }
        }.swipeActions(allowsFullSwipe: false) {
            if nutrientAmounts[nutrient, default: 0] > 0 {
                Button("Clear") {
                    clearEntry(nutrient)
                }.tint(.red)
            }
            if nutrientAmounts[nutrient, default: 0] > 0 {
                Button("Round") {
                    roundEntry(nutrient)
                }.tint(.blue)
            }
        }.contextMenu {
            Button("Clear") {
                clearEntry(nutrient)
            }.disabled(nutrientAmounts[nutrient, default: 0] <= 0)
            Button("Round") {
                roundEntry(nutrient)
            }.disabled(nutrientAmounts[nutrient, default: 0] <= 0)
        }
    }
    
    private func roundEntry(_ nutrient: Nutrient) {
        if let amount = nutrientAmounts[nutrient] {
            nutrientAmounts[nutrient] = round(amount)
        }
    }
    
    private func clearEntry(_ nutrient: Nutrient) {
        nutrientAmounts[nutrient] = nil
    }
    
    private func getFieldName(_ nutrient: Nutrient) -> String {
        switch nutrient {
        case .Energy:
            return "Calories:"
        case .TotalFat:
            return "Total Fat:"
        case .SaturatedFat:
            return "Sat. Fat:"
        case .TransFat:
            return "Trans Fat:"
        case .PolyunsaturatedFat:
            return "Poly. Fat:"
        case .MonounsaturatedFat:
            return "Mono. Fat:"
        case .Sodium:
            return "Sodium:"
        case .Cholesterol:
            return "Cholesterol:"
        case .TotalCarbs:
            return "Total Carbs:"
        case .DietaryFiber:
            return "Dietary Fiber:"
        case .TotalSugars:
            return "Total Sugars:"
        case .AddedSugars:
            return "Added Sugars:"
        case .Protein:
            return "Protein:"
        case .VitaminD:
            return "Vitamin D:"
        case .Potassium:
            return "Potassium:"
        case .Calcium:
            return "Calcium:"
        case .Iron:
            return "Iron:"
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NutrientsEditSheet(nutrients: .constant([:]))
}
