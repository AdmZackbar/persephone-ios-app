//
//  NutrientScaleSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/15/24.
//

import SwiftUI

struct NutrientScaleSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let item: FoodItem
    
    @State private var scale: Double = 1
    @State private var nutrients: [Nutrient : FoodAmount] = [:]
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 3
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Scale:")
                    TextField("", value: $scale, formatter: formatter).keyboardType(.decimalPad)
                }
                Button("Revert to Default") {
                    scale = 1
                }
                Section("Nutrients") {
                    NutrientTableView(nutrients: computeScaledNutrients())
                }
            }.navigationTitle("Scale Nutrient Amounts")
                .navigationBarBackButtonHidden()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            item.ingredients.nutrients = computeScaledNutrients()
                            dismiss()
                        }.disabled(scale <= 0)
                    }
                }
        }.presentationDetents([.large])
            .onAppear {
                nutrients = item.ingredients.nutrients
            }
    }
    
    private func computeScaledNutrients() -> [Nutrient : FoodAmount] {
        nutrients.mapValues({ amount in
            FoodAmount(value: amount.value * scale, unit: amount.unit)
        })
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NutrientScaleSheet(item: item)
}
