//
//  MacroBarChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/7/26.
//

import Charts
import SwiftUI

struct MacroBarChart: View {
    let data: [MacroData]
    let textFormat: TextFormat
    
    init(nutrients: Nutrients = [:], textFormat: TextFormat = .none) {
        self.data = nutrients.toMacroData()
        self.textFormat = textFormat
    }
    
    var body: some View {
        Chart(data) { d in
            BarMark(
                x: .value("Size", d.calories)
            ).cornerRadius(8)
                .foregroundStyle(d.macro?.color ?? .gray)
                .annotation(position: .bottom, alignment: .center, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                    if let text = format(d) {
                        Text(text)
                            .fontWeight(.bold)
                            .foregroundStyle(d.macro?.color ?? .gray)
                            .padding(.top, -6)
                    }
                }
        }.chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
    }
    
    private func format(_ data: MacroData) -> String? {
        switch textFormat {
        case .none:
            return nil
        case .gram:
            return Amount.init(value: .raw(data.grams), unit: Units.gram)
                .formatted(maxDigits: 0, includeSpace: false)
        case .percent:
            return (data.calories / self.data.totalCalories)
                .formatted(.percent.precision(.fractionLength(0)))
        }
    }
    
    enum TextFormat {
        case none, gram, percent
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
        MacroBarChart(nutrients: nutrients, textFormat: .gram).frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients, textFormat: .percent).frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients).frame(height: 10)
            
    }.padding([.leading, .trailing], 12)
}
