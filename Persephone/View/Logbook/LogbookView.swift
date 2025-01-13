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
    
    static let Categories: [String] = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snacks",
        "Other"
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
            VStack(spacing: 24) {
                dateHeader()
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Self.Categories, id: \.hashValue) { category in
                            categoryButton(category: category, items: itemMap[category] ?? [])
                        }
                    }
                    Spacer()
                    LogbookPieChart(nutrients: items.totalNutrients, price: items.totalPrice)
                        .frame(width: 200, height: 200)
                }
                Spacer()
            }.navigationTitle("Logbook")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
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
    private func categoryButton(category: String, items: [LogFoodItemEntry]) -> some View {
        Button {
            navigationStore.logConfig.selectedCategory = category
            navigationStore.push(LogViewType.entries)
        } label: {
            VStack(alignment: .leading) {
                Text(category.uppercased())
                    .fontWeight(.light)
                Text("\(items.totalNutrients.calories.formatted()) Cal")
                    .font(.title2)
                    .bold()
                Text(items.totalPrice.toString())
                    .font(.title3)
            }.clipShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func handleLogViewType(_ type: LogViewType) -> some View {
        switch type {
        case .entries:
            LogCategoryView()
        case .addFoodItem:
            LogFoodItemEntryEditView(category: navigationStore.logConfig.selectedCategory ?? "Other", type: navigationStore.logConfig.selectedType)
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
