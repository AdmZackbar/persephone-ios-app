//
//  InventoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/8/26.
//

import SwiftData
import SwiftUI

struct InventoryView: View {
    @StateObject private var navigationStore = NavigationStore()
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \FoodInstance.acquireDate, order: .reverse)
    private var instances: [FoodInstance]
    
    @State private var editItem: PersistentIdentifier?
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            Form {
                ForEach(instances, id: \.id) { instance in
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
                            deleteButton(instance)
                        }
                }
            }.navigationTitle("Inventory")
                .sheet(isPresented: .isPresent($editItem), content: {
                    if let index = instances.firstIndex(where: { $0.id == editItem }) {
                        SaveAmountSheet(item: .init(instance: instances[index]))
                    }
                    else {
                        Text("Error getting item")
                    }
                })
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            navigationStore.push(InventoryViewType.addFood)
                        } label: {
                            Label("Add Food", systemImage: "plus")
                        }
                    }
                }
                .handleDestinations(navigationStore)
        }.environmentObject(navigationStore)
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
    
    struct SaveAmountSheet: View {
        @Environment(\.dismiss) var dismiss
        @Environment(\.modelContext) var modelContext
        
        @State var item: FoodInstanceItem
        @State private var remainderType: RemainderType = .amount
        
        var body: some View {
            NavigationStack {
                Form {
                    Section {
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
                                Text((item.total * item.remainder).formatted())
                                Text(item.cost.formatted())
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
            }.presentationDetents([.height(480)])
                // Don't use liquid glass as main background
                .presentationBackground(.regularMaterial)
        }
        
        @ViewBuilder
        private func remainderView() -> some View {
            Section {
                if item.total.amount.value.raw <= 1 {
                    Slider(value: $item.remainder, in: 0...1, step: 0.01)
                } else {
                    switch remainderType {
                    case .amount:
                        Stepper(value: Binding<Double>(get: {
                            item.total.amount.value.raw * item.remainder
                        }, set: { newValue in
                            item.remainder = newValue / item.total.amount.value.raw
                        }), in: 1...item.total.amount.value.raw) {
                            Text((item.total.amount * item.remainder).formatted())
                        }
                    case .value:
                        Stepper(value: Binding<Double>(get: {
                            item.total.val * item.remainder
                        }, set: { newValue in
                            if item.total.val <= 0 {
                                item.remainder = 0
                            } else {
                                item.remainder = newValue / item.total.val
                            }
                        }), in: 1...item.total.val) {
                            Text((item.total.value * item.remainder).formatted())
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Remaining")
                    Spacer()
                    if item.total.amount.value.raw > 1 {
                        Picker("", selection: $remainderType) {
                            Text("Amount").tag(RemainderType.amount)
                            Text(item.total.isMass ? "Mass" : "Volume").tag(RemainderType.value)
                        }.pickerStyle(.segmented)
                            .frame(width: 200)
                    }
                }
            }
        }
        
        private func storeEntriesList() -> some View {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(item.instance.food.storeEntries.filter({ $0.isAvailable }), id: \.hashValue) { storeEntry in
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

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    InventoryView()
}
