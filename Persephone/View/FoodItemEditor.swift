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
        case Name, Brand, Store, Price, TotalAmount, NumServings, ServingSize
        case Calories, TotalFat, Sodium, Cholesterol, TotalCarbs, Protein
        case VitaminD, Potassium, Calcium, Iron
        case Ingredients, Allergens
        
        func getPrevious() -> FocusableField? {
            switch self {
            case .Name:
                return nil
            case .Brand:
                return .Name
            case .Store:
                return .Brand
            // TODO
            case .Price:
                return nil
            case .TotalAmount:
                return .Store
            case .NumServings:
                return .TotalAmount
            case .ServingSize:
                return .NumServings
            case .Calories:
                return .ServingSize
            case .TotalFat:
                return .Calories
            case .Sodium:
                return .TotalFat
            case .Cholesterol:
                return .Sodium
            case .TotalCarbs:
                return .Cholesterol
            case .Protein:
                return .TotalCarbs
            case .VitaminD:
                return .Protein
            case .Potassium:
                return .VitaminD
            case .Calcium:
                return .Potassium
            case .Iron:
                return .Calcium
            case .Ingredients:
                return .Iron
            case .Allergens:
                return .Ingredients
            }
        }
        
        func getNext() -> FocusableField? {
            switch self {
            case .Name:
                return .Brand
            case .Brand:
                return .Store
            case .Store:
                return .TotalAmount
            // TODO
            case .Price:
                return nil
            case .TotalAmount:
                return .NumServings
            case .NumServings:
                return .ServingSize
            case .ServingSize:
                return .Calories
            case .Calories:
                return .TotalFat
            case .TotalFat:
                return .Sodium
            case .Sodium:
                return .Cholesterol
            case .Cholesterol:
                return .TotalCarbs
            case .TotalCarbs:
                return .Protein
            case .Protein:
                return .VitaminD
            case .VitaminD:
                return .Potassium
            case .Potassium:
                return .Calcium
            case .Calcium:
                return .Iron
            case .Iron:
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
    
    private let defaultBrands: [String] = [
        "Kirkland",
        "Publix"
    ]
    private let defaultStores: [String] = [
        "Costco",
        "Publix",
        "Target",
        "Kroger",
        "Trader Joe's",
        "Amazon"
    ]
    
    @FocusState private var focusedField: FocusableField?
    
    // Main Info
    @State private var name: String = ""
    
    // Metadata
    @State private var barcode: String?
    @State private var brand: String = ""
    
    // Size Info
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
    @State private var sizeType: SizeType = .Mass
    
    // Store Info
    @State private var storeExpanded: Bool = true
    @State private var store: String = ""
    @State private var price: Int = 0
    
    // Composition Info
    @State private var carbsExpanded: Bool = false
    @State private var fatExpanded: Bool = false
    @State private var calories: Double = 0.0
    // Nutrients
    @State private var totalCarbs: Double = 0.0
    @State private var dietaryFiber: Double = 0.0
    @State private var totalSugars: Double = 0.0
    @State private var addedSugars: Double = 0.0
    @State private var totalFat: Double = 0.0
    @State private var satFat: Double = 0.0
    @State private var transFat: Double = 0.0
    @State private var polyFat: Double = 0.0
    @State private var monoFat: Double = 0.0
    @State private var protein: Double = 0.0
    @State private var sodium: Double = 0.0
    @State private var cholesterol: Double = 0.0
    @State private var calcium: Double = 0.0
    @State private var potassium: Double = 0.0
    @State private var vitaminD: Double = 0.0
    @State private var iron: Double = 0.0
    // Other
    @State private var ingredients: String = ""
    @State private var allergens: String = ""
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    let gramFormatter: NumberFormatter = {
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
                    Menu {
                        ForEach(defaultBrands, id: \.self) { b in
                            Button(b) {
                                brand = b
                            }
                        }
                    } label: {
                        Label("Set Brand", systemImage: "list.bullet").labelStyle(.iconOnly)
                    }
                }
            }
            Section("Store") {
                Toggle("Store-Bought", isOn: $storeExpanded)
                if (storeExpanded) {
                    HStack {
                        TextField("Store Name", text: $store)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .Store)
                        Menu {
                            ForEach(defaultStores, id: \.self) { s in
                                Button(s) {
                                    store = s
                                }
                            }
                        } label: {
                            Label("Set Store", systemImage: "list.bullet").labelStyle(.iconOnly)
                        }
                    }
                    CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
                        .focused($focusedField, equals: .Price)
                }
            }
            Section("Size") {
                Picker(selection: $sizeType) {
                    Text("Weight (g)").tag(SizeType.Mass)
                    Text("Volume (mL)").tag(SizeType.Volume)
                } label: {
                    HStack {
                        Text("Net \(sizeType == .Mass ? "Weight" : "Volume"):")
                        TextField("required", value: $totalAmount, formatter: gramFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .TotalAmount)
                    }
                }
                HStack {
                    Text("Num. Servings:").gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                    TextField("required", value: $numServings, formatter: gramFormatter)
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
                        Text("(\(intFormatter.string(for: servingAmount)!)\(sizeType == .Mass ? "g" : "mL"))").font(.subheadline).fontWeight(.thin)
                    }
                }
            }
            Section("Nutrients") {
                createNutrientEntry(.Energy, value: $calories)
                DisclosureGroup(
                    isExpanded: $fatExpanded,
                    content: {
                        Grid {
                            createNutrientSubEntry(.SaturatedFat, value: $satFat)
                            Divider()
                            createNutrientSubEntry(.TransFat, value: $transFat)
                            Divider()
                            createNutrientSubEntry(.PolyunsaturatedFat, value: $polyFat)
                            Divider()
                            createNutrientSubEntry(.MonounsaturatedFat, value: $monoFat)
                        }
                    },
                    label: { createNutrientEntry(.TotalFat, value: $totalFat) }
                )
                createNutrientEntry(.Cholesterol, value: $cholesterol)
                createNutrientEntry(.Sodium, value: $sodium)
                DisclosureGroup(
                    isExpanded: $carbsExpanded,
                    content: {
                        Grid {
                            createNutrientSubEntry(.DietaryFiber, value: $dietaryFiber)
                            Divider()
                            createNutrientSubEntry(.TotalSugars, value: $totalSugars)
                            Divider()
                            createNutrientSubEntry(.AddedSugars, value: $addedSugars)
                        }
                    },
                    label: { createNutrientEntry(.TotalCarbs, value: $totalCarbs) }
                )
                createNutrientEntry(.Protein, value: $protein)
                createNutrientEntry(.VitaminD, value: $vitaminD)
                createNutrientEntry(.Potassium, value: $potassium)
                createNutrientEntry(.Calcium, value: $calcium)
                createNutrientEntry(.Iron, value: $iron)
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
                // Store Info
                storeExpanded = item.storeInfo != nil
                store = item.storeInfo?.name ?? ""
                price = item.storeInfo?.price ?? 0
                // Size Info
                numServings = item.sizeInfo.numServings
                servingSize = item.sizeInfo.servingSize
                totalAmount = item.sizeInfo.totalAmount
                sizeType = item.sizeInfo.sizeType
                // Composition
                calories = getNutrient(.Energy)
                totalCarbs = getNutrient(.TotalCarbs)
                dietaryFiber = getNutrient(.DietaryFiber)
                totalSugars = getNutrient(.TotalSugars)
                addedSugars = getNutrient(.AddedSugars)
                totalFat = getNutrient(.TotalFat)
                satFat = getNutrient(.SaturatedFat)
                transFat = getNutrient(.TransFat)
                polyFat = getNutrient(.PolyunsaturatedFat)
                monoFat = getNutrient(.MonounsaturatedFat)
                protein = getNutrient(.Protein)
                sodium = getNutrient(.Sodium)
                cholesterol = getNutrient(.Cholesterol)
                vitaminD = getNutrient(.VitaminD)
                potassium = getNutrient(.Potassium)
                calcium = getNutrient(.Calcium)
                iron = getNutrient(.Iron)
                ingredients = item.composition.ingredients ?? ""
                allergens = item.composition.allergens ?? ""
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
                    .disabled(isMainInfoInvalid() || isSizeInfoInvalid() || isStoreInfoInvalid() || isCompInvalid())
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
                    .disabled(isMainInfoInvalid() || isSizeInfoInvalid() || isStoreInfoInvalid() || isCompInvalid())
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func getNutrient(_ nutrient: Nutrient) -> Double {
        return item!.composition.nutrients[nutrient] ?? 0.0
    }
    
    private func isMainInfoInvalid() -> Bool {
        return name.isEmpty
    }
    
    private func isSizeInfoInvalid() -> Bool {
        return servingSize.isEmpty || numServings <= 0 || totalAmount <= 0
    }
    
    private func isStoreInfoInvalid() -> Bool {
        return storeExpanded && (store.isEmpty || price < 0)
    }
    
    private func isCompInvalid() -> Bool {
        return calories < 0
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
    
    private func createNutrientEntry(_ nutrient: Nutrient, value: Binding<Double>) -> some View {
        HStack(spacing: 12.0) {
            Text(getFieldName(nutrient))
            TextField("", value: value, formatter: gramFormatter)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: getFocusField(nutrient)!)
            if (nutrient != .Energy && value.wrappedValue > 0) {
                Text(nutrient.getUnit())
            }
        }
    }
    
    private func createNutrientSubEntry(_ nutrient: Nutrient, value: Binding<Double>) -> some View {
        GridRow {
            Text(getFieldName(nutrient)).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
            TextField("", value: value, formatter: gramFormatter)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
            if (value.wrappedValue > 0) {
                Text(nutrient.getUnit())
            }
        }
    }
    
    private func getFocusField(_ nutrient: Nutrient) -> FocusableField? {
        switch nutrient {
        case .Energy:
            return .Calories
        case .TotalFat:
            return .TotalFat
        case .Sodium:
            return .Sodium
        case .Cholesterol:
            return .Cholesterol
        case .TotalCarbs:
            return .TotalCarbs
        case .Protein:
            return .Protein
        case .VitaminD:
            return .VitaminD
        case .Potassium:
            return .Potassium
        case .Calcium:
            return .Calcium
        case .Iron:
            return .Iron
        default:
            return nil
        }
    }
    
    private func focusPreviousField() {
        focusedField = focusedField?.getPrevious()
    }
    
    private func focusNextField() {
        focusedField = focusedField?.getNext()
    }
    
    private func save() {
        let storeInfo = storeExpanded ? StoreInfo(name: store, price: price) : nil
        let sizeInfo = FoodSizeInfo(
            numServings: numServings,
            servingSize: servingSize,
            totalAmount: totalAmount,
            servingAmount: round(totalAmount / numServings),
            sizeType: sizeType)
        var composition = FoodComposition(
            nutrients: [
                .Energy: calories,
                .TotalCarbs: totalCarbs,
                .DietaryFiber: dietaryFiber,
                .TotalSugars: totalSugars,
                .AddedSugars: addedSugars,
                .TotalFat: totalFat,
                .SaturatedFat: satFat,
                .TransFat: transFat,
                .PolyunsaturatedFat: polyFat,
                .MonounsaturatedFat: monoFat,
                .Protein: protein,
                .Sodium: sodium,
                .Cholesterol: cholesterol,
                .VitaminD: vitaminD,
                .Potassium: potassium,
                .Calcium: calcium,
                .Iron: iron
            ],
            ingredients: ingredients,
            allergens: allergens)
        composition.nutrients.keys.forEach { key in
            if composition.nutrients[key]! <= 0 {
                composition.nutrients.removeValue(forKey: key)
            }
        }
        if let item {
            item.name = name
            item.metaData.brand = brand
            item.storeInfo = storeInfo
            item.sizeInfo = sizeInfo
            item.composition = composition
        } else {
            let metaData = FoodMetaData(barcode: barcode, brand: brand)
            let newItem = FoodItem(name: name,
                                   metaData: metaData,
                                   composition: composition,
                                   sizeInfo: sizeInfo,
                                   storeInfo: storeInfo)
            modelContext.insert(newItem)
        }
    }
    
    init(item: FoodItem?, mode: EditorMode? = nil) {
        self.item = item
        self.mode = mode ?? (item == nil ? .Add : .Edit)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    let item = FoodItem(name: "Lightly Breaded Chicken Chunks",
                        metaData: FoodMetaData(
                            barcode: "102032120",
                            brand: "Kirkland"),
                        composition: FoodComposition(
                            nutrients: [
                                .Energy: 120,
                                .TotalCarbs: 4,
                                .TotalSugars: 1.5,
                                .TotalFat: 3,
                                .SaturatedFat: 1.25,
                                .Protein: 13,
                                .Sodium: 530,
                                .Cholesterol: 25,
                            ],
                            ingredients: "Salt, Chicken, Other stuff",
                        allergens: "Meat"),
                        sizeInfo: FoodSizeInfo(
                            numServings: 16,
                            servingSize: "4 oz",
                            totalAmount: 1814,
                            servingAmount: 63,
                            sizeType: .Mass),
                        storeInfo: StoreInfo(name: "Costco", price: 1399))
    return NavigationStack {
        FoodItemEditor(item: item)
    }.modelContainer(container)
}
