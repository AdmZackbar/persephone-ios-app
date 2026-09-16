//
//  NutrientsSummaryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/16/26.
//

import SwiftUI

struct LogEntriesSummaryView: View {
    let entries: [LogEntry]
    
    var body: some View {
        let nutrients = entries.map { $0.nutrients }.reduce([:], +)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                Text(nutrients.calories.formatted())
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Text(entries.map({ $0.cost ?? .zero }).reduce(.zero, +).formatted())
                    .font(.title3)
                    .fontWeight(.bold)
            }
            HStack {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 24, verticalSpacing: 2) {
                    GridRow {
                        Text("Carbs")
                        Text("Fat")
                        Text("Protein")
                    }.font(.subheadline)
                        .fontWeight(.light)
                    GridRow {
                        Text(nutrients.get(.TotalCarbs)?.formatted() ?? "0 g")
                            .foregroundStyle(.carbs)
                        Text(nutrients.get(.TotalFat)?.formatted() ?? "0 g")
                            .foregroundStyle(.fat)
                        Text(nutrients.get(.Protein)?.formatted() ?? "0 g")
                            .foregroundStyle(.protein)
                        
                    }.font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Sodium")
                        .font(.subheadline)
                        .fontWeight(.light)
                    Text(nutrients.get(.Sodium)?.formatted() ?? "0 mg")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            MacroBarChart(nutrients: nutrients, textFormat: .percent, textLayout: .center)
                .font(.caption2)
                .frame(height: 12)
                .padding(.top, 4)
        }
    }
}
