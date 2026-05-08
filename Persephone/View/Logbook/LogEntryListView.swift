//
//  LogEntryListView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/6/26.
//

import SwiftUI

struct LogEntryListView: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .fontWeight(.semibold)
                HStack(alignment: .top, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let brand = entry.brand {
                            Text(brand)
                        }
                        Text(entry.date.formatted(date: .omitted, time: .shortened))
                    }.font(.subheadline).italic()
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.amount.formatted())
                            .fontWeight(.bold)
                        if let cost = entry.cost {
                            Text(cost.formatted())
                                .italic()
                        }
                    }.font(.subheadline)
                }
            }
            MiniNutrientPieChart(text: entry.nutrients.calories.value.formatted(), nutrients: entry.nutrients)
                .frame(width: 64, height: 64)
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    Form {
        LogEntryListView(entry: .food(.init(food: .init(name: "Test Food"))))
        LogEntryListView(entry: .food(.init(food: .init(name: "Top Sirloin Steak", metaData: .init(brand: "Publix")), amount: .init(value: .raw(300), unit: .gram), meal: "Breakfast")))
        LogEntryListView(entry: .food(.init(food: .init(name: "Lightly Breaded Chicken Breast Chunks", metaData: .init(brand: "Kirkland Signature"), ingredients: .init(nutrients: [.Energy : 900]), servingSize: .init(str: "1 serving", val: 90)), amount: .init(value: .raw(300), unit: .gram), meal: "Breakfast")))
    }
}
