//
//  LogbookPieChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Charts
import SwiftUI

struct LogbookPieChart: View {
    let nutrients: Nutrients
    let price: Currency
    
    var body: some View {
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
    }
    
    @ViewBuilder
    private func chartOverlay(_ frame: CGRect) -> some View {
        VStack(spacing: 2) {
            Text((nutrients.get(.Energy) ?? .init(value: .zero, unit: Units.calorie)).formatted())
                .font(.title3).fontWeight(.heavy)
            Text(price.formatted()).bold()
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
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogbookPieChart(nutrients: [
        .Energy: 120,
        .TotalCarbs: 14,
        .Protein: 11,
        .TotalFat: 4.5,
        .Sodium: 120
    ], price: .dollars(13.45)).frame(width: 200, height: 200)
}
