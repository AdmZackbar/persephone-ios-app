//
//  AddFoodInstanceView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/8/26.
//

import SwiftData
import SwiftUI

struct AddFoodInstanceView: View {
    @EnvironmentObject var navigationStore: NavigationStore
    @Environment(\.modelContext) private var modelContext
    
    @Query private var foods: [Food]
    
    @State private var date: Date
    @State private var source: String
    @State private var selection: [FoodInstanceItem]
    @State private var editItem: PersistentIdentifier?
    @State private var searchText: String
    
    init() {
        self.date = .now
        self.source = Stores.costco.name
        self.selection = []
        self.editItem = nil
        self.searchText = ""
        self._foods = Query(filter: #Predicate<Food> { food in
            food.metaData.retireDate == nil
        }, sort: \.name)
    }
    
    var body: some View {
        Form {
            Section {
                if !selection.isEmpty {
                    ForEach(selection, id: \.hashValue) { item in
                        Button {
                            editItem = item.food.id
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text(item.food.name)
                                        .bold()
                                    if let brand = item.food.brand {
                                        Text(brand)
                                            .font(.subheadline)
                                            .italic()
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text((item.amount * item.remainder).formatted())
                                    Text(item.cost.formatted())
                                }
                            }.contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    selection.removeAll(where: { $0 == item })
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } else {
                    Text("Select foods to begin")
                        .font(.subheadline)
                        .italic()
                        .opacity(0.5)
                }
            } header: {
                DatePicker("Entries", selection: $date)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.primary)
            }
            Section {
                foodListView()
            } header: {
                HStack {
                    Text("Select")
                    Spacer()
                }.foregroundStyle(.primary)
            }
        }.navigationTitle("Add Entries")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .searchable(text: $searchText)
            .sheet(isPresented: .isPresent($editItem), content: {
                if let index = selection.firstIndex(where: { $0.food.id == editItem }) {
                    SetAmountSheet(item: $selection[index])
                }
                else {
                    Text("Error getting item")
                }
            })
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func foodListView() -> some View {
        var foodList: [Food] {
            if searchText.isEmpty {
                // If not searching for something specific, try to filter by
                // foods with a store entry matching the current store
                let filtered = foods.filter({ $0.storeEntries.contains(where: { $0.store == source }) })
                // But if none exist, just return the whole list instead of nothing
                return filtered.isEmpty ? foods : filtered
            }
            return foods.filter(isFiltered)
        }
        ForEach(foodList.prefix(30)) { food in
            Button {
                var item: FoodInstanceItem {
                    // Try to get relevant store entry for item to prepopulate info
                    var storeEntry: Food.StoreEntry? {
                        food.storeEntries.first(where: { $0.store == source }) ?? food.storeEntries.first
                    }
                    return .init(food: food, date: date, source: source, amount: storeEntry?.amount ?? .init(), cost: storeEntry?.cost ?? .zero, remainder: 1.0)
                }
                selection.append(item)
                editItem = food.id
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(food.name)
                            .bold()
                        if let brand = food.brand {
                            Text(brand)
                                .font(.subheadline)
                                .italic()
                        }
                    }
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }
    
    private func isFiltered(_ food: Food) -> Bool {
        if searchText.isEmpty {
            return true
        }
        if food.name.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        if let brand = food.brand, brand.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        if let category = food.category, category.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        return false
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu {
                ForEach(Stores.allCases) { store in
                    Button(store.name) {
                        source = store.name
                    }.disabled(source == store.name)
                }
                // TODO add alert to add new source
            } label: {
                HStack {
                    Text(source)
                        .font(.title)
                        .fontWeight(.bold)
                    Image(systemName: "chevron.down")
                }
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button {
                navigationStore.pop()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                // Can't use forEach and modify values
                for index in selection.indices {
                    var entry = selection[index]
                    // Make sure date and source are up to date
                    entry.date = date
                    entry.source = source
                    // Save to DB
                    entry.save(modelContext)
                }
                navigationStore.pop()
            } label: {
                Label("Save", systemImage: "checkmark")
            }.disabled(selection.isEmpty || !selection.allSatisfy({ !$0.invalid }))
        }
    }
    
    struct SetAmountSheet: View {
        @Binding var item: FoodInstanceItem
        @State private var remainderType: RemainderType = .amount
        
        var body: some View {
            Form {
                Section {
                    HStack {
                        Text("Amount:")
                        TextField("required", text: $item.amount.str)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Picker(selection: $item.amount.isMass) {
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
                        TextField("required", value: $item.amount.val, formatter: formatter)
                            .keyboardType(.decimalPad)
                    }
                    CurrencyField(value: $item.cost)
                } header: {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            if let brand = item.food.brand {
                                Text(brand)
                                    .font(.subheadline)
                                    .italic()
                            }
                            Text(item.food.name)
                                .bold()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text((item.amount * item.remainder).formatted())
                            Text(item.cost.formatted())
                        }
                    }.foregroundStyle(.primary)
                        .padding(.top, 12)
                } footer: {
                    storeEntriesList()
                }
                remainderView()
            }.listSectionSpacing(.compact)
                .toolbar(.hidden)
                .presentationDetents([.height(460)])
                // Don't use liquid glass as main background
                .presentationBackground(.regularMaterial)
        }
        
        @ViewBuilder
        private func remainderView() -> some View {
            Section {
                if item.amount.amount.value.raw <= 1 {
                    Slider(value: $item.remainder, in: 0...1)
                } else {
                    switch remainderType {
                    case .fraction:
                        Slider(value: $item.remainder, in: 0...1)
                    case .amount:
                        Stepper(value: Binding<Double>(get: {
                            item.amount.amount.value.raw * item.remainder
                        }, set: { newValue in
                            item.remainder = newValue / item.amount.amount.value.raw
                        }), in: 1...item.amount.amount.value.raw) {
                            Text((item.amount.amount * item.remainder).formatted())
                        }
                    case .value:
                        Stepper(value: Binding<Double>(get: {
                            item.amount.val * item.remainder
                        }, set: { newValue in
                            if item.amount.val <= 0 {
                                item.remainder = 0
                            } else {
                                item.remainder = newValue / item.amount.val
                            }
                        }), in: 1...item.amount.val) {
                            Text((item.amount.value * item.remainder).formatted())
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Remaining")
                    Spacer()
                    if item.amount.amount.value.raw > 1 {
                        Picker("", selection: $remainderType) {
                            Text("Slider").tag(RemainderType.fraction)
                            Text("Amount").tag(RemainderType.amount)
                            Text(item.amount.isMass ? "Mass" : "Volume").tag(RemainderType.value)
                        }.pickerStyle(.segmented)
                            .frame(width: 200)
                    }
                }
            }
        }
        
        private func storeEntriesList() -> some View {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(item.food.storeEntries.filter({ $0.isAvailable }), id: \.hashValue) { storeEntry in
                        Button {
                            item.amount = storeEntry.amount
                            item.cost = storeEntry.cost
                        } label: {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(storeEntry.store)
                                        .italic()
                                    Text(storeEntry.cost.formatted())
                                        .font(.subheadline)
                                        .bold()
                                }
                                Text(storeEntry.amount.formatted())
                                    .font(.caption)
                            }
                        }.buttonStyle(.glass)
                    }
                }
            }.scrollIndicators(.hidden)
                .scrollClipDisabled()
                .padding([.leading, .trailing], -14)
        }
        
        private enum RemainderType: String, Identifiable, CaseIterable {
            case fraction, amount, value
            
            var id: String {
                rawValue
            }
            
            var name: String {
                switch self {
                case .fraction:
                    return "Slider"
                case .amount:
                    return "Servings"
                case .value:
                    return "Mass/Volume"
                }
            }
        }
    }
    
    struct FoodInstanceItem: Hashable {
        let food: Food
        var date: Date
        var source: String
        var amount: FoodSize
        var cost: Currency
        var remainder: Double
        
        var invalid: Bool {
            amount.str.isEmpty || amount.val <= 0 || source.isEmpty || remainder <= 0 || remainder > 1
        }
        
        func save(_ modelContext: ModelContext) {
            modelContext.insert(FoodInstance(food: food, acquireDate: date, source: source, cost: cost, total: amount, remainder: remainder))
        }
    }
}

enum Stores: String, Identifiable, CaseIterable {
    case costco, publix, kroger
    
    var id: String {
        rawValue
    }
    var name: String {
        rawValue.capitalized
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        AddFoodInstanceView()
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
