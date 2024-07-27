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
        VStack(spacing: 16) {
            Grid(horizontalSpacing: 16) {
                GridRow {
                    SizeTabView(item: item)
                    NutritionTabView(item: item)
                }
            }.frame(height: 160)
            MainTabView(sheetCoordinator: sheetCoordinator, item: item)
        }.navigationBarTitleDisplayMode(.inline)
            .padding()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if item.metaData.brand != nil {
                        VStack {
                            Text(item.name).font(.headline)
                            Text(item.metaData.brand ?? "").font(.subheadline)
                        }
                    } else {
                        Text(item.name).font(.headline)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            sheetCoordinator.presentSheet(.Nutrients(item: item))
                        } label: {
                            Label("Nutrition", systemImage: "tablecells")
                        }
                        Menu("Store Listings") {
                            ForEach(item.storeItems, id: \.store?.name) { storeItem in
                                Button(storeItem.store.name) {
                                    sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: storeItem))
                                }
                            }
                            Button {
                                sheetCoordinator.presentSheet(.StoreItem(foodItem: item, item: nil))
                            } label: {
                                Label("Add Listing", systemImage: "plus")
                            }
                        }
                    } label: {
                        Label("Edit", systemImage: "pencil").labelStyle(.titleOnly)
                    }
                }
            }.background(Color(UIColor.secondarySystemBackground))
                .sheetCoordinating(coordinator: sheetCoordinator)
    }
}

private struct StoreInfoView: View {
    var item: FoodItem
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let storeItem = item.storeItems.first {
                    Text(storeItem.store.name)
                    Text("\(currencyFormatter.string(for: Double(storeItem.price.cents) / Double(storeItem.quantity) / 100.0)!)")
                        .font(.title).bold()
                }
                Text(item.size.totalAmount.unit.isWeight() ? "Net Wt. \(formatWeight(item.size.totalAmount.value))" : "Net Vol. \(formatVolume(item.size.totalAmount.value))")
                    .font(.subheadline)
                Text("\(formatter.string(for: item.size.numServings)!) Servings")
                    .font(.subheadline)
                Text("\(item.size.servingSize) (\(formatter.string(for: item.size.servingAmount.value)!)g)")
                    .font(.subheadline)
                Spacer()
            }
            Spacer()
        }.padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if (volume > 500) {
            return "\(formatter.string(for: volume / 1000)!)L"
        }
        return "\(formatter.string(for: volume)!)mL"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if (weight > 500) {
            return "\(formatter.string(for: weight / 1000)!)kg"
        }
        return "\(formatter.string(for: weight)!)g"
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
    private enum ViewType {
        case Main, Macro
    }
    
    var item: FoodItem
    
    // selection currently breaks page indicator, so don't impl that for now
    
    var body: some View {
        TabView {
            ScrollView(.vertical) {
                NutritionView(item: item, header: item.size.servingSize, modifier: 1)
                    .frame(height: 126)
                NutritionView(item: item, header: "Whole Container", modifier: item.size.numServings)
                    .frame(height: 134)
            }.tag(ViewType.Main).scrollTargetBehavior(.paging)
                .padding(12)
            MacroChartView(item: item).tag(ViewType.Macro)
                .padding(12)
        }.tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .background(Color("BackgroundColor"))
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
                    .font(.title).bold()
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
            return "\(formatter.string(for: (item.getNutrient(.Energy)?.value ?? 0) * modifier)!) Cal"
        }
        let amount = try? item.getNutrient(nutrient)?.toGrams()
        return "\(formatter.string(for: (amount?.value ?? 0) * modifier)!)g"
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
        return (try? item.getNutrient(nutrient)?.toGrams())?.value ?? 0
    }
}

private struct MainTabView: View {
    private enum ViewType {
        case Nutrients, Ingredients, Description
    }
    
    @ObservedObject var sheetCoordinator: SheetCoordinator<FoodSheetEnum>
    
    var item: FoodItem
    
    @State private var viewType: ViewType = .Nutrients
    
    var body: some View {
        TabView(selection: $viewType) {
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
            }.tag(ViewType.Description).padding()
            ScrollView(.vertical) {
                NutrientTableView(nutrients: item.ingredients.nutrients)
                    .contextMenu {
                        Button {
                            sheetCoordinator.presentSheet(.Nutrients(item: item))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }.padding()
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
                }.tag(ViewType.Ingredients).padding()
            }
        }.tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            .background(Color("BackgroundColor"))
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
