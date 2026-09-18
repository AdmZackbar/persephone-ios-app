//
//  InventoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/8/26.
//

import SwiftData
import SwiftUI

struct StoreDate: Hashable {
    let store: String
    let date: Date
}

extension StoreDate: Comparable {
    static func < (lhs: StoreDate, rhs: StoreDate) -> Bool {
        if (lhs.date != rhs.date) {
            return lhs.date > rhs.date
        }
        return lhs.store < rhs.store
    }
}

struct InventoryView: View {
    @StateObject private var navigationStore = NavigationStore()
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \FoodInstance.acquireDate, order: .reverse)
    private var instances: [FoodInstance]
    
    @State private var viewType: ViewType = .viewItems
    @State private var searchText: String = ""
    @State private var editItem: PersistentIdentifier?
    @State private var showDeleteAll: Bool = false
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            mainView()
                .navigationTitle("Inventory")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: .isPresent($editItem), content: {
                    if let index = instances.firstIndex(where: { $0.id == editItem }) {
                        SaveAmountSheet(item: .init(instance: instances[index]))
                    }
                    else {
                        Text("Error getting item")
                    }
                })
                .alert("Are you sure you want to delete all items in inventory?", isPresented: $showDeleteAll) {
                    Button("Delete All", role: .destructive) {
                        do {
                            try modelContext.delete(model: FoodInstance.self)
                            try modelContext.save()
                        } catch {
                            print("Failed to clear inventory data.")
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("View Type", selection: $viewType) {
                            ForEach(ViewType.allCases, id: \.text) { type in
                                Text(type.text).tag(type)
                            }
                        }.pickerStyle(.segmented)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .destructive) {
                            showDeleteAll = true
                        } label: {
                            Label("Clear Data", systemImage: "trash")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                navigationStore.push(InventoryViewType.addFood)
                            } label: {
                                Label("Add Item", systemImage: "carrot")
                            }
                            Button {
                                modelContext.insert(GroceryList())
                            } label: {
                                Label("Add Grocery List", systemImage: "list.clipboard")
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .handleDestinations(navigationStore)
        }.environmentObject(navigationStore)
    }
    
    @ViewBuilder
    func mainView() -> some View {
        switch viewType {
        case .viewItems:
            currentItemsView()
                .searchable(text: $searchText)
        case .viewGroceryLists:
            GroceryListView()
        }
    }
    
    @ViewBuilder
    func currentItemsView() -> some View {
        Form {
            let byStoreAndDate = Dictionary(grouping: instances.filter(isFiltered)) { instance in
                StoreDate(store: instance.source, date: Calendar.current.startOfDay(for: instance.acquireDate))
            }
            if byStoreAndDate.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView("No items in inventory", systemImage: "list.clipboard")
                } else {
                    ContentUnavailableView("No related items", systemImage: "list.clipboard")
                }
            } else {
                ForEach(byStoreAndDate.keys.sorted(), id: \.hashValue) { key in
                    Section {
                        instanceList(byStoreAndDate[key]!)
                    } header: {
                        HStack {
                            Text(key.store)
                            Spacer()
                            Text(key.date.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                }
            }
        }
    }
    
    private func isFiltered(_ instance: FoodInstance) -> Bool {
        if searchText.isEmpty {
            return true
        }
        return instance.food.name.localizedCaseInsensitiveContains(searchText) || (instance.food.brand?.localizedCaseInsensitiveContains(searchText) ?? false) || instance.source.localizedCaseInsensitiveContains(searchText)
    }
    
    private func instanceList(_ instances: [FoodInstance]) -> some View {
        List(instances, id: \.id) { instance in
            Button {
                editItem = instance.id
            } label: {
                instanceListView(instance)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
                .swipeActions {
                    deleteButton(instance)
                }
                .contextMenu {
                    Button {
                        splitInstance(instance)
                    } label: {
                        Label("Split Item", systemImage: "arrow.trianglehead.branch")
                    }.disabled(instance.total.amount.value.raw <= 1)
                    deleteButton(instance)
                }
        }
    }
    
    private func splitInstance(_ instance: FoodInstance) {
        // TODO only really works for int values
        let originalMax = ceil(instance.total.amount.value.raw)
        let totalNum = ceil(instance.remaining.amount.value.raw)
        let remainder = instance.remainder < 1 ? totalNum - instance.remaining.amount.value.raw : 1
        for i in 1...Int(totalNum) {
            let remaining = i == Int(totalNum) ? remainder : 1.0
            let newInstance = FoodInstance(food: instance.food, acquireDate: instance.acquireDate, source: instance.source, cost: instance.cost / originalMax, total: instance.total / originalMax, remainder: remaining)
            modelContext.insert(newInstance)
        }
        modelContext.delete(instance)
    }
    
    private func deleteButton(_ instance: FoodInstance) -> some View {
        Button(role: .destructive) {
            modelContext.delete(instance)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func instanceListView(_ instance: FoodInstance) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(instance.food.name)
                    .bold()
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        if let brand = instance.food.brand {
                            Text(brand).italic()
                        }
                        Text(instance.acquireDate.formatted())
                            .fontWeight(.light)
                    }.font(.subheadline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(instance.remaining.amount.formatted(maxDigits: 1))
                        Text(instance.remaining.value.formatted())
                    }.font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            Gauge(value: instance.remainder, in: 0...1.0) {
                Text(instance.remainder.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline)
            }.gaugeStyle(.accessoryCircularCapacity)
        }
    }
    
    enum ViewType: CaseIterable {
        case viewItems, viewGroceryLists
        
        var text: String {
            switch self {
            case .viewItems:
                return "Current Items"
            case .viewGroceryLists:
                return "Grocery Lists"
            }
        }
    }
    
    struct SaveAmountSheet: View {
        @Environment(\.dismiss) var dismiss
        @Environment(\.modelContext) var modelContext
        
        @State var item: FoodInstanceItem
        @State private var remainderType: RemainderType = .amount
        
        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        DatePicker("Date:", selection: $item.date)
                        HStack {
                            Text("Amount:")
                            TextField("required", text: $item.total.str)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Picker(selection: $item.total.isMass) {
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
                            TextField("required", value: $item.total.val, formatter: formatter)
                                .keyboardType(.decimalPad)
                        }
                        CurrencyField(value: $item.cost)
                    } header: {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading) {
                                if let brand = item.instance.food.brand {
                                    Text(brand)
                                        .font(.subheadline)
                                        .italic()
                                }
                                Text(item.instance.food.name)
                                    .bold()
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(item.remaining.value.formatted())
                                Text(item.remaining.amount.formatted(maxDigits: 1))
                            }
                        }.foregroundStyle(.primary)
                            .padding(.top, 12)
                    } footer: {
                        storeEntriesList()
                    }
                    remainderView()
                }.navigationTitle("Edit Instance")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar(content: toolbarContent)
                    .listSectionSpacing(.compact)
            }.presentationDetents([.height(580)])
                // Don't use liquid glass as main background
                .presentationBackground(.regularMaterial)
        }
        
        @ViewBuilder
        private func remainderView() -> some View {
            let value: Binding<Double> = {
                switch remainderType {
                case .amount:
                    return Binding<Double>(get: {
                        item.total.amount.value.raw * item.remainder
                    }, set: { newValue in
                        item.remainder = newValue / item.total.amount.value.raw
                    })
                case .value:
                    return Binding<Double>(get: {
                        item.total.val * item.remainder
                    }, set: { newValue in
                        if item.total.val <= 0 {
                            item.remainder = 0
                        } else {
                            item.remainder = newValue / item.total.val
                        }
                    })
                }
            }()
            Section {
                if item.total.amount.value.raw <= 1 {
                    VStack {
                        HStack {
                            TextField("Amount", value: value, format: .number.precision(.fractionLength(remainderType == .amount ? 3 : 0)))
                            switch remainderType {
                            case .amount:
                                if let unit = item.total.amount.unitStr {
                                    Text(unit)
                                }
                            case .value:
                                if let unit = item.total.value.unitStr {
                                    Text(unit)
                                }
                            }
                        }
                        Slider(value: $item.remainder, in: 0...1, step: 0.01)
                    }
                } else {
                    switch remainderType {
                    case .amount:
                        Stepper(value: value, in: 1...item.total.amount.value.raw) {
                            Text((item.total.amount * item.remainder).formatted())
                        }
                    case .value:
                        Stepper(value: value, in: 1...item.total.val) {
                            Text((item.total.value * item.remainder).formatted())
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Remaining")
                    Spacer()
                    Picker("", selection: $remainderType) {
                        Text("Amount").tag(RemainderType.amount)
                        Text(item.total.isMass ? "Mass" : "Volume").tag(RemainderType.value)
                    }.pickerStyle(.segmented)
                        .frame(width: 200)
                }
            }
        }
        
        private func storeEntriesList() -> some View {
            ScrollView(.horizontal) {
                HStack {
                    Menu {
                        Button("Override All '\(item.source)'") {
                            item.instance.food.storeEntries.removeAll(where: { $0.store == item.source })
                            item.instance.food.storeEntries.append(.init(store: item.source, cost: item.cost, amount: item.total))
                        }
                        Button("Add New Entry") {
                            item.instance.food.storeEntries.append(.init(store: item.source, cost: item.cost, amount: item.total))
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                            .bold()
                            .frame(width: 36, height: 36)
                            .labelStyle(.iconOnly)
                    }.buttonStyle(.glass)
                        .disabled(item.source.isEmpty || item.cost.cents < 0 || item.total.str.isEmpty || item.total.val <= 0)
                    ForEach(item.instance.food.storeEntries.filter({ $0.store == item.source }), id: \.hashValue) { storeEntry in
                        Button {
                            item.total = storeEntry.amount
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
        
        @ToolbarContentBuilder
        private func toolbarContent() -> some ToolbarContent {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(Stores.allCases) { store in
                        Button(store.name) {
                            item.source = store.name
                        }.disabled(item.source == store.name)
                    }
                    // TODO add alert to add new source
                } label: {
                    HStack {
                        Text(item.source)
                            .font(.title)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.down")
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    item.save(modelContext)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }.disabled(item.invalid)
            }
        }
        
        private enum RemainderType: String, Identifiable, CaseIterable {
            case amount, value
            
            var id: String {
                rawValue
            }
            
            var name: String {
                switch self {
                case .amount:
                    return "Servings"
                case .value:
                    return "Mass/Volume"
                }
            }
        }
    }
    
    struct FoodInstanceItem: Hashable {
        let instance: FoodInstance
        var date: Date
        var source: String
        var total: FoodSize
        var cost: Currency
        var remainder: Double
        
        var remaining: FoodSize {
            total * remainder
        }
        var invalid: Bool {
            source.isEmpty || remainder > 1
        }
        
        init(instance: FoodInstance) {
            self.instance = instance
            self.date = instance.acquireDate
            self.source = instance.source
            self.total = instance.total
            self.cost = instance.cost
            self.remainder = instance.remainder
        }
        
        func save(_ modelContext: ModelContext) {
            if remainder <= 0 {
                modelContext.delete(instance)
            } else {
                instance.acquireDate = date
                instance.source = source
                instance.total = total
                instance.cost = cost
                instance.remainder = remainder
            }
        }
    }
}

enum InventoryViewType: Hashable {
    case addFood
}

#Preview(traits: .sampleData) {
    InventoryView()
}
