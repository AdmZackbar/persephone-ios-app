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

enum FoodSheetEnum: Identifiable, SheetEnum {
    var id: String {
        switch self {
        case .Nutrients(_, let n):
            return n.wrappedValue.description
        case .StoreItem(_, let i):
            return i?.store.name ?? "item editor"
        case .Store(let s):
            return s?.name ?? "store editor"
        }
    }
    
    case Nutrients(item: FoodItem?, nutrientAmounts: Binding<[Nutrient : FoodAmount]>)
    case StoreItem(foodItem: FoodItem, item: StoreItem?)
    case Store(store: Store?)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<FoodSheetEnum>) -> some View {
        switch self {
        case .Nutrients(let i, let n):
            NutrientSheet(item: i, nutrientAmounts: n)
        case .StoreItem(let f, let i):
            StoreItemSheet(foodItem: f, item: i)
        case .Store(let s):
            StoreSheet(store: s)
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
    @Query(sort: \StoreItem.store?.name) private var storeItems: [StoreItem] = []
    
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
            Section("Nutrients") {
                Button("Edit Nutrients") {
                    sheetCoordinator.presentSheet(.Nutrients(item: item, nutrientAmounts: $nutrientAmounts))
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
            if (item != nil) {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Creation Date: \(item!.metaData.timestamp.formatted(date: .long, time: .shortened))")
                        .font(.caption)
                    if (!(item?.metaData.barcode ?? "").isEmpty) {
                        Text("Barcode: \(item!.metaData.barcode!)")
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
        } else {
            let metaData = FoodMetaData(barcode: barcode, brand: brand)
            let newItem = FoodItem(name: name,
                                   metaData: metaData,
                                   ingredients: ingredients,
                                   size: size)
            modelContext.insert(newItem)
        }
    }
    
    init(item: FoodItem?, mode: EditorMode? = nil) {
        self.item = item
        self.mode = mode ?? (item == nil ? .Add : .Edit)
    }
}

struct StoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    let store: Store?
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Name:")
                    TextField("required", text: $name).textInputAutocapitalization(.words)
                }
            }.navigationTitle(store == nil ? "Add Store" : "Edit Store")
                .navigationBarBackButtonHidden()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(store == nil ? "Cancel" : "Revert") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            if let store {
                                store.name = name
                            } else {
                                let store = Store(name: name)
                                modelContext.insert(store)
                            }
                            dismiss()
                        }.disabled(name.isEmpty)
                    }
                }
        }.presentationDetents([.medium])
            .onAppear {
                if let store {
                    name = store.name
                }
            }
    }
    
    init(store: Store? = nil) {
        self.store = store
    }
}

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
                            if let item {
                                item.store = store
                                item.quantity = quantity
                                item.price = Price(cents: price)
                                item.available = available
                            } else {
                                let item = StoreItem(store: store, foodItem: foodItem, quantity: quantity, price: Price(cents: price), available: available)
                                modelContext.insert(item)
                            }
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
    
    init(foodItem: FoodItem, item: StoreItem? = nil) {
        self.foodItem = foodItem
        self.item = item
    }
}

struct NutrientSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: FoodItem?
    
    @Binding private var nutrientAmounts: [Nutrient : FoodAmount]
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.zeroSymbol = ""
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            List {
                createNutrientEntry(.Energy).font(.title2).bold()
                createNutrientEntry(.TotalFat).bold()
                createNutrientEntry(.SaturatedFat).fontWeight(.thin)
                createNutrientEntry(.TransFat).fontWeight(.thin)
                createNutrientEntry(.PolyunsaturatedFat).fontWeight(.thin)
                createNutrientEntry(.MonounsaturatedFat).fontWeight(.thin)
                createNutrientEntry(.Cholesterol).bold()
                createNutrientEntry(.Sodium).bold()
                createNutrientEntry(.TotalCarbs).bold()
                createNutrientEntry(.DietaryFiber).fontWeight(.thin)
                createNutrientEntry(.TotalSugars).fontWeight(.thin)
                createNutrientEntry(.AddedSugars).fontWeight(.thin)
                createNutrientEntry(.Protein).bold()
                createNutrientEntry(.VitaminD).italic().fontWeight(.thin)
                createNutrientEntry(.Potassium).italic().fontWeight(.thin)
                createNutrientEntry(.Calcium).italic().fontWeight(.thin)
                createNutrientEntry(.Iron).italic().fontWeight(.thin)
            }.navigationTitle("Nutrients")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(item != nil ? "Revert" : "Clear") {
                            if let item = item {
                                nutrientAmounts = item.ingredients.nutrients
                            } else {
                                nutrientAmounts = [:]
                            }
                            
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Hide") {
                            dismiss()
                        }
                    }
                }
        }
    }
    
    private func createNutrientEntry(_ nutrient: Nutrient) -> some View {
        HStack(spacing: 8) {
            Text(getFieldName(nutrient))
            TextField("", value: Binding<Double>(get: {
                nutrientAmounts[nutrient]?.value ?? 0
            }, set: { value in
                nutrientAmounts[nutrient] = FoodAmount(value: value, unit: nutrient.getCommonUnit())
            }), formatter: formatter)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
            if (nutrient != .Energy && nutrientAmounts[nutrient]?.value ?? 0 > 0) {
                Text(nutrient.getCommonUnit().getAbbreviation())
            }
        }.swipeActions(allowsFullSwipe: false) {
            if nutrientAmounts[nutrient]?.value ?? 0 > 0 {
                Button("Clear") {
                    clearEntry(nutrient)
                }.tint(.red)
            }
            if item != nil && nutrientAmounts[nutrient] != item?.getNutrient(nutrient) {
                Button("Revert") {
                    revertEntry(nutrient)
                }
            }
            if nutrientAmounts[nutrient]?.value ?? 0 > 0 {
                Button("Round") {
                    roundEntry(nutrient)
                }.tint(.blue)
            }
        }.contextMenu {
            Button("Clear") {
                clearEntry(nutrient)
            }.disabled(nutrientAmounts[nutrient]?.value ?? 0 <= 0)
            if item != nil {
                Button("Revert") {
                    revertEntry(nutrient)
                }.disabled(nutrientAmounts[nutrient] == item?.getNutrient(nutrient))
            }
            Button("Round") {
                roundEntry(nutrient)
            }.disabled(nutrientAmounts[nutrient]?.value ?? 0 <= 0)
        }
    }
    
    private func roundEntry(_ nutrient: Nutrient) {
        if let amount = nutrientAmounts[nutrient] {
            nutrientAmounts[nutrient] = FoodAmount(value: round(amount.value), unit: amount.unit)
        }
    }
    
    private func clearEntry(_ nutrient: Nutrient) {
        nutrientAmounts[nutrient] = nil
    }
    
    private func revertEntry(_ nutrient: Nutrient) {
        if let item = item {
            nutrientAmounts[nutrient] = item.getNutrient(nutrient)
        }
    }
    
    private func getFieldName(_ nutrient: Nutrient) -> String {
        switch nutrient {
        case .Energy:
            return "Calories:"
        case .TotalFat:
            return "Total Fat:"
        case .SaturatedFat:
            return "Sat. Fat:"
        case .TransFat:
            return "Trans Fat:"
        case .PolyunsaturatedFat:
            return "Poly. Fat:"
        case .MonounsaturatedFat:
            return "Mono. Fat:"
        case .Sodium:
            return "Sodium:"
        case .Cholesterol:
            return "Cholesterol:"
        case .TotalCarbs:
            return "Total Carbs:"
        case .DietaryFiber:
            return "Dietary Fiber:"
        case .TotalSugars:
            return "Total Sugars:"
        case .AddedSugars:
            return "Added Sugars:"
        case .Protein:
            return "Protein:"
        case .VitaminD:
            return "Vitamin D:"
        case .Potassium:
            return "Potassium:"
        case .Calcium:
            return "Calcium:"
        case .Iron:
            return "Iron:"
        }
    }
    
    init(item: FoodItem?, nutrientAmounts: Binding<[Nutrient : FoodAmount]>) {
        self.item = item
        self._nutrientAmounts = nutrientAmounts
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    let store = Store(name: "Costco")
    container.mainContext.insert(store)
    container.mainContext.insert(StoreItem(store: store, foodItem: item, quantity: 2, price: Price(cents: 500), available: true))
    return NavigationStack {
        FoodItemEditor(item: item)
    }.modelContainer(container)
}
