//
//  NutrientPieChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Charts
import SwiftUI

struct NutrientPieChart: View {
    let nutrients: Nutrients
    
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
                    let protein = getNutrientString(.Protein)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Protein")
                        Text(protein)
                    }.foregroundStyle(Colors.protein)
                    Spacer()
                    let carbs = getNutrientString(.TotalCarbs)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Carbs")
                        Text(carbs)
                    }.foregroundStyle(Colors.carbs)
                }
                Spacer()
                let fat = getNutrientString(.TotalFat)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Fat")
                    Text(fat)
                }.foregroundStyle(Colors.fat)
            }.font(.caption)
                .fontWeight(.heavy)
        }
    }
    
    @ViewBuilder
    private func chartOverlay(_ frame: CGRect) -> some View {
        VStack(spacing: 2) {
            Text(nutrients.calories.value.formatted(maxDigits: 0))
                .font(.title3).fontWeight(.heavy)
            Text("Cal")
                .font(.caption).bold()
        }.position(x: frame.midX, y: frame.midY)
    }
    
    private func createData() -> [(name: String, amount: Double)] {
        let data = [
            (name: "Carbs", amount: nutrients[.TotalCarbs, default: 0] * 4),
            (name: "Fat", amount: nutrients[.TotalFat, default: 0] * 9),
            (name: "Protein", amount: nutrients[.Protein, default: 0] * 4)
        ]
        if data.allSatisfy({ (name: String, amount: Double) in amount <= 0 }) {
            return [(name: "None", amount: 1)]
        }
        return data
    }
    
    private func getNutrientString(_ nutrient: Nutrient) -> String {
        if let amount = nutrients.get(nutrient) {
            return amount.formatted(maxDigits: 0)
        }
        return "0g"
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    NutrientPieChart(nutrients: [
        .Energy: 120,
        .TotalCarbs: 14,
        .Protein: 11,
        .TotalFat: 4.5,
        .Sodium: 120
    ]).frame(width: 200, height: 200)
}
