//
//  LogbookView.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/15/24.
//

import SwiftData
import SwiftUI

struct LogbookView: View {
    @Query(sort: \LogbookItem.date) var logItems: [LogbookItem]
    
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack {
                    Button {
                        date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                    } label: {
                        Label("Prev", systemImage: "chevron.left").labelStyle(.iconOnly)
                    }
                    Spacer()
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .bold()
                    Spacer()
                    Button {
                        date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                    } label: {
                        Label("Next", systemImage: "chevron.right").labelStyle(.iconOnly)
                    }
                }
                LogbookItemView(logItem: getOrCreateLogItem())
                Spacer()
            }.navigationTitle("Logbook")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
        }
    }
    
    private func getOrCreateLogItem() -> LogbookItem {
        logItems.first(where: { $0.date.formatted(date: .abbreviated, time: .omitted) == date.formatted(date: .abbreviated, time: .omitted) }) ?? LogbookItem(date: date)
    }
}

struct LogbookItemView: View {
    let logItem: LogbookItem
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(spacing: 16) {
                    createMealInfo(.Breakfast)
                    createMealInfo(.Lunch)
                    createMealInfo(.Dinner)
                }.frame(width: 100)
                Spacer()
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text(logItem.nutrients[.Energy]?.value.toString(maxDigits: 0) ?? "0")
                            .font(.title)
                            .bold()
                        Text("Calories")
                    }
                    VStack(spacing: 4) {
                        Text(logItem.targetNutrients[.Energy]?.value.toString(maxDigits: 0) ?? "0")
                            .font(.title3)
                            .bold()
                        Text("Target")
                            .font(.subheadline)
                            .italic()
                    }
                    let diff = (logItem.targetNutrients[.Energy]?.value ?? .Raw(0)) - (logItem.nutrients[.Energy]?.value ?? .Raw(0))
                    VStack(spacing: 4) {
                        Text(diff.abs().toString(maxDigits: 0))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(computeDiffColor(diff.value))
                        Text(computeDiffStr(diff.value))
                            .font(.subheadline)
                            .italic()
                    }
                }
                Spacer()
                VStack(spacing: 16) {
                    createMealInfo(.Snacks)
                    createMealInfo(.Dessert)
                }.frame(width: 100)
            }
            MacroChartView(nutrients: logItem.nutrients)
                .frame(width: 160, height: 120)
            Spacer()
        }
    }
    
    private func computeDiffColor(_ diff: Double) -> Color {
        if abs(diff) < 0.5 {
            Color.primary
        } else if diff > 0 {
            Color.green
        } else {
            Color.red
        }
    }
    
    private func computeDiffStr(_ diff: Double) -> String {
        if abs(diff) < 0.5 {
            "On Target"
        } else if diff > 0 {
            "Left"
        } else {
            "Over"
        }
    }
    
    private func createMealInfo(_ mealType: LogbookItem.MealType) -> some View {
        VStack {
            Text(logItem.computeNutrients(mealType: mealType)[.Energy]?.value.toString(maxDigits: 0) ?? "0")
                .font(.title2)
                .bold()
            Text(mealType.rawValue)
                .font(.subheadline)
                .italic()
        }
    }
}

#Preview {
    let container = createTestModelContainer()
     createTestLogItem(container.mainContext)
    return LogbookView().modelContainer(container)
}
