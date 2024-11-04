//
//  AddFoodInstanceView.swift
//  Persephone
//
//  Created by Zach Wassynger on 11/4/24.
//

import SwiftData
import SwiftUI

struct AddFoodInstanceView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \FoodItem.name) var foodItems: [FoodItem]
    
    private enum OriginType: String, CaseIterable {
        case Store, Gift, Grown
    }
    
    private enum AmountType: String, CaseIterable {
        case Single, Collection
    }
    
    @Binding private var path: [InventoryView.ViewType]
    @State private var foodItem: FoodItem? = nil
    @State private var showFoodItemSheet: Bool = false
    @State private var purchaseDate: Date = Date()
    @State private var hasExpDate: Bool = false
    @State private var expDate: Date = Date()
    @State private var hasFreezeDate: Bool = false
    @State private var freezeDate: Date = Date()
    @State private var originType: OriginType = .Store
    @State private var store: String = ""
    @State private var price: Int = 0
    @State private var giftFrom: String = ""
    @State private var grownLocation: String = ""
    @State private var amountType: AmountType = .Single
    @State private var numItems: Int = 1
    
    init(path: Binding<[InventoryView.ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        Form {
            Section("Food") {
                Button(foodItem?.name ?? "Select Food Item") {
                    showFoodItemSheet = true
                }
            }
            if foodItem != nil {
                Section("Dates") {
                    DatePicker("Purchase Date:", selection: $purchaseDate, displayedComponents: .date)
                    Toggle("Expires:", isOn: $hasExpDate)
                    if hasExpDate {
                        DatePicker("Exp. Date:", selection: $expDate, displayedComponents: .date)
                    }
                    Toggle("Frozen:", isOn: $hasFreezeDate)
                    if hasFreezeDate {
                        DatePicker("Freeze Date:", selection: $freezeDate, displayedComponents: .date)
                    }
                }
                Section("Origin") {
                    originView()
                }
                Section("Amount") {
                    amountView()
                }
            }
        }.navigationTitle("Add Food Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheet(isPresented: $showFoodItemSheet) {
                NavigationStack {
                    List(foodItems) { item in
                        Button(item.name) {
                            foodItem = item
                            showFoodItemSheet = false
                        }
                    }
                }.navigationTitle("Select Food Item")
                    .navigationBarBackButtonHidden()
                    .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showFoodItemSheet = false
                        }
                    }
                }
            }.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: back)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save).disabled(isInvalid())
                }
            }
    }
    
    @ViewBuilder
    private func originView() -> some View {
        Picker("", selection: $originType) {
            ForEach(OriginType.allCases, id: \.rawValue) { type in
                Text(type.rawValue).tag(type)
            }
        }.pickerStyle(.segmented)
        switch originType {
        case .Store:
            HStack {
                Text("Store:")
                TextField("required", text: $store)
            }
            let formatter = {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.maximumFractionDigits = 2
                return formatter
            }()
            CurrencyTextField(numberFormatter: formatter, value: $price)
        case .Gift:
            HStack {
                Text("Giver:")
                TextField("required", text: $giftFrom)
            }
        case .Grown:
            HStack {
                Text("Location:")
                TextField("required", text: $grownLocation)
            }
        }
    }
    
    @ViewBuilder
    private func amountView() -> some View {
        Picker("", selection: $amountType) {
            ForEach(AmountType.allCases, id: \.rawValue) { type in
                Text(type.rawValue).tag(type)
            }
        }.pickerStyle(.segmented)
        Stepper {
            HStack {
                Text("Num. Items:")
                let formatter = {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 0
                    return formatter
                }()
                TextField("", value: $numItems, formatter: formatter)
            }
        } onIncrement: {
            numItems += 1
        } onDecrement: {
            if numItems > 0 {
                numItems -= 1
            }
        }
    }
    
    private func isInvalid() -> Bool {
        return foodItem == nil || (hasExpDate && expDate < purchaseDate) || isOriginInvalid() || numItems <= 0
    }
    
    private func isOriginInvalid() -> Bool {
        switch originType {
        case .Store:
            return store.isEmpty
        case .Gift:
            return giftFrom.isEmpty
        case .Grown:
            return grownLocation.isEmpty
        }
    }
    
    private func back() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    private func save() {
        var item: FoodInstance? = nil
        switch amountType {
        case .Single:
            for _ in 0..<numItems {
                item = createItem()
                modelContext.insert(item!)
            }
        case .Collection:
            item = createItem()
            modelContext.insert(item!)
        }
        back()
        path.append(.InstanceView(item: item!))
    }
    
    private func createItem() -> FoodInstance {
        return FoodInstance(
            foodItem: foodItem!,
            origin: computeOrigin(),
            amount: computeAmount(),
            dates: FoodInstance.Dates(
                acqDate: purchaseDate,
                expDate: hasExpDate ? expDate : nil,
                freezeDate: hasFreezeDate ? freezeDate : nil))
    }
    
    private func computeOrigin() -> FoodInstance.Origin {
        switch originType {
        case .Store:
            return .Store(store: store, cost: .Cents(price))
        case .Gift:
            return .Gift(from: giftFrom)
        case .Grown:
            return .Grown(location: grownLocation)
        }
    }
    
    private func computeAmount() -> FoodInstance.Amount {
        switch amountType {
        case .Single:
            return .Single(total: foodItem!.size.totalAmount, remaining: foodItem!.size.totalAmount)
        case .Collection:
            return .Collection(total: numItems, remaining: numItems)
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    createTestFoodItem(container.mainContext)
    return NavigationStack {
        AddFoodInstanceView(path: .constant([]))
    }.modelContainer(container)
}
