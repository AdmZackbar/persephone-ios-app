//
//  MacroBarChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/7/26.
//

import Charts
import SwiftUI

struct MacroBarChart: View {
    let nutrients: Nutrients
    let showText: Bool
    
    init(nutrients: Nutrients = [:], showText: Bool = false) {
        self.nutrients = nutrients
        self.showText = showText
    }
    
    var body: some View {
        Chart(createData(), id: \.name) { item in
            BarMark(
                x: .value("Size", item.amount)
            ).cornerRadius(4)
                .foregroundStyle(by: .value("Macro type", item.name))
                .annotation(position: .bottom, alignment: .center, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                    if showText {
                        Text(item.text)
                            .fontWeight(.bold)
                    }
                }
        }.chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartForegroundStyleScale([
                "Carbs": .carbs,
                "Fat": .fat,
                "Protein": .protein,
                "None": .gray
            ])
            .chartLegend(.hidden)
    }
    
    private func createData() -> [(name: String, amount: Double, text: String)] {
        let data = [
            (name: "Carbs", amount: nutrients[.TotalCarbs, default: 0] * 4, text: format(.TotalCarbs)),
            (name: "Fat", amount: nutrients[.TotalFat, default: 0] * 9, text: format(.TotalFat)),
            (name: "Protein", amount: nutrients[.Protein, default: 0] * 4, text: format(.Protein)),
        ]
        if data.allSatisfy({ (name: String, amount: Double, text: String) in amount <= 0 }) {
            return [(name: "None", amount: 1, text: "")]
        }
        return data
    }
    
    private func format(_ nutrient: Nutrient) -> String {
        return Amount.init(value: .raw(nutrients[nutrient, default: 0.0]), unit: Units.gram).formatted(maxDigits: 0, includeSpace: false)
    }
}

#Preview {
    VStack(spacing: 50) {
        let nutrients: Nutrients = [
            .Energy: 200,
            .TotalCarbs: 1,
            .TotalFat: 14,
            .Protein: 30,
        ]
        MacroBarChart().frame(height: 10)
        MacroBarChart(nutrients: nutrients, showText: true).frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients).frame(height: 10)
            
    }.padding()
}
