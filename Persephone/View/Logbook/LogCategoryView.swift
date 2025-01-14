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
    
    @State private var sheetType: SheetType? = nil
    
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
            .background(Color(uiColor: UIColor.secondarySystemBackground))
            .toolbar(content: toolbarContent)
            .sheet(item: $sheetType) { type in
                switch type {
                case .EditFoodItem(let entry):
                    EditAmountSheet(item: .init(entry: entry))
                }
            }
    }
    
    @ViewBuilder
    private func itemView(_ entry: LogFoodItemEntry) -> some View {
        Button {
            sheetType = .EditFoodItem(entry: entry)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                if let brand = entry.item.metaData.brand {
                    Text(brand)
                        .font(.subheadline)
                        .opacity(0.7)
                }
                Text(entry.item.name)
                    .bold()
                HStack {
                    Text("\(entry.nutrients.calories.formatted(.number.precision(.fractionLength(0)))) Cal")
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
                    .fontWeight(.semibold)
                HStack {
                    macroSummaryText(entry.nutrients)
                        .fontWeight(.semibold)
                    Spacer()
                    if let price = entry.price {
                        Text(price.toString())
                            .italic()
                    }
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
                    edit(entry)
                } label: {
                    Label("Edit", systemImage: "pencil")
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
            } preview: {
                LogFoodItemEntryPreview(entry: entry)
                    .padding()
                    .frame(width: 300)
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
                Button {
                    edit(entry)
                } label: {
                    Label("Edit", systemImage: "pencil").tint(.gray)
                }
            }
    }
    
    private func edit(_ entry: LogFoodItemEntry) {
        navigationStore.push(LogViewType.editFoodItem(entry: entry))
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

private enum SheetType: Identifiable {
    var id: String {
        switch self {
        case .EditFoodItem(_):
            "Edit Food Item"
        }
    }
    
    case EditFoodItem(entry: LogFoodItemEntry)
}

struct EditAmountSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State var item: LogFoodItemEntryEditView.Item
    
    var body: some View {
        NavigationStack {
            Form {
                let foodItem = item.foodItem!
                Picker(selection: $item.amountUnit) {
                    Text(foodItem.size.servingSizeAmount.unit.abbreviation).tag(nil as Unit?)
                    if foodItem.size.totalAmount.unit.isWeight {
                        Text(Unit.Gram.abbreviation).tag(Unit.Gram)
                    }
                    if foodItem.size.totalAmount.unit.isVolume {
                        Text(Unit.Milliliter.abbreviation).tag(Unit.Milliliter)
                    }
                } label: {
                    TextField("Amount", text: Binding(get: {
                        if item.amountUnit == nil {
                            (item.amount * foodItem.size.servingSizeAmount.value.value).toString()
                        } else {
                            (item.amount * foodItem.size.servingAmount.value.value).toString()
                        }
                    }, set: { str in
                        if let value = Quantity.Magnitude.parseString(str) {
                            if item.amountUnit == nil {
                                item.amount = value / foodItem.size.servingSizeAmount.value.value
                            } else {
                                item.amount = value / foodItem.size.servingAmount.value.value
                            }
                        }
                    })).keyboardType(.decimalPad)
                        .font(.title)
                        .bold()
                }
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(foodItem.name)
                                .font(.headline)
                            if let brand = foodItem.metaData.brand {
                                Text(brand)
                                    .font(.subheadline)
                                    .italic()
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\((foodItem.size.servingSizeAmount.value * item.amount.value).toString()) \(foodItem.size.servingSizeAmount.unit.abbreviation)")
                                .bold()
                            Text("\((foodItem.size.servingAmount.value * item.amount.value).toString())\(foodItem.size.servingAmount.unit.abbreviation)")
                                .font(.subheadline).bold()
                        }
                    }
                    NutrientPieChart(nutrients: foodItem.ingredients.nutrients * item.amount.value)
                        .frame(width: 160, height: 120)
                }
                Toggle(isOn: $item.hasPrice) {
                    costEntryView(foodItem)
                }
            }.navigationTitle("Edit Amount")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            item.save(modelContext)
                            dismiss()
                        }
                    }
                }
        }.presentationDetents([.medium])
    }
    
    @ViewBuilder
    private func costEntryView(_ foodItem: FoodItem) -> some View {
        HStack {
            Text("Cost (\(foodItem.size.totalAmount.value.toString(maxDigits: 1))\(foodItem.size.totalAmount.unit.abbreviation)):")
            if item.hasPrice {
                CurrencyField(value: Binding(get: {
                    item.unitPrice.toCents()
                }, set: { value in
                    item.unitPrice = .Cents(value)
                }))
                if !foodItem.storeEntries.isEmpty {
                    Menu {
                        ForEach(foodItem.storeEntries, id: \.hashValue) { storeEntry in
                            Button("\(storeEntry.storeName)\(storeEntry.sale ? " (Sale)" : ""): \(storeEntry.costType.toString())") {
                                item.unitPrice = storeEntry.costPerUnit(size: foodItem.size)
                            }
                        }
                    } label: {
                        Label("Set", systemImage: "chevron.down").labelStyle(.iconOnly)
                    }
                }
            } else {
                Text("No Price Data")
            }
        }
    }
}

struct LogFoodItemEntryPreview: View {
    let entry: LogFoodItemEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(entry.item.name)
                        .font(.headline)
                    if let brand = entry.item.metaData.brand {
                        Text(brand)
                            .font(.subheadline)
                            .italic()
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\((entry.item.size.servingSizeAmount.value * entry.amount.value).toString()) \(entry.item.size.servingSizeAmount.unit.abbreviation)")
                        .bold()
                    Text("\((entry.item.size.servingAmount.value * entry.amount.value).toString())\(entry.item.size.servingAmount.unit.abbreviation)")
                        .font(.subheadline).bold()
                }
            }
            NutrientPieChart(nutrients: entry.item.ingredients.nutrients * entry.amount.value)
                .frame(width: 160, height: 120)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        LogCategoryView()
    }.environmentObject(navigationStore)
}
