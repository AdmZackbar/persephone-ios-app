//
//  FoodPreview.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/19/25.
//

import SwiftUI

struct FoodPreview: View {
    let food: Food
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(food.name)
                        .font(.headline)
                    if let brand = food.brand {
                        Text(brand)
                            .font(.subheadline)
                            .italic()
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(food.servingSize.amount.formatted(includeSpace: true))
                        .bold()
                    Text(food.servingSize.value.formatted(includeSpace: true))
                        .font(.subheadline).bold()
                }
            }
            NutrientPieChart(nutrients: food.ingredients.nutrients)
                .frame(width: 160, height: 120)
        }
    }
}
