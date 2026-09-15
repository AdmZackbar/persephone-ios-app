//
//  DaySummaryFamilyViews.swift
//  PersephoneWidget
//
//  Created by Zach Wassynger on 9/15/26.
//

import SwiftUI
import WidgetKit

private func caloriesText(_ entry: DaySummaryEntry) -> String {
    entry.nutrients.calories.value.formatted(maxDigits: 0)
}

private func grams(_ entry: DaySummaryEntry, _ macro: Macro) -> String {
    entry.nutrients.get(macro.nutrient)?.formatted(maxDigits: 0, includeSpace: false) ?? "0g"
}

struct SmallDaySummaryView: View {
    let entry: DaySummaryEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("Today")
                .font(.caption).fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            MiniNutrientPieChart(text: caloriesText(entry), nutrients: entry.nutrients)
                .font(.headline).fontWeight(.bold)
                .frame(width: 78, height: 78)

            HStack(spacing: 6) {
                ForEach(Macro.allCases, id: \.rawValue) { macro in
                    Text(grams(entry, macro))
                        .foregroundStyle(macro.color)
                }
            }
            .font(.caption2).fontWeight(.semibold)
        }
        .redacted(reason: entry.isDataAvailable ? [] : .placeholder)
    }
}

struct MediumDaySummaryView: View {
    let entry: DaySummaryEntry

    var body: some View {
        HStack(spacing: 14) {
            MiniNutrientPieChart(text: caloriesText(entry), nutrients: entry.nutrients)
                .font(.title3).fontWeight(.bold)
                .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption).fontWeight(.semibold)
                Text(entry.nutrients.calories.formatted())
                    .font(.title2).fontWeight(.bold)

                Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 1) {
                    GridRow {
                        ForEach(Macro.allCases, id: \.rawValue) { Text($0.name) }
                    }.fontWeight(.light)
                    GridRow {
                        ForEach(Macro.allCases, id: \.rawValue) { macro in
                            Text(grams(entry, macro)).foregroundStyle(macro.color)
                        }
                    }.fontWeight(.semibold)
                }
                .font(.caption2)

                MacroBarChart(nutrients: entry.nutrients,
                              textFormat: .percent, textLayout: .center)
                    .font(.system(size: 8))
                    .frame(height: 11)
            }
        }
        .redacted(reason: entry.isDataAvailable ? [] : .placeholder)
    }
}

struct CircularDaySummaryView: View {
    let entry: DaySummaryEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            MiniNutrientPieChart(nutrients: entry.nutrients)
            VStack(spacing: -2) {
                Text(caloriesText(entry))
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.6)
                Text("Cal").font(.system(size: 8))
            }
        }
        .widgetAccentable()
    }
}

struct RectangularDaySummaryView: View {
    let entry: DaySummaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Today").font(.headline).widgetAccentable()
            Text(entry.nutrients.calories.formatted())
                .font(.body).fontWeight(.semibold)
            Text(Macro.allCases.map { "\($0.name.prefix(1)) \(grams(entry, $0))" }
                    .joined(separator: " · "))
                .font(.caption2)
            MacroBarChart(nutrients: entry.nutrients)
                .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
