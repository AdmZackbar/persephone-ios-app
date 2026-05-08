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
    let textLayout: TextLayout
    
    init(nutrients: Nutrients = [:],
         textFormat: TextFormat = .none,
         textLayout: TextLayout = .bottom) {
        self.data = nutrients.toMacroData()
        self.textFormat = textFormat
        self.textLayout = textLayout
    }
    
    var body: some View {
        Chart(data) { d in
            BarMark(
                x: .value("Size", d.calories)
            ).cornerRadius(8)
                .foregroundStyle(d.macro?.color ?? .gray)
                .annotation(position: textLayout.position, alignment: .center, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                    if let text = format(d) {
                        Text(text)
                            .fontWeight(.bold)
                            .foregroundStyle(textLayout.getColor(d))
                            .padding(textLayout.paddingSide, -6)
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
            return Amount.init(value: .raw(data.grams), unit: .gram)
                .formatted(maxDigits: 0, includeSpace: false)
        case .percent:
            return (data.calories / self.data.totalCalories)
                .formatted(.percent.precision(.fractionLength(0)))
        }
    }
    
    enum TextFormat {
        case none, gram, percent
    }
    
    enum TextLayout {
        case top, center, bottom
        
        var position: AnnotationPosition {
            switch self {
            case .top:
                return .top
            case .center:
                return .overlay
            case .bottom:
                return .bottom
            }
        }
        
        var paddingSide: Edge.Set {
            // Flip side (we want text to get closer to the bar)
            switch self {
            case .top:
                return .bottom
            case .center:
                return []
            case .bottom:
                return .top
            }
        }
        
        func getColor(_ data: MacroData) -> Color {
            switch self {
            case .top, .bottom:
                // Above or below bar, use same color as bar
                return data.macro?.color ?? .primary
            case .center:
                // Can't use the same color as the bar, default to background
                return .background
            }
        }
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
        MacroBarChart(nutrients: nutrients, textFormat: .gram)
            .frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients, textFormat: .percent)
            .frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients, textFormat: .percent, textLayout: .top)
            .frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients, textFormat: .percent, textLayout: .center)
            .frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients).frame(height: 10)
            
    }.padding([.leading, .trailing], 12)
}
