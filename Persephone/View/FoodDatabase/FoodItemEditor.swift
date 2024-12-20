//
//  FoodItemEditor.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct FoodItemEditor: View {
    @Environment(\.modelContext) var modelContext
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    
    enum Mode {
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
    
    let item: FoodItem
    let mode: Mode
    
    @Binding private var path: [FoodDatabaseView.ViewType]
    // Name details
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var details: String = ""
    // Size
    @State private var amountUnit: Unit = .Gram
    @State private var numServings: Double = 0.0
    @State private var servingSize: String = ""
    @State private var totalAmount: Double = 0
    private var servingAmount: Double? {
        get {
            if (totalAmount <= 0 || numServings <= 0) {
                return nil
            }
            return totalAmount / numServings
        }
    }
    // Ingredients
    @State private var ingredients: String = ""
    @State private var allergens: String = ""
    @State private var nutrients: NutritionDict = [:]
    @State private var storeItems: [FoodItem.StoreEntry] = []
    @State private var rating: Double? = nil
    @State private var tags: [String] = []
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.zeroSymbol = ""
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    init(path: Binding<[FoodDatabaseView.ViewType]>, item: FoodItem? = nil, mode: Mode? = nil) {
        self._path = path
        self.item = item ?? FoodItem(name: "", details: "", metaData: FoodItem.MetaData(), ingredients: FoodIngredients(nutrients: [:]), size: FoodItem.Size(totalAmount: Quantity(value: .Raw(0), unit: .Gram), numServings: 1, servingSize: ""), storeEntries: [])
        self.mode = mode ?? (item == nil ? .Add : .Edit)
    }
    
    var body: some View {
        Form {
            mainSection()
            nutrientsSection()
            Section("Ingredients") {
                TextField("ingredients", text: $ingredients, axis: .vertical)
                    .textInputAutocapitalization(.words)
                    .lineLimit(2...12)
                HStack {
                    Text("Allergens:")
                    TextField("None", text: $allergens)
                        .textInputAutocapitalization(.words)
                }.bold()
            }
            Section("Description") {
                TextField("optional", text: $details, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(1...8)
            }
            storeSection()
            Section("Tags") {
                if !tags.isEmpty {
                    HStack {
                        Text(tags.joined(separator: ", "))
                            .italic(item.metaData.tags.isEmpty)
                            .lineLimit(1...3)
                        Spacer()
                    }.contentShape(Rectangle())
                        .onTapGesture {
                            sheetCoordinator.presentSheet(.Tags(tags: $tags))
                        }
                } else {
                    Button("Add Tag(s)") {
                        sheetCoordinator.presentSheet(.Tags(tags: $tags))
                    }
                }
            }
            Section("Rating") {
                Picker("Rating:", selection: $rating) {
                    Text("N/A").tag(nil as Double?)
                    ForEach(RatingTier.allCases) { tier in
                        Text(tier.rawValue).tag(tier.rating as Double?)
                    }
                }.pickerStyle(.segmented)
            }
        }.navigationTitle(mode.getTitle())
            .toolbarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheetCoordinating(coordinator: sheetCoordinator)
            .onAppear(perform: load)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        path.removeLast()
                    }.disabled(path.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save).disabled(path.isEmpty || isMainInfoInvalid() || isSizeInvalid())
                }
            }
    }
    
    private func mainSection() -> some View {
        Section(item.metaData.barcode ?? "") {
            HStack {
                Text("Name:").fontWeight(.light)
                TextField("required", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            HStack {
                Text("Brand:").fontWeight(.light)
                TextField("optional", text: $brand)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            HStack {
                Text(amountUnit.isWeight ? "Net Wt:" : "Net Vol:").fontWeight(.light)
                Picker(selection: $amountUnit) {
                    createAmountUnitOption(.Gram)
                    createAmountUnitOption(.Ounce)
                    createAmountUnitOption(.Milliliter)
                    createAmountUnitOption(.FluidOunce)
                } label: {
                    TextField("required", value: $totalAmount, formatter: formatter)
                        .keyboardType(.decimalPad)
                }.gridCellAnchor(UnitPoint(x: 0, y: 0.5))
            }
            HStack {
                Text("Num Servings:").fontWeight(.light)
                TextField("required", value: $numServings, formatter: formatter)
                    .keyboardType(.decimalPad)
            }
            HStack {
                Text("Serving Size:").fontWeight(.light)
                if servingAmount != nil {
                    HStack {
                        TextField("required", text: $servingSize)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                        Spacer()
                        Text("(\(formatter.string(for: servingAmount)!)\(amountUnit.abbreviation))")
                            .fontWeight(.light)
                            .italic()
                            .onTapGesture {
                                sheetCoordinator.presentSheet(.ServingAmount(totalAmount: $totalAmount, numServings: $numServings))
                            }
                    }
                } else {
                    TextField("required", text: $servingSize)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
            }
        }
    }
    
    private func nutrientsSection() -> some View {
        Section("Nutrients") {
            NutrientTableView(nutrients: nutrients)
                .contextMenu {
                    Button("Edit Individual Nutrients") {
                        sheetCoordinator.presentSheet(.Nutrients(nutrients: $nutrients))
                    }
                    Button("Scale All") {
                        sheetCoordinator.presentSheet(.NutrientsScale(item: item))
                    }
                }
                .onTapGesture {
                    sheetCoordinator.presentSheet(.Nutrients(nutrients: $nutrients))
                }
            
        }
    }
    
    private func storeSection() -> some View {
        Section("Store Listings") {
            List($storeItems, id: \.hashValue) { $storeItem in
                Button {
                    sheetCoordinator.presentSheet(.EditStoreItem(item: $storeItem))
                } label: {
                    HStack {
                        Text(storeItem.storeName).bold()
                        if storeItem.sale {
                            Text("(sale)").font(.subheadline).fontWeight(.light)
                        } else if !storeItem.available {
                            Text("(retired)").font(.subheadline).fontWeight(.light)
                        }
                        Spacer()
                        switch storeItem.costType {
                        case .Collection(let cost, let quantity):
                            VStack(alignment: .trailing) {
                                Text("\(formatter.string(for: quantity)!) for \(cost.toString())")
                                if !storeItem.available {
                                    Text("(retired)").font(.caption).fontWeight(.thin)
                                }
                            }
                        case .PerAmount(let cost, let amount):
                            VStack(alignment: .trailing) {
                                Text("\(cost.toString()) / \(amount.value.value == 1 ? "" : amount.value.toString())\(amount.unit.abbreviation)")
                                if !storeItem.available {
                                    Text("(retired)").font(.caption).fontWeight(.thin)
                                }
                            }
                        }
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain).swipeActions(allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        storeItems.removeAll(where: { s in s == storeItem })
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
            Button("Add Listing...") {
                sheetCoordinator.presentSheet(.AddStoreItem(storeItems: $storeItems))
            }
        }
    }
    
    private func createAmountUnitOption(_ unit: Unit) -> some View {
        Text(unit.abbreviation).tag(unit).font(.subheadline).fontWeight(.thin)
    }
    
    private func isMainInfoInvalid() -> Bool {
        return name.isEmpty
    }
    
    private func isSizeInvalid() -> Bool {
        return servingSize.isEmpty || numServings <= 0 || totalAmount <= 0
    }
    
    private func load() {
        switch mode {
        case .Confirm, .Edit:
            name = item.name
            brand = item.metaData.brand ?? ""
            details = item.details
            amountUnit = item.size.totalAmount.unit
            numServings = item.size.numServings
            servingSize = item.size.servingSize
            totalAmount = item.size.totalAmount.value.value
            ingredients = item.ingredients.all
            allergens = item.ingredients.allergens
            nutrients = item.ingredients.nutrients
            storeItems = item.storeEntries
            rating = item.metaData.rating
            tags = item.metaData.tags
        default:
            break
        }
    }
    
    private func save() {
        item.name = name
        item.metaData.brand = brand
        item.details = details
        item.size = FoodItem.Size(totalAmount: Quantity(value: .Raw(totalAmount), unit: amountUnit), numServings: numServings, servingSize: servingSize)
        item.ingredients.all = ingredients
        item.ingredients.allergens = allergens
        item.ingredients.nutrients = nutrients
        item.storeEntries = storeItems
        item.metaData.rating = rating
        item.metaData.tags = tags
        switch mode {
        case .Add, .Confirm:
            modelContext.insert(item)
        default:
            break
        }
        switch mode {
        case .Confirm:
            path.removeAll()
            path.append(.ItemView(item: item))
        default:
            path.removeLast()
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        FoodItemEditor(path: .constant([]), item: item)
    }.modelContainer(container)
}
