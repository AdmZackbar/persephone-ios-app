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
    
    enum Mode {
        case Add(items: Binding<[FoodItem.StoreEntry]>)
        case Edit(item: Binding<FoodItem.StoreEntry>)
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Entry"
            case .Edit:
                "Edit Entry"
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
    
    @State private var storeName: String = ""
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
                HStack {
                    Text("Store:")
                    TextField("required", text: $storeName)
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
                        }.disabled(storeName.isEmpty || quantity < 1 || price <= 0)
                    }
                }
                .sheetCoordinating(coordinator: sheetCoordinator)
        }.presentationDetents([.medium])
            .onAppear {
                switch mode {
                case .Edit(let item):
                    self.storeName = item.wrappedValue.storeName
                    switch item.wrappedValue.costType {
                    case .Collection(let cost, let quantity):
                        switch cost {
                        case .Cents(let amount):
                            self.price = amount
                        }
                        self.quantity = quantity
                    default:
                        break
                    }
                    self.available = item.wrappedValue.available
                default:
                    break
                }
            }
    }
    
    private func save() {
        switch mode {
        case .Add(let items):
            items.wrappedValue.append(FoodItem.StoreEntry(storeName: storeName, costType: .Collection(cost: .Cents(price), quantity: quantity), available: available))
        case .Edit(let item):
            item.wrappedValue.storeName = storeName
            item.wrappedValue.costType = .Collection(cost: .Cents(price), quantity: quantity)
            item.wrappedValue.available = available
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return StoreItemSheet(mode: .Edit(item: .constant(item.storeEntries.first!)))
        .modelContainer(container)
}
