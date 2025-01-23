//
//  FoodEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/19/25.
//

import SwiftData
import SwiftUI

struct FoodEditView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    @State private var item: FoodItem
    @State private var sheetType: FoodSheetType?
    
    init(item: FoodItem = .init()) {
        self.item = item
    }
    
    var body: some View {
        Form {
            mainSection()
            servingSizeSection()
            storeEntrySection()
                .disabled(item.servingSize.str.isEmpty || item.servingSize.val <= 0)
            ingredientSection()
        }.navigationTitle(item.isEdit ? "Edit Food" : "Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar(content: toolbarContent)
            .sheet(item: $sheetType) { type in
                switch type {
                case .nutrients:
                    NutrientsEditSheet(nutrients: $item.ingredients.nutrients)
                case .addStoreEntry:
                    StoreEntryEditSheet(foodItem: $item)
                case .editStoreEntry(let entry):
                    StoreEntryEditSheet(foodItem: $item, item: .init(entry: entry))
                }
            }
    }
    
    @ViewBuilder
    private func mainSection() -> some View {
        Section {
            HStack {
                Text("Name:")
                TextField("required", text: $item.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            HStack {
                Text("Brand:")
                TextField("optional", text: $item.metaData.brand)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            HStack {
                Text("Category:")
                TextField("optional", text: $item.metaData.category)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            RatingTierEditor(label: "Rating:", rating: $item.rating)
            OptionalDatePicker(text: "Retired:", selection: $item.metaData.retireDate)
            TextField("Notes", text: $item.metaData.notes, axis: .vertical)
                .lineLimit(3...12)
                .textInputAutocapitalization(.sentences)
        } header: {
            HStack {
                Text(item.metaData.timestamp.formatted())
                Spacer()
                if let barcode = item.metaData.barcode {
                    Text(barcode)
                }
            }
        }
    }
    
    @ViewBuilder
    private func servingSizeSection() -> some View {
        Section("Serving Size") {
            TextField("required", text: $item.servingSize.str)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Picker(selection: $item.servingSize.isMass) {
                Text("g").tag(true)
                Text("mL").tag(false)
            } label: {
                let formatter = {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 3
                    formatter.zeroSymbol = ""
                    formatter.groupingSeparator = ""
                    return formatter
                }()
                TextField("required", value: $item.servingSize.val, formatter: formatter)
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    @ViewBuilder
    private func ingredientSection() -> some View {
        Section {
            NutrientsView(nutrients: item.ingredients.nutrients)
                .contentShape(Rectangle())
                .onTapGesture {
                    sheetType = .nutrients
                }
        }
        Section("Ingredients") {
            TextField("optional", text: $item.ingredients.all, axis: .vertical)
                .lineLimit(3...12)
                .textInputAutocapitalization(.words)
            HStack(alignment: .top) {
                Text("Allergens:")
                TextField("None", text: $item.ingredients.allergens, axis: .vertical)
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.words)
            }.bold()
        }
    }
    
    @ViewBuilder
    private func storeEntrySection() -> some View {
        if item.storeEntries.isEmpty {
            Section("Store Entries") {
                Button {
                    sheetType = .addStoreEntry
                } label: {
                    Label("Add Store Entry", systemImage: "plus")
                }
            }
        } else {
            Section {
                ForEach($item.storeEntries, id: \.hashValue) { storeEntry in
                    Button {
                        sheetType = .editStoreEntry(entry: storeEntry)
                    } label: {
                        storeEntryView(storeEntry.wrappedValue)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }.onDelete { indices in
                    withAnimation {
                        for index in indices {
                            item.storeEntries.remove(at: index)
                        }
                    }
                }
            } header: {
                Button {
                    sheetType = .addStoreEntry
                } label: {
                    HStack {
                        Text("Store Entries")
                        Image(systemName: "plus")
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func storeEntryView(_ entry: Food.StoreEntry) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.store)
                    .font(.headline)
                Text(entry.cost.formatted())
                    .font(.subheadline)
                Text(entry.amount.formatted())
                    .font(.subheadline)
                HStack(spacing: 4) {
                    if !entry.isAvailable {
                        Text("Retired")
                    }
                    if entry.isSale {
                        Text("Sale")
                    }
                }.font(.caption)
            }
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(item.isEdit ? "Save" : "Add") {
                if let food = item.save() {
                    modelContext.insert(food)
                    navigationStore.replace(FoodViewType.viewFood(food))
                } else {
                    navigationStore.pop()
                }
            }.disabled(item.isInvalid)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(item.isEdit ? "Cancel" : "Back") {
                navigationStore.pop()
            }
        }
    }
}

enum FoodSheetType: Identifiable {
    var id: String {
        switch self {
        case .nutrients:
            "Nutrients"
        case .addStoreEntry:
            "Add Store Entry"
        case .editStoreEntry(let entry):
            "Edit \(entry.store)"
        }
    }
    
    case nutrients
    case addStoreEntry
    case editStoreEntry(entry: Binding<Food.StoreEntry>)
}

struct RatingTierEditor: View {
    let label: String
    
    @Binding private var rating: RatingTier?
    
    init(label: String, rating: Binding<RatingTier?>) {
        self.label = label
        self._rating = rating
    }
    
    var body: some View {
        Picker(label, selection: $rating) {
            Text("N/A").tag(nil as RatingTier?)
            ForEach(RatingTier.allCases, id: \.hashValue) { tier in
                Text(tier.rawValue).tag(tier)
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        FoodEditView()
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
