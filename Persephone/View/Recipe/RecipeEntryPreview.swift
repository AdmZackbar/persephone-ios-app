//
//  RecipeEntryPreview.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/20/25.
//

import SwiftUI

struct RecipeEntryPreview: View {
    let entry: RecipeEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .opacity(0.7)
                        .italic()
                    Text(entry.name)
                        .font(.title3)
                        .bold()
                    Text(entry.total.formatted())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let cost = entry.cost {
                        Text(cost.formatted())
                            .font(.subheadline)
                            .italic()
                    }
                }
                Gauge(value: entry.remainingScale, in: 0...1) {
                    Text(entry.remaining.value.formatted(maxDigits: 0))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }.gaugeStyle(.accessoryCircularCapacity)
            }
            NutrientPieChart(nutrients: entry.nutrients / entry.total.amount.value.raw)
                .frame(width: 160, height: 120)
        }
    }
}
