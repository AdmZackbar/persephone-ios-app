//
//  NutrientTableView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/25/24.
//

import SwiftUI

struct NutrientTableView: View {
    var nutrients: NutritionDict
    var scale: Double
    
    init(nutrients: NutritionDict, scale: Double = 1) {
        self.nutrients = nutrients
        self.scale = scale
    }
    
    var body: some View {
        VStack(spacing: 12) {
            createRow(name: "Calories", nutrient: .Energy)
                .bold().font(.title2)
            createRow(name: "Total Fat", nutrient: .TotalFat)
                .font(.subheadline).bold()
            createRow(name: "Saturated Fat", nutrient: .SaturatedFat, indented: true)
                .font(.caption)
            createRow(name: "Trans Fat", nutrient: .TransFat, indented: true)
                .font(.caption)
            createRow(name: "Polyunsaturated Fat", nutrient: .PolyunsaturatedFat, indented: true)
                .font(.caption)
            createRow(name: "Monounsaturated Fat", nutrient: .MonounsaturatedFat, indented: true) 
                .font(.caption)
            createRow(name: "Cholesterol", nutrient: .Cholesterol)
                .font(.subheadline).bold()
            createRow(name: "Sodium", nutrient: .Sodium)
                .font(.subheadline).bold()
            createRow(name: "Total Carbohydrates", nutrient: .TotalCarbs)
                .font(.subheadline).bold()
            createRow(name: "Dietary Fiber", nutrient: .DietaryFiber, indented: true)
                .font(.caption)
            createRow(name: "Total Sugars", nutrient: .TotalSugars, indented: true)
                .font(.caption)
            createRow(name: "Added Sugars", nutrient: .AddedSugars, indented: true)
                .font(.caption)
            createRow(name: "Protein", nutrient: .Protein)
                .font(.subheadline).bold()
            createRow(name: "Vitamin D", nutrient: .VitaminD)
                .font(.caption)
            createRow(name: "Calcium", nutrient: .Calcium)
                .font(.caption)
            createRow(name: "Iron", nutrient: .Iron)
                .font(.caption)
            createRow(name: "Potassium", nutrient: .Potassium)
                .font(.caption)
        }
    }
    
    private func createRow(name: String, nutrient: Nutrient, indented: Bool = false) -> some View {
        HStack {
            Text(name)
            Spacer()
            let amount = ((nutrients[nutrient]?.value ?? .Raw(0)) * scale).toString(maxDigits: 1)
            if (nutrient == .Energy) {
                Text(amount)
            } else {
                Text("\(amount) \(nutrient.getCommonUnit().abbreviation)")
            }
        }
        .italic(indented).padding(EdgeInsets(top: 0.0, leading: indented ? 8.0 : 0.0, bottom: 0.0, trailing: 0.0))
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        NutrientTableView(nutrients: item.ingredients.nutrients)
    }.modelContainer(container)
}
