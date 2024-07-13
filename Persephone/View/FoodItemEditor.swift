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
                Grid {
                    createNutrientEntry(field: "Sodium:", unit: "mg", value: $sodium)
                    Divider()
                    createNutrientEntry(field: "Cholesterol:", unit: "mg", value: $cholesterol)
                    Divider()
                    createNutrientEntry(field: "Protein:", value: $protein)
                }
            }
            Section("Ingredients") {
                TextEditor(text: $ingredients)
                    .frame(height: 100)
            }
            Section("Allergens") {
                TextField("Optional", text: $allergens)
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
                ingredients = item.composition.ingredients ?? ""
                allergens = item.composition.allergens ?? ""
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
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ScannerView(barcodeHandler: lookupBarcode)
                        .navigationTitle("Scan Barcode")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
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
    
    private func lookupBarcode(barcode: String) {
        var code = barcode
        if (code.count == 13) {
            // Barcode is in EAN13 format, we want UPC-A which has
            // just 12 digits instead of 13
            code.removeFirst()
        }
        self.barcode = code
        
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(code)&pageSize=1&dataType=Branded&sortBy=publishedDate&sortOrder=desc") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("KqxXU5h1uiwyHv300gSqczUVtSKmjkAm1w7mD48k", forHTTPHeaderField: "X-Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Empty data"); return }
            parseFoodDataResult(data: data)
        }.resume()
    }
    
    private func parseFoodDataResult(data: Data) {
        let decoder = JSONDecoder()
        if let jsonData = try? decoder.decode(SearchResult.self, from: data) {
            if let food = jsonData.foods?.count ?? 0 > 0 ? jsonData.foods?[0] : nil {
                name = food.description ?? name
                brand = food.brandName ?? brand
                servingSize = food.householdServingFullText ?? servingSize
                ingredients = food.ingredients ?? ingredients
                let gramPattern = /([\d.]+)\s*[gG]/
                let kgPattern = /([\d.]+)\s*[kK][gG]/
                if let match = try? gramPattern.firstMatch(in: food.packageWeight ?? "") {
                    totalAmount = Double(match.1)!
                } else if let match = try? kgPattern.firstMatch(in: food.packageWeight ?? "") {
                    totalAmount = Double(match.1)! * 1000.0
                }
                if (totalAmount > 0 && food.servingSize != nil && food.servingSizeUnit == "g") {
                    numServings = totalAmount / food.servingSize!
                }
                var ratio = 1.0
                if (food.servingSize != nil && food.servingSizeUnit == "g") {
                    ratio = food.servingSize! / 100.0
                }
                var nutrientMap: [String : Double] = [:]
                food.foodNutrients?.forEach({ nutrient in
                    let adjValue = nutrient.value * ratio
                    // Round to nearest half
                    nutrientMap[nutrient.nutrientName] = round(adjValue * 2.0) / 2.0
                })
                calories = nutrientMap["Energy"] ?? calories
                totalFat = nutrientMap["Total lipid (fat)"] ?? totalFat
                satFat = nutrientMap["Fatty acids, total saturated"] ?? satFat
                transFat = nutrientMap["Fatty acids, total trans"] ?? transFat
                totalCarbs = nutrientMap["Carbohydrate, by difference"] ?? totalCarbs
                totalSugars = nutrientMap["Total Sugars"] ?? totalSugars
                dietaryFiber = nutrientMap["Fiber, total dietary"] ?? dietaryFiber
                protein = nutrientMap["Protein"] ?? protein
                sodium = nutrientMap["Sodium, Na"] ?? sodium
                cholesterol = nutrientMap["Cholesterol"] ?? cholesterol
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
                .Cholesterol: cholesterol
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
}

private struct SearchResult: Codable {
    let totalHits: Int?
    let currentPage: Int?
    let totalPages: Int?
    let foodSearchCriteria: FoodSearchCriteria?
    let foods: [BrandedFoodItem]?
}

private struct FoodSearchCriteria: Codable {
    let query: String?
    let dataType: [String]?
    let generalSearchInput: String?
    let numberOfResultsPerPage: Int?
    let pageSize: Int?
    let pageNumber: Int?
    let sortBy: String?
    let sortOrder: String?
}

private struct BrandedFoodItem: Codable {
    let fdcId: Int
    let description: String?
    let dataType: String
    let gtinUpc: String?
    let publishedDate: String?
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let marketCountry: String?
    let foodCategory: String?
    let modifiedDate: String?
    let dataSource: String?
    let packageWeight: String?
    let servingSizeUnit: String?
    let servingSize: Double?
    let householdServingFullText: String?
    let tradeChannels: [String]?
    let allHighlightFields: String?
    let score: Double?
    let foodNutrients: [FoodNutrient]?
}

private struct FoodNutrient: Codable {
    let nutrientId: Int
    let nutrientName: String
    let nutrientNumber: String
    let unitName: String
    let derivationCode: String
    let derivationDescription: String
    let derivationId: Int
    let value: Double
    let foodNutrientSourceId: Int
    let foodNutrientSourceCode: String
    let foodNutrientSourceDescription: String
    let rank: Int
    let indentLevel: Int
    let foodNutrientId: Int
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    return NavigationStack {
        FoodItemEditor(item: nil)
    }.modelContainer(container)
}
