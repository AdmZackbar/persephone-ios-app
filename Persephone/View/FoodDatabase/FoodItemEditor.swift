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
    @State private var amountUnit: FoodUnit = .Gram
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
    @State private var storeItems: [StoreItem] = []
    
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
        self.item = item ?? FoodItem(name: "", metaData: FoodMetaData(), ingredients: FoodIngredients(nutrients: [:]), size: FoodSize(totalAmount: FoodAmount(value: .Raw(0), unit: .Gram), numServings: 1, servingSize: ""))
        self.mode = mode ?? (item == nil ? .Add : .Edit)
    }
    
    var body: some View {
        Form {
            Section(item.metaData.barcode ?? "") {
                HStack {
                    Text("Name:").fontWeight(.light)
                    TextField("required", text: $name)
                }
                HStack {
                    Text("Brand:").fontWeight(.light)
                    TextField("optional", text: $brand)
                }
                HStack {
                    Text(amountUnit.isWeight() ? "Net Wt:" : "Net Vol:").fontWeight(.light)
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
                            Spacer()
                            Text("(\(formatter.string(for: servingAmount)!)\(amountUnit.getAbbreviation()))")
                                .fontWeight(.light)
                                .italic()
                        }
                    } else {
                        TextField("required", text: $servingSize)
                    }
                }
            }
            Section("Nutrients") {
                NutrientTableView(nutrients: item.ingredients.nutrients)
                    .contextMenu {
                        Button {
                            sheetCoordinator.presentSheet(.Nutrients(item: item))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                Menu("Edit...") {
                    Button("Individual Nutrients...") {
                        sheetCoordinator.presentSheet(.Nutrients(item: item))
                    }
                    Button("Scale All...") {
                        sheetCoordinator.presentSheet(.NutrientsScale(item: item))
                    }
                }
            }
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
            Section("Tags") {
                Text(item.metaData.tags.isEmpty ? "No tags" : item.metaData.tags.joined(separator: ", "))
                    .italic(item.metaData.tags.isEmpty)
                Button("Edit Tags...") {
                    sheetCoordinator.presentSheet(.Tags(item: item))
                }
            }
            // Can only add store items if the item is already inserted
            // TODO find workaround
            if mode != .Add {
                Section("Store Listings") {
                    List(storeItems) { storeItem in
                        Button {
                            sheetCoordinator.presentSheet(.EditStoreItem(item: storeItem))
                        } label: {
                            HStack {
                                Text(mode == .Edit ? storeItem.store.name : "Store").bold()
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(formatter.string(for: storeItem.quantity)!) for \(storeItem.price.toString())")
                                    if !storeItem.available {
                                        Text("(retired)").font(.caption).fontWeight(.thin)
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
                        sheetCoordinator.presentSheet(.AddStoreItem(foodItem: item, storeItems: $storeItems))
                    }
                }
            }
        }.navigationTitle(mode.getTitle())
            .toolbarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheetCoordinating(coordinator: sheetCoordinator)
            .onAppear {
                switch mode {
                case .Confirm, .Edit:
                    name = item.name
                    brand = item.metaData.brand ?? ""
                    details = item.details ?? ""
                    amountUnit = item.size.totalAmount.unit
                    numServings = item.size.numServings
                    servingSize = item.size.servingSize
                    totalAmount = item.size.totalAmount.value.toValue()
                    ingredients = item.ingredients.all
                    allergens = item.ingredients.allergens
                    storeItems = item.storeItems
                default:
                    break
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        path.removeLast()
                    }.disabled(path.isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        item.name = name
                        item.metaData.brand = brand
                        item.details = details.isEmpty ? nil : details
                        item.size = FoodSize(totalAmount: FoodAmount(value: .Raw(totalAmount), unit: amountUnit), numServings: numServings, servingSize: servingSize)
                        item.ingredients.all = ingredients
                        item.ingredients.allergens = allergens
                        switch mode {
                        case .Add, .Confirm:
                            modelContext.insert(item)
                        case .Edit:
                            item.storeItems = storeItems
                        }
                        switch mode {
                        case .Confirm:
                            path.removeAll()
                            path.append(.ItemView(item: item))
                        default:
                            path.removeLast()
                        }
                    }.disabled(path.isEmpty || isMainInfoInvalid() || isSizeInvalid())
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
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        FoodItemEditor(path: .constant([]), item: item)
    }.modelContainer(container)
}
