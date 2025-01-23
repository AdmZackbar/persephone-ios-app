//
//  LogbookView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LogbookView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \FoodLogEntry.date) private var foodEntries: [FoodLogEntry]
    @Query(sort: \RecipeLogEntry.date) private var recipeEntries: [RecipeLogEntry]
    @Query(filter: #Predicate { $0.metaData.retireDate == nil },
           sort: \Food.name) private var foods: [Food]
    
    static let Meals: [String] = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snacks"
    ]
    
    @StateObject private var navigationStore = NavigationStore()
    
    @State private var importing = false
    
    var body: some View {
        let entries: [LogEntry] = foodEntries.filter({ navigationStore.logConfig.contains($0.date) })
            .map({ .food($0) }) +
        recipeEntries.filter({ navigationStore.logConfig.contains($0.date) })
            .map({ .recipe($0) })
        let entryMap: [String : [LogEntry]] = {
            var map: [String : [LogEntry]] = [:]
            entries.forEach({ entry in
                if Self.Meals.contains(where: { $0 == entry.meal }) {
                    map[entry.meal, default: []].append(entry)
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
                        nutrientView(nutrients: entries.nutrients, price: entries.cost ?? .zero)
                    }
                    Section("Meals") {
                        ForEach(Self.Meals, id: \.hashValue) { meal in
                            mealButton(meal: meal, entries: entryMap[meal, default: []])
                        }
                        Button("View All Entries") {
                            navigationStore.logConfig.selectedMeal = nil
                            navigationStore.push(LogViewType.entries)
                        }
                    }
                }.headerProminence(.increased)
            }.navigationTitle("Logbook")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(uiColor: UIColor.secondarySystemBackground))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(Self.Meals, id: \.hashValue) { meal in
                                Button(meal) {
                                    navigationStore.push(LogViewType.add(meal: meal))
                                }
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }.handleDestinations(navigationStore)
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
    private func mealButton(meal: String, entries: [LogEntry]) -> some View {
        Button {
            navigationStore.logConfig.selectedMeal = meal
            navigationStore.push(LogViewType.entries)
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.capitalized)
                        .font(.title3)
                        .bold()
                    Text((entries.cost ?? .zero).formatted())
                        .italic()
                }
                Spacer()
                horizontalMacroView(entries.nutrients)
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    for entry in entries {
                        switch entry {
                        case .food(let food):
                            modelContext.delete(food)
                        case .recipe(let recipe):
                            modelContext.delete(recipe)
                        }
                    }
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
            }
    }
    
    @ViewBuilder
    private func nutrientView(nutrients: Nutrients, price: Currency) -> some View {
        HStack(alignment: .top) {
            LogbookPieChart(nutrients: nutrients, price: price)
                .frame(width: 180, height: 170)
            verticalMacroView(nutrients)
        }
    }
    
    @ViewBuilder
    private func horizontalMacroView(_ nutrients: Nutrients) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(nutrients.calories.formatted(maxDigits: 0, includeSpace: true))
                .font(.title3)
                .bold()
            HStack(spacing: 4) {
                Text("\(nutrients.get(.TotalCarbs)?.formatted(maxDigits: 0) ?? "0g")")
                    .foregroundStyle(Colors.carbs)
                Text("·")
                Text("\(nutrients.get(.TotalFat)?.formatted(maxDigits: 0) ?? "0g")")
                    .foregroundStyle(Colors.fat)
                Text("·")
                Text("\(nutrients.get(.Protein)?.formatted(maxDigits: 0) ?? "0g")")
                    .foregroundStyle(Colors.protein)
                Text("·")
                Text("\(nutrients.get(.Sodium)?.formatted(maxDigits: 0) ?? "0mg")")
            }.italic()
                .bold()
        }
    }
    
    @ViewBuilder
    private func verticalMacroView(_ nutrients: Nutrients) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Carbs: \(nutrients.get(.TotalCarbs)?.formatted(maxDigits: 1) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.carbs)
            Text("Fat: \(nutrients.get(.TotalFat)?.formatted(maxDigits: 1) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.fat)
            Text("Protein: \(nutrients.get(.Protein)?.formatted(maxDigits: 1) ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.protein)
            Text("Sodium: \(nutrients.get(.Sodium)?.formatted(maxDigits: 0) ?? "0mg")")
        }.bold()
    }
}

enum LogViewType: Hashable {
    case entries
    case add(meal: String? = nil)
    case edit(_ entry: LogEntry)
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogbookView()
}
