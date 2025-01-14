//
//  NutrientPieChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Charts
import SwiftUI

struct NutrientPieChart: View {
    let nutrients: NutritionDict
    let scale: Double
    
    init(nutrients: NutritionDict, scale: Double = 1) {
        self.nutrients = nutrients
        self.scale = scale
    }
    
    var body: some View {
        ZStack {
            Chart(createData(), id: \.name) { name, amount in
                SectorMark(
                    angle: .value("Amount", amount),
                    innerRadius: .ratio(0.7),
                    outerRadius: .inset(8),
                    angularInset: 2
                ).cornerRadius(4)
                    .foregroundStyle(by: .value("Macro type", name))
            }.chartLegend(.hidden)
                .padding(4)
                .chartForegroundStyleScale([
                    "Carbs": Colors.carbs,
                    "Fat": Colors.fat,
                    "Protein": Colors.protein,
                    "None": Color.gray
                ])
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let anchor = chartProxy.plotFrame {
                            let frame = geometry[anchor]
                            chartOverlay(frame)
                        }
                    }
                }
            VStack(alignment: .leading) {
                HStack {
                    let protein = amountToString(.Protein)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Protein")
                        Text("\(protein)g")
                    }.foregroundStyle(Colors.protein)
                    Spacer()
                    let carbs = amountToString(.TotalCarbs)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Carbs")
                        Text("\(carbs)g")
                    }.foregroundStyle(Colors.carbs)
                }
                Spacer()
                let fat = amountToString(.TotalFat)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Fat")
                    Text("\(fat)g")
                }.foregroundStyle(Colors.fat)
            }.font(.caption)
                .fontWeight(.heavy)
        }
    }
    
    @ViewBuilder
    private func chartOverlay(_ frame: CGRect) -> some View {
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
        }.position(x: frame.midX, y: frame.midY)
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
        if let amount = try? nutrients[nutrient]?.convert(unit: .Gram).value {
            (amount * scale).value
        } else {
            0
        }
    }
    
    private func amountToString(_ nutrient: Nutrient) -> String {
        if let amount = try? nutrients[nutrient]?.convert(unit: .Gram).value {
            (amount * scale).toString(maxDigits: 1)
        } else {
            "0"
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NutrientPieChart(nutrients: [
        .Energy: .calories(120),
        .TotalCarbs: .grams(14),
        .Protein: .grams(11),
        .TotalFat: .grams(4.5),
        .Sodium: .milligrams(120)
    ]).frame(width: 200, height: 200)
}
