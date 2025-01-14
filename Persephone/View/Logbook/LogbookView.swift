//
//  LogbookView.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/15/24.
//

import SwiftData
import SwiftUI

struct LogbookView: View {
    @Query(sort: \LogFoodItemEntry.date) var foodItems: [LogFoodItemEntry]
    @Environment(\.modelContext) var modelContext
    
    static let Categories: [String] = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snacks"
    ]
    
    @StateObject private var navigationStore = NavigationStore()
    
    var body: some View {
        let items = foodItems.filter({ navigationStore.logConfig.contains($0.date) && $0.type == navigationStore.logConfig.selectedType })
        let itemMap: [String : [LogFoodItemEntry]] = {
            var map: [String : [LogFoodItemEntry]] = [:]
            items.forEach({ item in
                if Self.Categories.contains(where: { $0 == item.category }) {
                    map[item.category, default: []].append(item)
                } else {
                    map["Other", default: []].append(item)
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
                        nutrientView(nutrition: items.totalNutrients, price: items.totalPrice)
                    }
                    Section("Meals") {
                        ForEach(Self.Categories, id: \.hashValue) { category in
                            categoryButton(category: category, entries: itemMap[category, default: []])
                        }
                        Button("View All Entries") {
                            navigationStore.logConfig.selectedCategory = nil
                            navigationStore.push(LogViewType.entries)
                        }
                    }
                }.headerProminence(.increased)
            }.navigationTitle("Logbook")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(uiColor: UIColor.secondarySystemBackground))
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("", selection: $navigationStore.logConfig.selectedType) {
                            Text("Actual").tag(LogType.actual)
                            Text("Plan").tag(LogType.plan)
                        }.pickerStyle(.segmented)
                            .frame(width: 150)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(Self.Categories, id: \.hashValue) { category in
                                Button(category) {
                                    navigationStore.push(LogViewType.addFoodItem(category: category))
                                }
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(for: LogViewType.self, destination: handleLogViewType)
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
            navigationStore.push(LogViewType.entries)
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
                if navigationStore.logConfig.selectedType == .plan {
                    Menu("Actualize") {
                        Button("Copy") {
                            for entry in entries {
                                let copy = LogFoodItemEntry(date: entry.date,
                                                            item: entry.item,
                                                            amount: entry.amount,
                                                            amountUnit: entry.amountUnit,
                                                            category: entry.category,
                                                            type: .actual,
                                                            unitPrice: entry.unitPrice)
                                modelContext.insert(copy)
                            }
                        }
                        Button("Move") {
                            for entry in entries {
                                entry.type = .actual
                            }
                        }
                    }
                }
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
    
    @ViewBuilder
    private func handleLogViewType(_ type: LogViewType) -> some View {
        switch type {
        case .entries:
            LogCategoryView()
        case .addFoodItem(let category):
            LogFoodItemEntryEditView(item: .init(date: navigationStore.logConfig.date, category: category ?? navigationStore.logConfig.selectedCategory ?? "Other", type: navigationStore.logConfig.selectedType))
        case .editFoodItem(let entry):
            LogFoodItemEntryEditView(item: .init(entry: entry))
        }
    }
}

enum LogViewType: Hashable {
    case entries
    case addFoodItem(category: String? = nil)
    case editFoodItem(entry: LogFoodItemEntry)
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogbookView()
}
