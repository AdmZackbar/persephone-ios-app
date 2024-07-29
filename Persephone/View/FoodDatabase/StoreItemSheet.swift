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
    
    let foodItem: FoodItem
    let item: StoreItem?
    
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
                Section(foodItem.name) {
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
            }.navigationTitle(item == nil ? "Add Store Entry" : "Edit Store Entry")
                .navigationBarBackButtonHidden()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(item == nil ? "Cancel" : "Revert") {
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
                if let item {
                    store = item.store
                    quantity = item.quantity
                    price = item.price.cents
                    available = item.available
                }
            }
    }
    
    private func save() {
        if let item {
            item.store = store!
            item.quantity = quantity
            item.price = Price(cents: price)
            item.available = available
        } else {
            foodItem.storeItems.append(StoreItem(store: store!, foodItem: foodItem, quantity: quantity, price: Price(cents: price), available: available))
        }
    }
    
    init(foodItem: FoodItem, item: StoreItem? = nil) {
        self.foodItem = foodItem
        self.item = item
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    container.mainContext.insert(Store(name: "Publix"))
    container.mainContext.insert(Store(name: "Target"))
    return StoreItemSheet(foodItem: item, item: item.storeItems.first)
        .modelContainer(container)
}
