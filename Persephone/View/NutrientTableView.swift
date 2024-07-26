//
//  NutrientTableView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/25/24.
//

import SwiftUI

struct NutrientTableView: View {
    var nutrients: [Nutrient : FoodAmount]
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            createRow(name: "Calories", nutrient: .Energy).bold().font(.title)
            createRow(name: "Total Fat", nutrient: .TotalFat).bold()
            createRow(name: "Saturated Fat", nutrient: .SaturatedFat, indented: true).font(.subheadline)
            createRow(name: "Trans Fat", nutrient: .TransFat, indented: true).font(.subheadline)
            createRow(name: "Polyunsaturated Fat", nutrient: .PolyunsaturatedFat, indented: true).font(.subheadline)
            createRow(name: "Monounsaturated Fat", nutrient: .MonounsaturatedFat, indented: true) .font(.subheadline)
            createRow(name: "Cholesterol", nutrient: .Cholesterol).bold()
            createRow(name: "Sodium", nutrient: .Sodium).bold()
            createRow(name: "Total Carbohydrates", nutrient: .TotalCarbs).bold()
            createRow(name: "Dietary Fiber", nutrient: .DietaryFiber, indented: true).font(.subheadline)
            createRow(name: "Total Sugars", nutrient: .TotalSugars, indented: true).font(.subheadline)
            createRow(name: "Added Sugars", nutrient: .AddedSugars, indented: true).font(.subheadline)
            createRow(name: "Protein", nutrient: .Protein).bold()
            createRow(name: "Vitamin D", nutrient: .VitaminD).font(.subheadline)
            createRow(name: "Calcium", nutrient: .Calcium).font(.subheadline)
            createRow(name: "Iron", nutrient: .Iron).font(.subheadline)
            createRow(name: "Potassium", nutrient: .Potassium).font(.subheadline)
        }
    }
    
    private func createRow(name: String, nutrient: Nutrient, indented: Bool = false) -> some View {
        HStack {
            Text(name)
            Spacer()
            if (nutrient == .Energy) {
                Text(format(nutrient))
            } else {
                Text("\(format(nutrient)) \(nutrient.getCommonUnit().getAbbreviation())")
            }
        }
        .italic(indented)
        .padding(EdgeInsets(top: 0.0, leading: indented ? 8.0 : 0.0, bottom: 0.0, trailing: 0.0))
    }
    
    private func format(_ nutrient: Nutrient) -> String {
        formatter.string(for: nutrients[nutrient]?.value ?? 0)!
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        NutrientTableView(nutrients: item.ingredients.nutrients)
    }.modelContainer(container)
}
