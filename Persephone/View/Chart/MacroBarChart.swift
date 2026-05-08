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
    let textFormat: TextFormat
    
    init(nutrients: Nutrients = [:], textFormat: TextFormat = .none) {
        self.nutrients = nutrients
        self.textFormat = textFormat
    }
    
    var body: some View {
        let data = createData()
        Chart(data) { d in
            BarMark(
                x: .value("Size", d.energy)
            ).cornerRadius(8)
                .foregroundStyle(d.macro?.color ?? .gray)
                .annotation(position: .bottom, alignment: .center, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                    if let text = d.format(textFormat, totalEnergy: data.map({ $0.energy }).reduce(0, +)) {
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
    
    private func createData() -> [Data] {
        let data = Macro.allCases.map({ Data(macro: $0, nutrients: nutrients) })
        if data.allSatisfy({ $0.value <= 0.0 }) {
            // Return 'none' value
            return [.init()]
        }
        return data
    }
    
    enum TextFormat {
        case none, gram, percent
    }
    
    private struct Data: Identifiable {
        var id: String {
            if let macro {
                macro.rawValue
            } else {
                "None"
            }
        }
        
        let macro: Macro?
        let value: Double
        var energy: Double {
            if let macro {
                value * macro.modifier
            } else {
                1.0
            }
        }
        
        init() {
            self.macro = nil
            self.value = 1.0
        }
        
        init(macro: Macro, nutrients: Nutrients) {
            self.macro = macro
            self.value = nutrients[macro.nutrient, default: 0.0]
        }
        
        func format(_ textFormat: TextFormat, totalEnergy: Double) -> String? {
            switch textFormat {
            case .none:
                return nil
            case .gram:
                return Amount.init(value: .raw(value), unit: Units.gram).formatted(maxDigits: 0, includeSpace: false)
            case .percent:
                return (energy / totalEnergy).formatted(.percent.precision(.fractionLength(0)))
            }
        }
    }
    
    private enum Macro: String, CaseIterable {
        case carbs, fat, protein
        
        var nutrient: Nutrient {
            switch self {
            case .carbs:
                return .TotalCarbs
            case .fat:
                return .TotalFat
            case .protein:
                return .Protein
            }
        }
        var modifier: Double {
            switch self {
            case .carbs, .protein:
                return 4
            case .fat:
                return 9
            }
        }
        var color: Color {
            switch self {
            case .carbs:
                return .carbs
            case .fat:
                return .fat
            case .protein:
                return .protein
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
        MacroBarChart(nutrients: nutrients, textFormat: .gram).frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients, textFormat: .percent).frame(height: 20)
            .font(.caption)
        MacroBarChart(nutrients: nutrients).frame(height: 10)
            
    }.padding([.leading, .trailing], 12)
}
