//
//  NutrientsView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/25/24.
//

import SwiftUI

struct NutrientsView: View {
    let nutrients: Nutrients
    let maxDigits: Int
    
    init(nutrients: Nutrients, maxDigits: Int = 0) {
        self.nutrients = nutrients
        self.maxDigits = maxDigits
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
            let amount = nutrients.get(nutrient) ?? .init(value: .zero, unit: nutrient.getCommonUnit())
            if (nutrient == .Energy) {
                Text(amount.value.formatted(maxDigits: maxDigits))
            } else {
                Text(amount.formatted(maxDigits: maxDigits))
            }
        }
        .italic(indented).padding(EdgeInsets(top: 0.0, leading: indented ? 8.0 : 0.0, bottom: 0.0, trailing: 0.0))
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NavigationStack {
        Form {
            NutrientsView(nutrients: [
                .Energy: 120.5,
                .TotalCarbs: 13,
                .TotalFat: 2.4,
                .Protein: 6.7
            ])
        }
    }
}
