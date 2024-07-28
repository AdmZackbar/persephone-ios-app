//
//  FoodItemEditor.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

enum EditorMode {
    case Add, Edit, Confirm
    
    func getTitle() -> String {
        switch self {
        case .Add:
            return "Add Food Entry"
        case .Edit:
            return "Edit Food Entry"
        case .Confirm:
            return "Confirm Food Entry"
        }
    }
}

struct FoodItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    private enum FocusableField: Hashable, CaseIterable {
        case Name, Brand, Price, TotalAmount, NumServings, ServingSize, Ingredients, Allergens
        
        func getPrevious() -> FocusableField? {
            switch self {
            case .Name:
                return nil
            case .Brand:
                return .Name
//            case .Store:
//                return .Brand
            // TODO
            case .Price:
                return nil
            case .TotalAmount:
                return .Brand
            case .NumServings:
                return .TotalAmount
            case .ServingSize:
                return .NumServings
            case .Ingredients:
                return .ServingSize
            case .Allergens:
                return .Ingredients
            }
        }
        
        func getNext() -> FocusableField? {
            switch self {
            case .Name:
                return .Brand
            case .Brand:
                return .TotalAmount
//            case .Store:
//                return .TotalAmount
            // TODO
            case .Price:
                return nil
            case .TotalAmount:
                return .NumServings
            case .NumServings:
                return .ServingSize
            case .ServingSize:
                return .Ingredients
            case .Ingredients:
                return .Allergens
            case .Allergens:
                return nil
            }
        }
    }
    
    let item: FoodItem?
    let mode: EditorMode
    
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    @FocusState private var focusedField: FocusableField?
    
    // Main Info
    @State private var name: String = ""
    
    // Metadata
    @State private var barcode: String?
    @State private var brand: String = ""
    
    // Size Info
    @State private var amountUnit: FoodUnit = .Gram
    @State private var numServings: Double = 0.0
    @State private var servingSize: String = ""
    @State private var totalAmount: Double = 0.0
    private var servingAmount: Double? {
        get {
            if (totalAmount <= 0 || numServings <= 0) {
                return nil
            }
            return totalAmount / numServings
        }
    }
    
    // Store
    @State private var storeItems: [StoreItem] = []
    
    // Nutrients
    @State private var nutrientAmounts: [Nutrient : FoodAmount] = [:]
    // Other
    @State private var ingredients: String = ""
    @State private var allergens: String = ""
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    let sizeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    let intFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .Name)
                HStack {
                    TextField("Brand", text: $brand)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .Brand)
                }
            }
            Section("Size") {
                Picker(selection: $amountUnit) {
                    createAmountUnitOption(.Gram)
                    createAmountUnitOption(.Ounce)
                    createAmountUnitOption(.Milliliter)
                    createAmountUnitOption(.FluidOunce)
                } label: {
                    HStack {
                        Text("Total Amount:").gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        TextField("required", value: $totalAmount, formatter: sizeFormatter)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .TotalAmount)
                    }
                }
                HStack {
                    Text("Num. Servings:").gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                    TextField("required", value: $numServings, formatter: sizeFormatter)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .NumServings)
                    if (numServings > 0) {
                        Text("servings").font(.subheadline).fontWeight(.thin)
                    }
                }
                HStack {
                    Text("Serving Size:").gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                    TextField("required", text: $servingSize)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .ServingSize)
                    if (servingAmount != nil) {
                        Text("(\(intFormatter.string(for: servingAmount)!) \(amountUnit.getAbbreviation()))").font(.subheadline).fontWeight(.thin)
                    }
                }
            }
            Section("Store Listings") {
                List(storeItems, id: \.store.name) { storeItem in
                    VStack {
                        HStack {
                            Text(storeItem.store.name).font(.title3).bold()
                            Spacer()
                            Text(currencyFormatter.string(for: Double(storeItem.price.cents) / 100.0)!).font(.headline).bold()
                        }
                        HStack {
                            Text(storeItem.available ? "Available" : "Retired").font(.subheadline).italic()
                            Spacer()
                            Text("\(storeItem.quantity) units").font(.subheadline)
                        }
                    }.swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(storeItem)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            sheetCoordinator.presentSheet(.StoreItem(foodItem: item!, item: storeItem))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }.contextMenu {
                        Button(storeItem.available ? "Mark Retired" : "Mark Available") {
                            storeItem.available.toggle()
                        }
                        Button {
                            sheetCoordinator.presentSheet(.StoreItem(foodItem: item!, item: storeItem))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            modelContext.delete(storeItem)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                if let item {
                    Button {
                        sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: nil))
                    } label: {
                        Label("Add Listing", systemImage: "plus")
                    }
                }
            }
            if let item {
                Section("Nutrients") {
                    Button("Edit Nutrients") {
                        sheetCoordinator.presentSheet(.Nutrients(item: item))
                    }
                }
            }
            Section("Ingredients") {
                TextEditor(text: $ingredients)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .Ingredients)
                    .frame(height: 100)
            }
            Section("Allergens") {
                TextField("Optional", text: $allergens)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .Allergens)
            }
            if let item {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Creation Date: \(item.metaData.timestamp.formatted(date: .long, time: .shortened))")
                        .font(.caption)
                    if (!(item.metaData.barcode ?? "").isEmpty) {
                        Text("Barcode: \(item.metaData.barcode!)")
                            .font(.caption)
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .onSubmit(focusNextField)
        .onAppear {
            if let item {
                name = item.name
                // Metadata
                barcode = item.metaData.barcode
                brand = item.metaData.brand ?? ""
                // Size
                amountUnit = item.size.totalAmount.unit
                numServings = item.size.numServings
                servingSize = item.size.servingSize
                totalAmount = item.size.totalAmount.value
                // Store
                storeItems = item.storeItems
                // Ingredients
                nutrientAmounts = item.ingredients.nutrients
                ingredients = item.ingredients.all
                allergens = item.ingredients.allergens
            }
        }
        .navigationTitle(mode.getTitle())
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            // Currently causes a constraint warning, not sure how to fix
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    focusPreviousField()
                } label: {
                    Image(systemName: "chevron.up")
                }.disabled(focusedField == .Name)
                Button {
                    focusNextField()
                } label: {
                    Image(systemName: "chevron.down")
                }.disabled(focusedField == .Allergens)
                Spacer()
            }
            if (mode == .Confirm) {
                ToolbarItem(placement: .primaryAction) {
                    Button("Confirm") {
                        withAnimation {
                            save()
                            modelContext.insert(item!)
                            dismiss()
                        }
                    }
                    .disabled(isMainInfoInvalid() || isSizeInvalid() || isIngredientsInvalid())
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        dismiss()
                    }
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        withAnimation {
                            save()
                            dismiss()
                        }
                    }
                    .disabled(isMainInfoInvalid() || isSizeInvalid() || isIngredientsInvalid())
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .sheetCoordinating(coordinator: sheetCoordinator)
    }
    
    private func createAmountUnitOption(_ unit: FoodUnit) -> some View {
        Text(unit.getAbbreviation()).tag(unit).font(.subheadline).fontWeight(.thin)
    }
    
    private func isMainInfoInvalid() -> Bool {
        return name.isEmpty
    }
    
    private func isSizeInvalid() -> Bool {
        return servingSize.isEmpty || numServings <= 0 || totalAmount <= 0
    }
    
    private func isIngredientsInvalid() -> Bool {
        return !nutrientAmounts.values.allSatisfy { amount in
            amount.value >= 0
        }
    }
    
    private func focusPreviousField() {
        focusedField = focusedField?.getPrevious()
    }
    
    private func focusNextField() {
        focusedField = focusedField?.getNext()
    }
    
    private func save() {
        let size = FoodSize(
            totalAmount: FoodAmount(value: totalAmount, unit: amountUnit),
            numServings: numServings,
            servingSize: servingSize)
        let ingredients = FoodIngredients(
            nutrients: nutrientAmounts,
            all: ingredients,
            allergens: allergens)
        if let item {
            item.name = name
            item.metaData.brand = brand
            item.size = size
            item.ingredients = ingredients
            item.storeItems = storeItems
        } else {
            let metaData = FoodMetaData(barcode: barcode, brand: brand)
            let newItem = FoodItem(name: name,
                                   metaData: metaData,
                                   ingredients: ingredients,
                                   size: size)
            modelContext.insert(newItem)
            storeItems.forEach { storeItem in
                modelContext.insert(storeItem)
            }
        }
    }
    
    init(item: FoodItem?, mode: EditorMode? = nil) {
        self.item = item
        self.mode = mode ?? (item == nil ? .Add : .Edit)
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        FoodItemEditor(item: item)
    }.modelContainer(container)
}
