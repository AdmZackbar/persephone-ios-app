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
    let data: [MacroData]
    
    init(text: String = "", nutrients: Nutrients = [:]) {
        self.text = text
        self.data = nutrients.toMacroData()
    }
    
    var body: some View {
        Chart(data) { d in
            SectorMark(
                angle: .value("Amount", d.calories),
                innerRadius: .ratio(0.75),
                angularInset: 1
            ).cornerRadius(1)
                .foregroundStyle(d.macro?.color ?? .gray)
        }.chartLegend(.hidden)
            .padding(4)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if !text.isEmpty, let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        Text(text).position(x: frame.midX, y: frame.midY)
                    }
                }
            }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    VStack {
        MiniNutrientPieChart()
            .frame(width: 40, height: 40)
            .font(.subheadline)
        MiniNutrientPieChart(text: "1", nutrients: [
            .Energy: 120,
            .TotalCarbs: 14,
            .Protein: 11,
            .TotalFat: 4.5,
            .Sodium: 120
        ]).frame(width: 40, height: 40)
        MiniNutrientPieChart(text: "31")
            .frame(width: 40, height: 40)
            .font(.subheadline)
    }
}
