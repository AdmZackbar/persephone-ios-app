//
//  FoodLogEntryPreview.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import SwiftUI

struct FoodLogEntryPreview: View {
    let entry: FoodLogEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(entry.food.name)
                        .font(.headline)
                    if let brand = entry.food.brand {
                        Text(brand)
                            .font(.subheadline)
                            .italic()
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(entry.size.amount.formatted(includeSpace: true))
                        .bold()
                    Text(entry.size.value.formatted(includeSpace: true))
                        .font(.subheadline).bold()
                }
            }
            NutrientPieChart(nutrients: entry.nutrients)
                .frame(width: 160, height: 120)
        }
    }
}
