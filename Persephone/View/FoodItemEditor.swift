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
                TextField("Name", text: $name).textInputAutocapitalization(.words)
                HStack {
                    TextField("Brand", text: $brand).textInputAutocapitalization(.words)
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
                        TextField("Store Name", text: $store).textInputAutocapitalization(.words)
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
                createNutrientEntry(.Energy, value: $calories).bold()
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
                    label: { createNutrientEntry(.TotalFat, value: $totalFat).bold() }
                )
                createNutrientEntry(.Sodium, value: $sodium).bold()
                createNutrientEntry(.Cholesterol, value: $cholesterol).bold()
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
                    label: { createNutrientEntry(.TotalCarbs, value: $totalCarbs).bold() }
                )
                createNutrientEntry(.Protein, value: $protein).bold()
                createNutrientEntry(.VitaminD, value: $vitaminD)
                createNutrientEntry(.Potassium, value: $potassium)
                createNutrientEntry(.Calcium, value: $calcium)
                createNutrientEntry(.Iron, value: $iron)
            }
            Section("Ingredients") {
                TextEditor(text: $ingredients)
                    .textInputAutocapitalization(.words)
                    .frame(height: 100)
            }
            Section("Allergens") {
                TextField("Optional", text: $allergens).textInputAutocapitalization(.words)
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
