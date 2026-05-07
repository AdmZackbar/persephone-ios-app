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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .fontWeight(.semibold)
                HStack {
                    if let brand = entry.brand {
                        Text(brand)
                    }
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                }.font(.caption).italic()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.amount.formatted())
                    .font(.subheadline)
                    .fontWeight(.bold)
                if let cost = entry.cost {
                    Text(cost.formatted())
                        .font(.caption)
                        .italic()
                }
            }
            MiniNutrientPieChart(text: entry.nutrients.calories.value.formatted(), nutrients: entry.nutrients)
                .frame(width: 56, height: 56)
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    LogEntryListView(entry: .food(.init(food: .init(name: "Test Food"))))
}
