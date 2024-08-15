//
//  LookupFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/14/24.
//

import SwiftData
import SwiftUI

private enum ViewState {
    case GetQuery
    case Querying
    case NoResult
    case ResultList(items: [FoodItem])
    case ConfirmResult(items: [FoodItem], item: FoodItem)
}

struct LookupFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var viewState: ViewState = .GetQuery
    @State private var query: String = ""
    
    var body: some View {
        VStack {
            switch viewState {
            case .GetQuery:
                Form {
                    TextField("query", text: $query)
                    Button("Search", action: onSearch)
                }.navigationTitle("Search Foods")
                    .navigationBarTitleDisplayMode(.inline)
            case .Querying:
                Text("Looking up \(query)...")
            case .NoResult:
                Text("No results found for \(query)")
                    .navigationTitle("Search Results")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") {
                                viewState = .GetQuery
                            }
                        }
                    }
            case .ResultList(let items):
                List(items, id: \.name) { item in
                    Button {
                        viewState = .ConfirmResult(items: items, item: item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                if item.metaData.brand != nil {
                                    Text(item.metaData.brand!).font(.subheadline).italic()
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .opacity(0.5)
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }.navigationTitle("Search Results")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") {
                                viewState = .GetQuery
                            }
                        }
                    }
            case .ConfirmResult(let items, let item):
                ConfirmFoodScanView(items: items, item: item, viewState: $viewState)
            }
        }
    }
    
    private func onSearch() {
        queryEndpoint(query: query) { results in
            if results.isEmpty {
                viewState = .NoResult
            } else if results.count == 1 {
                viewState = .ConfirmResult(items: results, item: results.first!)
            } else {
                viewState = .ResultList(items: results)
            }
        }
    }
    
    private func queryEndpoint(query: String, completion: @escaping ([FoodItem]) -> Void) {
        viewState = .Querying
        Task {
            var results: [FoodItem] = []
            results.append(contentsOf: try await FoodDataCentralEndpoint.lookup(query: query, maxResults: 20))
            completion(results)
        }
    }
}

private struct ConfirmFoodScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    
    let items: [FoodItem]
    let item: FoodItem
    
    @Binding private var viewState: ViewState
    // Name details
    @State private var name: String = ""
    @State private var brand: String = ""
    // Size
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
    // Ingredients
    @State private var ingredients: String = ""
    @State private var allergens: String = ""
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.zeroSymbol = ""
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        Form {
            Section(item.metaData.barcode ?? "unknown barcode") {
                Grid(verticalSpacing: 16) {
                    GridRow {
                        Text("Name:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        TextField("required", text: $name)
                    }
                    GridRow {
                        Text("Brand:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        TextField("optional", text: $brand)
                    }
                    GridRow {
                        Text(amountUnit.isWeight() ? "Net Wt:" : "Net Vol:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
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
                    GridRow {
                        Text("Num Servings:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
                        TextField("required", value: $numServings, formatter: formatter)
                            .keyboardType(.decimalPad)
                    }
                    GridRow {
                        Text("Serving Size:").fontWeight(.light).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
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
                Button("Adjust Values...") {
                    sheetCoordinator.presentSheet(.Nutrients(item: item))
                }
            }
            Section("Ingredients") {
                TextEditor(text: $ingredients)
                    .textInputAutocapitalization(.words)
                    .frame(height: 140)
                HStack {
                    Text("Allergens:")
                    TextField("None", text: $allergens)
                        .textInputAutocapitalization(.words)
                }.bold()
            }
            Section("Tags") {
                Text(item.metaData.tags.isEmpty ? "No tags" : item.metaData.tags.joined(separator: ", "))
                    .italic(item.metaData.tags.isEmpty)
                Button("Edit Tags...") {
                    sheetCoordinator.presentSheet(.Tags(item: item))
                }
            }
            Section("Store Listings") {
                List(item.storeItems) { storeItem in
                    HStack {
                        Text(storeItem.store.name).bold()
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(formatter.string(for: storeItem.quantity)!) for \(currencyFormatter.string(for: Double(storeItem.price.cents) / 100.0)!)")
                            if !storeItem.available {
                                Text("(retired)").font(.caption).fontWeight(.thin)
                            }
                        }
                    }.onTapGesture {
                        sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: storeItem))
                    }.swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            item.storeItems.removeAll(where: { s in s == storeItem })
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
                Button("Add Listing...") {
                    sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: nil))
                }
            }
        }.navigationTitle("Confirm Item Details")
            .toolbarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheetCoordinating(coordinator: sheetCoordinator)
            .onAppear {
                name = item.name
                brand = item.metaData.brand ?? ""
                amountUnit = item.size.totalAmount.unit
                numServings = item.size.numServings
                servingSize = item.size.servingSize
                totalAmount = item.size.totalAmount.value
                ingredients = item.ingredients.all
                allergens = item.ingredients.allergens
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(items.count > 1 ? "Back" : "Cancel") {
                        if items.count > 1 {
                            viewState = .ResultList(items: items)
                        } else {
                            viewState = .GetQuery
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        item.name = name
                        item.metaData.brand = brand
                        item.size = FoodSize(totalAmount: FoodAmount(value: totalAmount, unit: amountUnit), numServings: numServings, servingSize: servingSize)
                        item.ingredients.all = ingredients
                        item.ingredients.allergens = allergens
                        modelContext.insert(item)
                        dismiss()
                    }
                }
            }
    }
    
    private func createAmountUnitOption(_ unit: FoodUnit) -> some View {
        Text(unit.getAbbreviation()).tag(unit).font(.subheadline).fontWeight(.thin)
    }
    
    init(items: [FoodItem], item: FoodItem, viewState: Binding<ViewState>) {
        self.items = items
        self.item = item
        self._viewState = viewState
    }
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        LookupFoodView()
    }.modelContainer(container)
}
