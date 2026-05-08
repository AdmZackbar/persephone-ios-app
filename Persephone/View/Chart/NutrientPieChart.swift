//
//  NutrientPieChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Charts
import SwiftUI

struct NutrientPieChart: View {
    let data: [MacroData]
    
    init(nutrients: Nutrients = [:]) {
        self.data = nutrients.toMacroData()
    }
    
    var body: some View {
        ZStack {
            Chart(data) { d in
                SectorMark(
                    angle: .value("Amount", d.calories),
                    innerRadius: .ratio(0.7),
                    outerRadius: .inset(8),
                    angularInset: 2
                ).cornerRadius(4)
                    .foregroundStyle(d.macro?.color ?? .gray)
            }.chartLegend(.hidden)
                .padding(4)
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
                    let protein = getNutrientString(.protein)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Protein")
                        Text(protein)
                    }.foregroundStyle(.protein)
                    Spacer()
                    let carbs = getNutrientString(.carbs)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Carbs")
                        Text(carbs)
                    }.foregroundStyle(.carbs)
                }
                Spacer()
                let fat = getNutrientString(.fat)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Fat")
                    Text(fat)
                }.foregroundStyle(.fat)
            }.font(.caption)
                .fontWeight(.heavy)
        }
    }
    
    @ViewBuilder
    private func chartOverlay(_ frame: CGRect) -> some View {
        VStack(spacing: 2) {
            Text(data.totalCalories.formatted(.number.precision(.fractionLength(0))))
                .font(.title3).fontWeight(.heavy)
            Text("Cal")
                .font(.caption).bold()
        }.position(x: frame.midX, y: frame.midY)
    }
    
    private func getNutrientString(_ macro: Macro) -> String {
        return "\(data.first(where: { $0.macro == macro })?.grams.formatted(.number.precision(.fractionLength(0))) ?? "0")g"
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
