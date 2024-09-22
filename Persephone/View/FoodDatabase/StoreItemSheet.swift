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
    
    enum CostType {
        case Collection
        case PerAmount
    }
    
    let mode: Mode
    
    @State private var storeName: String = ""
    @State private var costType: CostType = .Collection
    @State private var quantity: Int = 1
    @State private var amount: Double = 1
    @State private var unit: Unit = .Pound
    @State private var price: Int = 0
    @State private var available: Bool = true
    @State private var sale: Bool = false
    
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
                Picker("", selection: $costType) {
                    Text("Collection").tag(CostType.Collection)
                    Text("Per Amount").tag(CostType.PerAmount)
                }.pickerStyle(.segmented)
                switch costType {
                case .Collection:
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
                case .PerAmount:
                    Picker(selection: $unit) {
                        Text("lb").tag(Unit.Pound)
                        Text("oz").tag(Unit.Ounce)
                    } label: {
                        TextField("", value: $amount, formatter: formatter)
                    }
                }
                Toggle(isOn: $sale) {
                    Text("Sale:")
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
                        self.costType = .Collection
                        switch cost {
                        case .Cents(let amount):
                            self.price = amount
                        }
                        self.quantity = quantity
                    case .PerAmount(let cost, let amount):
                        self.costType = .PerAmount
                        switch cost {
                        case .Cents(let amount):
                            self.price = amount
                        }
                        self.amount = amount.value.value
                        self.unit = amount.unit
                    }
                    self.sale = item.wrappedValue.sale
                    self.available = item.wrappedValue.available
                default:
                    break
                }
            }
    }
    
    private func save() {
        switch mode {
        case .Add(let items):
            items.wrappedValue.append(FoodItem.StoreEntry(storeName: storeName, costType: computeCostType(), available: available, sale: sale))
        case .Edit(let item):
            item.wrappedValue.storeName = storeName
            item.wrappedValue.costType = computeCostType()
            item.wrappedValue.sale = sale
            item.wrappedValue.available = available
        }
    }
    
    private func computeCostType() -> FoodItem.CostType {
        switch costType {
        case .Collection:
            return .Collection(cost: .Cents(price), quantity: quantity)
        case .PerAmount:
            return .PerAmount(cost: .Cents(price), amount: Quantity(value: .Raw(amount), unit: unit))
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return StoreItemSheet(mode: .Edit(item: .constant(item.storeEntries.first!)))
        .modelContainer(container)
}
