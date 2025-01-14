//
//  LogCategoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import SwiftData
import SwiftUI

struct LogCategoryView: View {
    @Query(sort: \LogFoodItemEntry.date) var foodItems: [LogFoodItemEntry]
    @Environment(\.modelContext) var modelContext
    
    @EnvironmentObject
    private var navigationStore: NavigationStore
    
    var body: some View {
        let items = foodItems.filter({ navigationStore.logConfig.contains($0.date) && navigationStore.logConfig.selectedType == $0.type }).filter({ navigationStore.logConfig.selectedCategory == nil || $0.category == navigationStore.logConfig.selectedCategory })
        VStack(spacing: 0) {
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
            }.padding()
            Form {
                Section {
                    ForEach(items, id: \.hashValue, content: itemView)
                } header: {
                    Menu {
                        Button("All Entries") {
                            navigationStore.logConfig.selectedCategory = nil
                        }
                        ForEach(LogbookView.Categories, id: \.hashValue) { category in
                            Button(category) {
                                navigationStore.logConfig.selectedCategory = category
                            }.disabled(category == navigationStore.logConfig.selectedCategory)
                        }
                    } label: {
                        HStack {
                            Text(navigationStore.logConfig.selectedCategory ?? "All Entries")
                                .font(.title2)
                                .bold()
                            Image(systemName: "chevron.down")
                            Spacer()
                        }.clipShape(Rectangle())
                    }.buttonStyle(.plain)
                }.headerProminence(.increased)
                HStack(alignment: .top) {
                    LogbookPieChart(nutrients: items.totalNutrients, price: items.totalPrice)
                        .frame(width: 160, height: 160)
                    macroText(items.totalNutrients)
                }
            }
            Spacer()
        }.navigationTitle("Logbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func itemView(_ entry: LogFoodItemEntry) -> some View {
        Button {
            navigationStore.push(LogViewType.editFoodItem(entry: entry))
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                let brand = entry.item.metaData.brand
                if brand != nil || entry.price != nil {
                    HStack {
                        if let brand {
                            Text(brand)
                                .opacity(0.7)
                        }
                        Spacer()
                        if let price = entry.price {
                            Text(price.toString())
                                .italic()
                        }
                    }.font(.subheadline)
                }
                Text(entry.item.name)
                    .bold()
                HStack {
                    Text("\(entry.nutrients.calories.formatted(.number.precision(.fractionLength(0)))) Cal")
                        .fontWeight(.semibold)
                    Spacer()
                    let amount: String = {
                        switch entry.amountUnit {
                        case .none:
                            return (entry.item.size.servingSizeAmount * entry.amount.value).formatted(maxDigits: 2, includeSpace: true)
                        default:
                            return (entry.item.size.servingAmount * entry.amount.value).formatted(maxDigits: 1)
                        }
                    }()
                    Text(amount)
                }.font(.subheadline)
                HStack {
                    macroSummaryText(entry.nutrients)
                        .fontWeight(.semibold)
                    Spacer()
                }.font(.subheadline)
            }.contentShape(Rectangle())
        }.buttonStyle(.plain)
            .contextMenu {
                if entry.type == .plan {
                    Menu("Actualize") {
                        Button("Copy") {
                            copyToActual(entry)
                        }
                        Button("Move") {
                            moveToActual(entry)
                        }
                    }
                }
                Button {
                    duplicate(entry)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    delete(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(allowsFullSwipe: false) {
                Button {
                    delete(entry)
                } label: {
                    Label("Delete", systemImage: "trash").tint(.red)
                }
                Button {
                    duplicate(entry)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc").tint(.blue)
                }
            }
    }
    
    private func copyToActual(_ entry: LogFoodItemEntry) {
        let copy = LogFoodItemEntry(date: entry.date,
                                    item: entry.item,
                                    amount: entry.amount,
                                    amountUnit: entry.amountUnit,
                                    category: entry.category,
                                    type: .actual,
                                    unitPrice: entry.unitPrice)
        modelContext.insert(copy)
    }
    
    private func moveToActual(_ entry: LogFoodItemEntry) {
        entry.type = .actual
    }
    
    private func duplicate(_ entry: LogFoodItemEntry) {
        let copy = LogFoodItemEntry(date: entry.date,
                                    item: entry.item,
                                    amount: entry.amount,
                                    amountUnit: entry.amountUnit,
                                    category: entry.category,
                                    type: entry.type,
                                    unitPrice: entry.unitPrice)
        modelContext.insert(copy)
        navigationStore.push(LogViewType.editFoodItem(entry: copy))
    }
    
    private func delete(_ entry: LogFoodItemEntry) {
        modelContext.delete(entry)
    }
    
    @ViewBuilder
    private func macroSummaryText(_ nutrients: NutritionDict) -> some View {
        HStack(spacing: 4) {
            Text("\(nutrients[.TotalCarbs]?.formatted() ?? "0g")")
                .foregroundStyle(Colors.carbs)
            Text("·")
            Text("\(nutrients[.TotalFat]?.formatted() ?? "0g")")
                .foregroundStyle(Colors.fat)
            Text("·")
            Text("\(nutrients[.Protein]?.formatted() ?? "0g")")
                .foregroundStyle(Colors.protein)
            Text("·")
            Text("\(nutrients[.Sodium]?.formatted() ?? "0mg")")
        }
    }
    
    @ViewBuilder
    private func macroText(_ nutrients: NutritionDict) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Carbs: \(nutrients[.TotalCarbs]?.formatted() ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.carbs)
            Text("Fat: \(nutrients[.TotalFat]?.formatted() ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.fat)
            Text("Protein: \(nutrients[.Protein]?.formatted() ?? "0g")")
                .font(.title3)
                .foregroundStyle(Colors.protein)
            Text("Sodium: \(nutrients[.Sodium]?.formatted() ?? "0mg")")
        }.bold()
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("", selection: $navigationStore.logConfig.selectedType) {
                Text("Actual").tag(LogType.actual)
                Text("Plan").tag(LogType.plan)
            }.pickerStyle(.segmented)
                .frame(width: 150)
        }
        ToolbarItem(placement: .topBarTrailing) {
            if navigationStore.logConfig.selectedCategory != nil {
                Button {
                    navigationStore.push(LogViewType.addFoodItem())
                } label: {
                    Label("Add", systemImage: "plus")
                }
            } else {
                Menu {
                    ForEach(LogbookView.Categories, id: \.hashValue) { category in
                        Button(category) {
                            navigationStore.push(LogViewType.addFoodItem(category: category))
                        }
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        LogCategoryView()
    }.environmentObject(navigationStore)
}
