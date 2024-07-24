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
        "Kirkland Signature",
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
            Section("Size") {
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
                        Text("(\(intFormatter.string(for: servingAmount)!)g)").font(.subheadline).fontWeight(.thin)
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
                // Size Info
                numServings = item.size.numServings
                servingSize = item.size.servingSize
                totalAmount = item.size.totalAmount.value
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
                    .disabled(isMainInfoInvalid() || isSizeInfoInvalid() || isCompInvalid())
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
                    .disabled(isMainInfoInvalid() || isSizeInfoInvalid() || isCompInvalid())
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
        return item!.getNutrient(nutrient)?.value ?? 0.0
    }
    
    private func isMainInfoInvalid() -> Bool {
        return name.isEmpty
    }
    
    private func isSizeInfoInvalid() -> Bool {
        return servingSize.isEmpty || numServings <= 0 || totalAmount <= 0
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
                Text(nutrient.getCommonUnit().getAbbreviation())
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
                Text(nutrient.getCommonUnit().getAbbreviation())
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
        let size = FoodSize(
            totalAmount: FoodAmount.grams(totalAmount),
            numServings: numServings,
            servingSize: servingSize)
        var ingredients = FoodIngredients(
            nutrients: [
                .Energy: FoodAmount.calories(calories),
                .TotalCarbs: FoodAmount.grams(totalCarbs),
                .DietaryFiber: FoodAmount.grams(dietaryFiber),
                .TotalSugars: FoodAmount.grams(totalSugars),
                .AddedSugars: FoodAmount.grams(addedSugars),
                .TotalFat: FoodAmount.grams(totalFat),
                .SaturatedFat: FoodAmount.grams(satFat),
                .TransFat: FoodAmount.grams(transFat),
                .PolyunsaturatedFat: FoodAmount.grams(polyFat),
                .MonounsaturatedFat: FoodAmount.grams(monoFat),
                .Protein: FoodAmount.grams(protein),
                .Sodium: FoodAmount.milligrams(sodium),
                .Cholesterol: FoodAmount.milligrams(cholesterol),
                .VitaminD: FoodAmount.milligrams(vitaminD),
                .Potassium: FoodAmount.milligrams(potassium),
                .Calcium: FoodAmount.milligrams(calcium),
                .Iron: FoodAmount.milligrams(iron)
            ],
            all: ingredients,
            allergens: allergens)
        ingredients.nutrients.keys.forEach { key in
            if ingredients.nutrients[key]!.value <= 0 {
                ingredients.nutrients.removeValue(forKey: key)
            }
        }
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

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        FoodItemEditor(item: item)
    }.modelContainer(container)
}
