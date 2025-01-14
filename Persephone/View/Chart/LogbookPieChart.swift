//
//  LogbookPieChart.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Charts
import SwiftUI

struct LogbookPieChart: View {
    let nutrients: NutritionDict
    let price: Price
    
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
            if let cal = nutrients[.Energy] {
                Text("\(cal.value.toString(maxDigits: 0)) Cal")
                    .font(.title3).fontWeight(.heavy)
            } else {
                Text("0 Cal")
                    .font(.title3).fontWeight(.heavy)
            }
            Text("\(price.toString())").bold()
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
        (try? nutrients[nutrient]?.convert(unit: .Gram).value)?.value ?? 0
    }
    
    private func amountToString(_ nutrient: Nutrient) -> String {
        (try? nutrients[nutrient]?.convert(unit: .Gram).value)?.toString(maxDigits: 1) ?? "0"
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogbookPieChart(nutrients: [
        .Energy: .calories(120),
        .TotalCarbs: .grams(14),
        .Protein: .grams(11),
        .TotalFat: .grams(4.5),
        .Sodium: .milligrams(120)
    ], price: .Cents(1345)).frame(width: 200, height: 200)
}
