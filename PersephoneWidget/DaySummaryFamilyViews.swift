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

            ZStack {
                // Don't include widget background, unnecessary
                MiniNutrientPieChart(nutrients: entry.nutrients)
                VStack(spacing: -2) {
                    Text(caloriesText(entry))
                        .font(.title3)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.6)
                    Text("Cal").font(.system(size: 10))
                }
            }

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
    @Environment(\.widgetRenderingMode) private var renderingMode
    
    let entry: DaySummaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom) {
                Text(entry.nutrients.calories.formatted())
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.totalCost.formatted())
                    .fontWeight(.bold)
            }
            HStack {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 24, verticalSpacing: 2) {
                    GridRow {
                        Text("Carbs")
                        Text("Fat")
                        Text("Protein")
                    }.fontWeight(.light)
                    GridRow {
                        Text(entry.nutrients.get(.TotalCarbs)?.formatted() ?? "0 g")
                            .foregroundStyle(.carbs)
                        Text(entry.nutrients.get(.TotalFat)?.formatted() ?? "0 g")
                            .foregroundStyle(.fat)
                        Text(entry.nutrients.get(.Protein)?.formatted() ?? "0 g")
                            .foregroundStyle(.protein)
                        
                    }.fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Sodium")
                        .fontWeight(.light)
                    Text(entry.nutrients.get(.Sodium)?.formatted() ?? "0 mg")
                        .fontWeight(.semibold)
                }
            }
            if renderingMode == .fullColor {
                MacroBarChart(nutrients: entry.nutrients, textFormat: .percent, textLayout: .center)
                    .font(.caption2)
                    .frame(height: 12)
                    .padding(.top, 4)
            } else {
                MacroBarChart(nutrients: entry.nutrients, textFormat: .percent, textLayout: .center)
                    .font(.caption2)
                    .frame(height: 12)
                    .padding(.top, 4)
                    .luminanceToAlpha()
                    .widgetAccentable()
            }
        }
        .redacted(reason: entry.isDataAvailable ? [] : .placeholder)
    }
}

struct CircularDaySummaryView: View {
    let entry: DaySummaryEntry

    var body: some View {
        ZStack {
            // Don't include widget background, unnecessary
            MiniNutrientPieChart(nutrients: entry.nutrients)
            VStack(spacing: -2) {
                Text(caloriesText(entry))
                    .font(.system(size: 14, design: .rounded))
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.6)
                Text("Cal").font(.system(size: 7))
            }
        }
        .widgetAccentable()
    }
}

struct RectangularDaySummaryView: View {
    let entry: DaySummaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .bottom) {
                Text(entry.nutrients.calories.formatted())
                    .font(.body)
                Spacer()
                Text(entry.totalCost.formatted())
                    .font(.caption)
            }.fontWeight(.semibold)
            Text(Macro.allCases.map { "\($0.name.prefix(1)) \(grams(entry, $0))" }
                    .joined(separator: " · "))
                .font(.caption2)
            MacroBarChart(nutrients: entry.nutrients)
                .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
