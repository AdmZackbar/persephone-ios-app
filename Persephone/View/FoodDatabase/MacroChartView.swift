//
//  MacroChartView.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/29/24.
//

import Charts
import SwiftUI

struct MacroChartView: View {
    var nutrients: NutritionDict
    var scale: Double
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    init(nutrients: NutritionDict, scale: Double = 1) {
        self.nutrients = nutrients
        self.scale = scale
    }
    
    var body: some View {
        let data = createData()
        return ZStack {
            Chart(data, id: \.name) { name, amount in
                SectorMark(
                    angle: .value("Amount", amount),
                    innerRadius: .ratio(0.65),
                    outerRadius: .inset(8),
                    angularInset: 2
                ).cornerRadius(4)
                    .foregroundStyle(by: .value("Macro type", name))
            }.chartLegend(.hidden)
                .chartForegroundStyleScale([
                    "Carbs": Color.green,
                    "Fat": Color.orange,
                    "Protein": Color.purple,
                    "None": Color.gray
                ])
            VStack(spacing: 2) {
                if let cal = nutrients[.Energy] {
                    Text((cal.value * scale).toString(maxDigits: 0))
                        .font(.title3).fontWeight(.heavy)
                } else {
                    Text("0")
                        .font(.title3).fontWeight(.heavy)
                }
                Text("Cal")
                    .font(.caption).bold()
            }
            VStack(spacing: 0) {
                HStack {
                    Text("Protein")
                        .font(.caption).fontWeight(.heavy).foregroundStyle(.purple)
                    Spacer()
                }
                HStack {
                    Text("\(formatter.string(for: computeAmount(.Protein))!)g")
                        .font(.caption).bold().foregroundStyle(.purple)
                    Spacer()
                }
                Spacer()
            }
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Carbs").font(.caption).fontWeight(.heavy).foregroundStyle(.green)
                }
                HStack {
                    Spacer()
                    Text("\(formatter.string(for: computeAmount(.TotalCarbs))!)g")
                        .font(.caption).bold().foregroundStyle(.green)
                }
                Spacer()
            }
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Text("Fat")
                        .font(.caption).fontWeight(.heavy).foregroundStyle(.orange)
                    Spacer()
                }
                HStack {
                    Text("\(formatter.string(for: computeAmount(.TotalFat))!)g")
                        .font(.caption).bold().foregroundStyle(.orange)
                    Spacer()
                }
            }
        }
    }
    
    private func createData() -> [(name: String, amount: Double)] {
        let data = [
            (name: "Carbs", amount: computeAmount(.TotalCarbs) * 4),
            (name: "Fat", amount: computeAmount(.TotalFat) * 9),
            (name: "Protein", amount: computeAmount(.Protein) * 4)
        ]
        if data.allSatisfy({ (name: String, amount: Double) in amount <= 0 }) {
            return [(name: "None", amount: 1)]
        }
        return data
    }
    
    private func computeAmount(_ nutrient: Nutrient) -> Double {
        if let amount = try? nutrients[nutrient]?.toGrams().value {
            (amount * scale).value
        } else {
            0
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return MacroChartView(nutrients: item.ingredients.nutrients)
}
