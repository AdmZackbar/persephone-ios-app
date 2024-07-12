//
//  FoodItemEditor.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct FoodItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    let item: FoodItem?
    
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
    
    // Main Info
    @State private var name: String = ""
    
    // Metadata
    @State private var barcode: String?
    @State private var brand: String = ""
    @State private var details: String = ""
    
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
                HStack {
                    TextField("Brand", text: $brand)
                    Menu {
                        ForEach(defaultBrands, id: \.self) { b in
                            Button(b) {
                                brand = b
                            }
                        }
                    } label: {
                        Label("Set Brand", systemImage: "chevron.right").labelStyle(.iconOnly)
                    }
                }
            }
            Section("Store") {
                Toggle("Store-Bought", isOn: $storeExpanded)
                if (storeExpanded) {
                    HStack {
                        TextField("Store Name", text: $store)
                        Menu {
                            ForEach(defaultStores, id: \.self) { s in
                                Button(s) {
                                    store = s
                                }
                            }
                        } label: {
                            Label("Set Store", systemImage: "chevron.right").labelStyle(.iconOnly)
                        }
                    }
                    CurrencyTextField(numberFormatter: currencyFormatter, value: $price)
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
                    }
                }
                HStack {
                    Text("Num. Servings:").gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                    TextField("required", value: $numServings, formatter: gramFormatter)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    if (numServings > 0) {
                        Text("servings").font(.subheadline).fontWeight(.thin)
                    }
                }
                HStack {
                    Text("Serving Size:").gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                    TextField("required", text: $servingSize)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                    if (servingAmount != nil) {
                        Text("(\(intFormatter.string(for: servingAmount)!)\(sizeType == .Mass ? "g" : "mL"))").font(.subheadline).fontWeight(.thin)
                    }
                }
            }
            Section("Nutrients") {
                createNutrientEntry(field: "Calories:", unit: "", value: $calories)
                DisclosureGroup(
                    isExpanded: $carbsExpanded,
                    content: {
                        Grid {
                            createNutrientSubEntry(field: "Dietary Fiber:", value: $dietaryFiber)
                            Divider()
                            createNutrientSubEntry(field: "Total Sugars:", value: $totalSugars)
                            Divider()
                            createNutrientSubEntry(field: "Added Sugars:", value: $addedSugars)
                        }
                    },
                    label: { createNutrientEntry(field: "Total Carbs:", value: $totalCarbs) }
                )
                DisclosureGroup(
                    isExpanded: $fatExpanded,
                    content: {
                        Grid {
                            createNutrientSubEntry(field: "Sat. Fat:", value: $satFat)
                            Divider()
                            createNutrientSubEntry(field: "Trans Fat:", value: $transFat)
                            Divider()
                            createNutrientSubEntry(field: "Poly. Fat:", value: $polyFat)
                            Divider()
                            createNutrientSubEntry(field: "Mono. Fat:", value: $monoFat)
                        }
                    },
                    label: { createNutrientEntry(field: "Total Fat:", value: $totalFat) }
                )
                Grid {
                    createNutrientEntry(field: "Protein:", value: $protein)
                    Divider()
                    createNutrientEntry(field: "Sodium:", unit: "mg", value: $sodium)
                    Divider()
                    createNutrientEntry(field: "Cholesterol:", unit: "mg", value: $cholesterol)
                }
            }
            Section("Ingredients") {
                TextEditor(text: $ingredients)
                    .frame(height: 70)
            }
            Section("Allergens") {
                TextField("Optional", text: $allergens)
            }
            Section("Description") {
                TextEditor(text: $details)
                    .frame(height: 70)
            }
        }
        .onAppear {
            if let item {
                name = item.name
                // Metadata
                barcode = item.metaData.barcode
                brand = item.metaData.brand ?? ""
                details = item.metaData.details ?? ""
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
                calories = item.composition.calories
                totalCarbs = getNutrientInG(.TotalCarbs)
                dietaryFiber = getNutrientInG(.DietaryFiber)
                totalSugars = getNutrientInG(.TotalSugars)
                addedSugars = getNutrientInG(.AddedSugars)
                totalFat = getNutrientInG(.TotalFat)
                satFat = getNutrientInG(.SaturatedFat)
                transFat = getNutrientInG(.TransFat)
                polyFat = getNutrientInG(.PolyunsaturatedFat)
                monoFat = getNutrientInG(.MonounsaturatedFat)
                protein = getNutrientInG(.Protein)
                sodium = item.composition.nutrients[.Sodium] ?? 0.0
                cholesterol = item.composition.nutrients[.Cholesterol] ?? 0.0
                ingredients = item.composition.ingredients.joined(separator: ",")
                allergens = item.composition.allergens.joined(separator: ",")
            }
        }
        .navigationTitle("\(item == nil ? "Add" : "Edit") Food Entry")
        .toolbar {
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
        .navigationBarBackButtonHidden()
    }
    
    private func getNutrientInG(_ nutrient: Nutrient) -> Double {
        return item == nil || item!.composition.nutrients[nutrient] == nil ? 0.0 : item!.composition.nutrients[nutrient]! / 1000.0
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
    
    private func createNutrientEntry(field: String, unit: String = "g", value: Binding<Double>) -> some View {
        HStack(spacing: 8.0) {
            Text(field)
            TextField("", value: value, formatter: gramFormatter)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
            if (!unit.isEmpty && value.wrappedValue > 0) {
                Text(unit)
            }
        }
    }
    
    private func createNutrientSubEntry(field: String, unit: String = "g", value: Binding<Double>) -> some View {
        GridRow {
            Text(field).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
            TextField("", value: value, formatter: gramFormatter)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
            if (!unit.isEmpty && value.wrappedValue > 0) {
                Text(unit)
            }
        }
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
            calories: calories,
            nutrients: [
                .TotalCarbs: totalCarbs * 1000.0,
                .DietaryFiber: dietaryFiber * 1000.0,
                .TotalSugars: totalSugars * 1000.0,
                .AddedSugars: addedSugars * 1000.0,
                .TotalFat: totalFat * 1000.0,
                .SaturatedFat: satFat * 1000.0,
                .TransFat: transFat * 1000.0,
                .PolyunsaturatedFat: polyFat * 1000.0,
                .MonounsaturatedFat: monoFat * 1000.0,
                .Protein: protein * 1000.0,
                .Sodium: sodium,
                .Cholesterol: cholesterol
            ],
            ingredients: ingredients.components(separatedBy: ","),
            allergens: allergens.components(separatedBy: ","))
        composition.nutrients.keys.forEach { key in
            if composition.nutrients[key]! <= 0 {
                composition.nutrients.removeValue(forKey: key)
            }
        }
        if let item {
            item.name = name
            item.metaData.brand = brand
            item.metaData.details = details
            item.storeInfo = storeInfo
            item.sizeInfo = sizeInfo
            item.composition = composition
        } else {
            let metaData = FoodMetaData(barcode: barcode, brand: brand, details: details)
            let newItem = FoodItem(name: name,
                                   metaData: metaData,
                                   composition: composition,
                                   sizeInfo: sizeInfo,
                                   storeInfo: storeInfo)
            modelContext.insert(newItem)
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    return NavigationStack {
        FoodItemEditor(item: nil)
    }.modelContainer(container)
}
