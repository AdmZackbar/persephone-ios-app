//
//  FoodItemView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import Charts
import SwiftData
import SwiftUI

private let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    return formatter
}()

struct FoodItemView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    
    var item: FoodItem
    
    var body: some View {
        VStack(spacing: 12) {
            if !(item.metaData.brand ?? "").isEmpty || !item.metaData.tags.isEmpty {
                HStack {
                    if !(item.metaData.brand ?? "").isEmpty {
                        Text(item.metaData.brand!).font(.subheadline).fontWeight(.semibold)
                    }
                    Spacer()
                    if !item.metaData.tags.isEmpty {
                        Label {
                            Text(item.metaData.tags.joined(separator: ", ")).font(.subheadline).italic()
                        } icon: {
                            Image(systemName: "tag.fill").font(.system(size: 12))
                        }.labelStyle(.titleAndIcon)
                    }
                }
            }
            Grid(horizontalSpacing: 12) {
                GridRow {
                    SizeTabView(item: item)
                    NutritionTabView(item: item)
                }
            }.frame(height: 140)
            if !item.storeItems.isEmpty {
                StoreItemsTabView(storeItems: item.storeItems.sorted(by: { x, y in
                    let unitX = Double(x.price.cents) / Double(x.quantity)
                    let unitY = Double(y.price.cents) / Double(y.quantity)
                    return unitX < unitY
                })).frame(height: 112)
            }
            MainTabView(sheetCoordinator: sheetCoordinator, item: item)
        }.navigationBarTitleDisplayMode(.inline)
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 12, trailing: 12))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(item.name).font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: .infinity)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            sheetCoordinator.presentSheet(.General(item: item))
                        } label: {
                            Label("General", systemImage: "pencil")
                        }
                        Menu {
                            ForEach(item.storeItems.sorted(by: { x, y in x.store.name < y.store.name }), id: \.store.name) { storeItem in
                                Button(storeItem.store.name) {
                                    sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: storeItem))
                                }
                            }
                            Button {
                                sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: nil))
                            } label: {
                                Label("Add Listing", systemImage: "plus")
                            }
                        } label: {
                            Label("Store Listings", systemImage: "storefront")
                        }
                        Button {
                            sheetCoordinator.presentSheet(.Nutrients(item: item))
                        } label: {
                            Label("Nutrition", systemImage: "tablecells")
                        }
                        Button {
                            sheetCoordinator.presentSheet(.Tags(item: item))
                        } label: {
                            Label("Tags", systemImage: "tag")
                        }
                    } label: {
                        Label("Edit", systemImage: "pencil").labelStyle(.titleOnly)
                    }
                }
            }.background(Color(UIColor.secondarySystemBackground))
                .sheetCoordinating(coordinator: sheetCoordinator)
    }
}

private struct StoreItemsTabView: View {
    @State private var tabSelection: String
    
    var storeItems: [StoreItem]
    
    init(storeItems: [StoreItem]) {
        self.tabSelection = storeItems.first!.store.name
        self.storeItems = storeItems
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $tabSelection) {
                ForEach(storeItems) { storeItem in
                    HStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(storeItem.store.name).font(.title2).bold()
                            Text("\(storeItem.quantity) for \(currencyFormatter.string(for: Double(storeItem.price.cents) / 100)!)")
                            Text(storeItem.available ? "Available" : "Retired").font(.subheadline).italic()
                            Spacer()
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text(computeCostPerUnit(storeItem)).bold()
                            Text("per Unit").font(.caption).fontWeight(.light)
                            Spacer()
                            Text(computeCostPerServing(storeItem)).bold()
                            Text("per Serving").font(.caption).fontWeight(.light)
                        }
                        VStack(alignment: .leading) {
                            if storeItem.foodItem.getNutrient(.Energy)?.value.toValue() ?? 0 != 0 {
                                Text(computeCostPerCalories(storeItem)).bold()
                                Text("per 100 cal").font(.caption).fontWeight(.light)
                                Spacer()
                            }
                            Text(computeCostPerUnitTotal(storeItem)).bold()
                            Text("per 100 \(storeItem.foodItem.size.totalAmount.unit.getAbbreviation())").font(.caption).fontWeight(.light)
                        }
                    }.padding(12).tag(storeItem.store.name)
                }
            }.frame(maxWidth: .infinity)
                .tabViewStyle(.page(indexDisplayMode: .never))
            // Tab indicators (only need to show if there's more than 1 listing
            if storeItems.count > 1 {
                HStack {
                    HStack(spacing: 6) {
                        ForEach(storeItems) { storeItem in
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(tabSelection == storeItem.store.name ? Color.accentColor : .gray)
                        }
                    }
                    Spacer()
                }.padding(EdgeInsets(top: 0, leading: 12, bottom: 8, trailing: 0))
            }
        }.background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func computeUnitCost(_ storeItem: StoreItem) -> Double {
        Double(storeItem.price.cents) / 100 / Double(storeItem.quantity)
    }
    
    private func computeCostPerUnit(_ storeItem: StoreItem) -> String {
        currencyFormatter.string(for: computeUnitCost(storeItem))!
    }
    
    private func computeCostPerServing(_ storeItem: StoreItem) -> String {
        currencyFormatter.string(for: computeUnitCost(storeItem) / storeItem.foodItem.size.numServings)!
    }
    
    private func computeCostPerCalories(_ storeItem: StoreItem) -> String {
        let caloriesPerServing = storeItem.foodItem.getNutrient(.Energy)!.value.toValue()
        let totalCal = storeItem.foodItem.size.numServings * caloriesPerServing
        return currencyFormatter.string(for: computeUnitCost(storeItem) / (totalCal / 100))!
    }
    
    private func computeCostPerUnitTotal(_ storeItem: StoreItem) -> String {
        currencyFormatter.string(for: computeUnitCost(storeItem) / storeItem.foodItem.size.totalAmount.value.toValue() * 100)!
    }
}

private struct SizeTabView: View {
    var item: FoodItem
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Serving Size").font(.subheadline)
                Text(item.size.servingSize).font(.title2).bold()
                Text("\(formatter.string(for: item.size.servingAmount.value)!)\(item.size.servingAmount.unit.getAbbreviation())").fontWeight(.light)
                Spacer()
                Text("\(formatter.string(for: item.size.numServings)!) servings").lineLimit(1)
                Text("Net \(item.size.totalAmount.unit.isWeight() ? "Wt" : "Vol"): \(formatter.string(for: item.size.totalAmount.value)!)\(item.size.totalAmount.unit.getAbbreviation())").font(.subheadline).fontWeight(.light).lineLimit(1)
                
            }
            Spacer()
        }.padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct NutritionTabView: View {
    private enum ViewType: String, Identifiable, CaseIterable, Equatable, Hashable {
        var id: String {
            rawValue
        }
        
        case Main, Macro
    }
    
    var item: FoodItem
    
    @State private var tabSelection: ViewType = .Main
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $tabSelection) {
                ScrollView(.vertical) {
                    NutritionView(item: item, header: item.size.servingSize, modifier: 1)
                        .frame(height: 120)
                    NutritionView(item: item, header: "Whole Container", modifier: item.size.numServings)
                        .frame(height: 116)
                }.scrollTargetBehavior(.paging)
                    .padding(12)
                    .tag(ViewType.Main)
                MacroChartView(item: item)
                    .padding(12)
                    .tag(ViewType.Macro)
            }.tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity)
            // Tab indicators
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(ViewType.allCases) { type in
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(tabSelection == type ? Color.accentColor : .gray)
                    }
                }
            }.padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 12))
        }.background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct NutritionView: View {
    var item: FoodItem
    var header: String
    var modifier: Double
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(header).font(.subheadline)
                Text(format(.Energy))
                    .font(.title2).bold()
                Text("\(format(.TotalFat)) Fat")
                    .font(.subheadline)
                    .fontWeight(.light)
                Text("\(format(.TotalCarbs)) Carbs")
                    .font(.subheadline)
                    .fontWeight(.light)
                Text("\(format(.Protein)) Protein")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
            }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func format(_ nutrient: Nutrient) -> String {
        if nutrient == .Energy {
            return "\(formatter.string(for: (item.getNutrient(.Energy)?.value.toValue() ?? 0) * modifier)!) Cal"
        }
        let amount = try? item.getNutrient(nutrient)?.toGrams()
        return "\(formatter.string(for: (amount?.value.toValue() ?? 0) * modifier)!)g"
    }
}

private struct MacroChartView: View {
    var item: FoodItem
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        let data = createData(item)
        return ZStack {
            Chart(data, id: \.name) { name, amount in
                SectorMark(
                    angle: .value("Amount", amount),
                    innerRadius: .ratio(0.65),
                    outerRadius: .inset(8),
                    angularInset: 2
                ).cornerRadius(4)
                    .foregroundStyle(by: .value("Macro type", name))
            }.chartLegend(.hidden)
                .chartForegroundStyleScale([
                    "Carbs": Color.green,
                    "Fat": Color.orange,
                    "Protein": Color.purple,
                    "None": Color.gray
                ])
            VStack(spacing: 2) {
                Text(formatter.string(for: item.getNutrient(.Energy)?.value ?? 0)!).font(.title3).fontWeight(.heavy)
                Text("Cal").font(.caption).bold()
            }
            VStack(spacing: 0) {
                HStack {
                    Text("Protein").font(.caption).fontWeight(.heavy).foregroundStyle(.purple)
                    Spacer()
                }
                HStack {
                    Text("\(formatter.string(for: computeAmount(.Protein))!)g").font(.caption).bold().foregroundStyle(.purple)
                    Spacer()
                }
                Spacer()
            }
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Carbs").font(.caption).fontWeight(.heavy).foregroundStyle(.green)
                }
                HStack {
                    Spacer()
                    Text("\(formatter.string(for: computeAmount(.TotalCarbs))!)g").font(.caption).bold().foregroundStyle(.green)
                }
                Spacer()
            }
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Text("Fat").font(.caption).fontWeight(.heavy).foregroundStyle(.orange)
                    Spacer()
                }
                HStack {
                    Text("\(formatter.string(for: computeAmount(.TotalFat))!)g").font(.caption).bold().foregroundStyle(.orange)
                    Spacer()
                }
            }
        }
    }
    
    private func createData(_ item: FoodItem) -> [(name: String, amount: Double)] {
        let data = [
            (name: "Carbs", amount: computeAmount(.TotalCarbs) * 4),
            (name: "Fat", amount: computeAmount(.TotalFat) * 9),
            (name: "Protein", amount: computeAmount(.Protein) * 4)
        ]
        if data.allSatisfy({ (name: String, amount: Double) in amount <= 0 }) {
            return [(name: "None", amount: 1)]
        }
        return data
    }
    
    private func computeAmount(_ nutrient: Nutrient) -> Double {
        return (try? item.getNutrient(nutrient)?.toGrams())?.value.toValue() ?? 0
    }
}

private struct MainTabView: View {
    private enum ViewType: String, Identifiable, CaseIterable, Equatable, Hashable {
        var id: String {
            rawValue
        }
        
        case Description, Nutrients, Ingredients
    }
    
    @ObservedObject var sheetCoordinator: SheetCoordinator<FoodSheetEnum>
    
    var item: FoodItem
    
    @State private var tabSelection: ViewType = .Description
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $tabSelection) {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description").font(.title2).bold()
                        Text(item.details ?? "No description set.").multilineTextAlignment(.leading)
                        Spacer(minLength: 20)
                        Text("Barcode: \(item.metaData.barcode ?? "None")").font(.caption)
                        Text("Created On: \(item.metaData.timestamp.formatted(date: .abbreviated, time: .standard))").font(.caption)
                        // Expands to fill horizontally
                        HStack {
                            Spacer()
                        }
                    }
                }.padding(12).tag(ViewType.Description)
                ScrollView(.vertical) {
                    NutrientTableView(nutrients: item.ingredients.nutrients)
                        .contextMenu {
                            Button {
                                sheetCoordinator.presentSheet(.Nutrients(item: item))
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                        }.padding(12)
                }.tag(ViewType.Nutrients)
                if !item.ingredients.all.isEmpty || !item.ingredients.allergens.isEmpty {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ingredients").font(.title2).bold()
                            Text(item.ingredients.all.isEmpty ? "No known ingredients" : item.ingredients.all)
                                .multilineTextAlignment(.leading)
                            Text("Allergens: \(item.ingredients.allergens.isEmpty ? "None" : item.ingredients.allergens)")
                                .multilineTextAlignment(.leading)
                                .bold()
                            // Expands to fill horizontally
                            HStack {
                                Spacer()
                            }
                        }
                    }.padding(12)
                        .tag(ViewType.Ingredients)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity)
            // Tab indicators
            HStack(spacing: 6) {
                ForEach(ViewType.allCases) { type in
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(tabSelection == type ? Color.accentColor : .gray)
                }
            }.padding(.bottom, 6)
        }.background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        FoodItemView(item: item)
    }.modelContainer(container)
}
