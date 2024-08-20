//
//  StoreItemSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/25/24.
//

import SwiftData
import SwiftUI

struct StoreItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    @Query(sort: \Store.name) private var stores: [Store]
    
    enum Mode {
        case Add(foodItem: FoodItem, items: Binding<[StoreItem]>)
        case Edit(item: StoreItem)
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Entry"
            case .Edit:
                "Edit Entry"
            }
        }
        
        func getHeader() -> String {
            switch self {
            case .Add(let item, _):
                item.name
            case .Edit(let item):
                item.foodItem.name
            }
        }
        
        func getBackAction() -> String {
            switch self {
            case .Add:
                "Back"
            case .Edit:
                "Revert"
            }
        }
    }
    
    let mode: Mode
    
    @State private var store: Store? = nil
    @State private var quantity: Int = 1
    @State private var price: Int = 0
    @State private var available: Bool = true
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(mode.getHeader()) {
                    if !stores.isEmpty {
                        HStack {
                            Text("Store:")
                            Menu(store?.name ?? "Select Store...") {
                                ForEach(stores, id: \.name) { s in
                                    Button(s.name) {
                                        store = s
                                    }
                                }
                                Divider()
                                Button {
                                    sheetCoordinator.presentSheet(.Store(store: nil))
                                } label: {
                                    Label("Add Store", systemImage: "plus")
                                }
                            }
                        }
                    } else {
                        Button("Add Store...") {
                            sheetCoordinator.presentSheet(.Store(store: nil))
                        }
                    }
                    HStack {
                        Text("Total Price:")
                        CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
                    }
                    Stepper {
                        HStack {
                            Text("Quantity:")
                            TextField("", value: $quantity, formatter: formatter)
                                .keyboardType(.numberPad)
                        }
                    } onIncrement: {
                        quantity += 1
                    } onDecrement: {
                        if quantity > 1 {
                            quantity -= 1
                        }
                    }
                    Toggle(isOn: $available) {
                        Text("Available:")
                    }
                }
            }.navigationTitle(mode.getTitle())
                .navigationBarBackButtonHidden()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(mode.getBackAction()) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            save()
                            dismiss()
                        }.disabled(store == nil || quantity < 1 || price <= 0)
                    }
                }
                .sheetCoordinating(coordinator: sheetCoordinator)
        }.presentationDetents([.medium])
            .onAppear {
                switch mode {
                case .Edit(let item):
                    store = item.store
                    quantity = item.quantity
                    price = item.price.cents
                    available = item.available
                default:
                    break
                }
            }
    }
    
    private func save() {
        switch mode {
        case .Add(let item, let items):
            items.wrappedValue.append(StoreItem(store: store!, foodItem: item, quantity: quantity, price: Price(cents: price), available: available))
        case .Edit(let item):
            item.store = store!
            item.quantity = quantity
            item.price = Price(cents: price)
            item.available = available
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    container.mainContext.insert(Store(name: "Publix"))
    container.mainContext.insert(Store(name: "Target"))
    return StoreItemSheet(mode: .Add(foodItem: item, items: .constant([])))
        .modelContainer(container)
}
