//
//  MiniNutrientPieChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/6/26.
//

import Charts
import SwiftUI

struct MiniNutrientPieChart: View {
    let text: String
    let nutrients: Nutrients
    
    var body: some View {
        Chart(createData(), id: \.name) { name, amount in
            SectorMark(
                angle: .value("Amount", amount),
                innerRadius: .ratio(0.75),
                angularInset: 1
            ).cornerRadius(1)
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
                        Text(text).position(x: frame.midX, y: frame.midY)
                    }
                }
            }
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
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    VStack {
        MiniNutrientPieChart(text: "1", nutrients: [
            .Energy: 120,
            .TotalCarbs: 14,
            .Protein: 11,
            .TotalFat: 4.5,
            .Sodium: 120
        ]).frame(width: 40, height: 40)
        MiniNutrientPieChart(text: "31", nutrients: [:])
            .frame(width: 40, height: 40)
            .font(.subheadline)
    }
}
