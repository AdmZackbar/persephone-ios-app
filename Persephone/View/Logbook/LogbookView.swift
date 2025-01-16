//
//  LogbookView.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/15/24.
//

import SwiftData
import SwiftUI

struct LogbookView: View {
    @Query(sort: \LogFoodItemEntry.date) var entries: [LogFoodItemEntry]
    @Environment(\.modelContext) var modelContext
    
    static let Categories: [String] = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snacks"
    ]
    
    @StateObject private var navigationStore = NavigationStore()
    
    var body: some View {
        let entries = entries.filter({ navigationStore.logConfig.contains($0.date) })
        let entryMap: [String : [LogFoodItemEntry]] = {
            var map: [String : [LogFoodItemEntry]] = [:]
            entries.forEach({ entry in
                if Self.Categories.contains(where: { $0 == entry.category }) {
                    map[entry.category, default: []].append(entry)
                } else {
                    map["Other", default: []].append(entry)
                }
            })
            return map
        }()
        NavigationStack(path: $navigationStore.path) {
            VStack(spacing: 0) {
                dateHeader()
                    .padding()
                Form {
                    Section("Summary") {
                        nutrientView(nutrition: entries.totalNutrients, price: entries.totalPrice)
                    }
                    Section("Meals") {
                        ForEach(Self.Categories, id: \.hashValue) { category in
                            categoryButton(category: category, entries: entryMap[category, default: []])
                        }
                        Button("View All Entries") {
                            navigationStore.logConfig.selectedCategory = nil
                            navigationStore.push(ViewType.entries)
                        }
                    }
                }.headerProminence(.increased)
            }.navigationTitle("Logbook")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(uiColor: UIColor.secondarySystemBackground))
                .handleDestinations(navigationStore)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(Self.Categories, id: \.hashValue) { category in
                                Button(category) {
                                    navigationStore.push(ViewType.addFoodItem(category: category))
                                }
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
        }.environmentObject(navigationStore)
    }
    
    @ViewBuilder
    private func dateHeader() -> some View {
        HStack {
            Button {
                navigationStore.logConfig.prev()
            } label: {
                Label("Prev", systemImage: "chevron.left").labelStyle(.iconOnly)
            }
            Spacer()
            Text(navigationStore.logConfig.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
                .bold()
            Spacer()
            Button {
                navigationStore.logConfig.next()
            } label: {
                Label("Next", systemImage: "chevron.right").labelStyle(.iconOnly)
            }
        }
    }
    
    @ViewBuilder
    private func categoryButton(category: String, entries: [LogFoodItemEntry]) -> some View {
        Button {
            navigationStore.logConfig.selectedCategory = category
            navigationStore.push(ViewType.entries)
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.capitalized)
                        .font(.title3)
                        .bold()
                    Text(entries.totalPrice.toString())
                        .italic()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(entries.totalNutrients.calories.formatted(.number.precision(.fractionLength(0)))) Cal")
                        .font(.title3)
                        .bold()
                    HStack(spacing: 4) {
                        Text("\(entries.totalNutrients[.TotalCarbs]?.formatted() ?? "0g")")
                            .foregroundStyle(Colors.carbs)
                        Text("·")
                        Text("\(entries.totalNutrients[.TotalFat]?.formatted() ?? "0g")")
                            .foregroundStyle(Colors.fat)
                        Text("·")
                        Text("\(entries.totalNutrients[.Protein]?.formatted() ?? "0g")")
                            .foregroundStyle(Colors.protein)
                    }.italic()
                        .bold()
                }
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    for entry in entries {
                        modelContext.delete(entry)
                    }
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
            }
    }
    
    @ViewBuilder
    private func nutrientView(nutrition: NutritionDict, price: Price) -> some View {
        HStack(alignment: .top) {
            LogbookPieChart(nutrients: nutrition, price: price)
                .frame(width: 180, height: 170)
            VStack(alignment: .leading, spacing: 4) {
                Text("Carbs: \(nutrition[.TotalCarbs]?.formatted() ?? "0g")")
                    .font(.title3)
                    .foregroundStyle(Colors.carbs)
                Text("Fat: \(nutrition[.TotalFat]?.formatted() ?? "0g")")
                    .font(.title3)
                    .foregroundStyle(Colors.fat)
                Text("Protein: \(nutrition[.Protein]?.formatted() ?? "0g")")
                    .font(.title3)
                    .foregroundStyle(Colors.protein)
                Text("Sodium: \(nutrition[.Sodium]?.formatted() ?? "0mg")")
            }.bold()
        }
    }
    
    enum ViewType: Hashable {
        case entries
        case addFoodItem(category: String? = nil)
        case editFoodItem(entry: LogFoodItemEntry)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogbookView()
}
