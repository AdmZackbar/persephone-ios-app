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
    @State private var showNutrientEditor: Bool = false
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
            Section("Nutrients") {
                Button("Edit Nutrients") {
                    showNutrientEditor = true
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
        .sheet(isPresented: $showNutrientEditor) {
            NavigationStack {
                NutrientEditor($nutrientAmounts).toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(item == nil ? "Clear" : "Revert") {
                            if let item = item {
                                nutrientAmounts = item.ingredients.nutrients
                            } else {
                                nutrientAmounts = [:]
                            }
                            showNutrientEditor = false
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Hide") {
                            showNutrientEditor = false
                        }
                    }
                }.navigationTitle("Nutrients")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
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
        var ingredients = FoodIngredients(
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

struct NutrientEditor: View {
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
            Button("Clear") {
                clearEntry(nutrient)
            }.disabled(nutrientAmounts[nutrient]?.value ?? 0 <= 0).tint(.red)
            Button("Round") {
                roundEntry(nutrient)
            }.disabled(nutrientAmounts[nutrient]?.value ?? 0 <= 0).tint(.blue)
        }.contextMenu {
            Button("Clear") {
                clearEntry(nutrient)
            }.disabled(nutrientAmounts[nutrient]?.value ?? 0 <= 0)
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
    
    init(_ nutrientAmounts: Binding<[Nutrient : FoodAmount]>) {
        self._nutrientAmounts = nutrientAmounts
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        FoodItemEditor(item: item)
    }.modelContainer(container)
}
