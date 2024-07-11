//
//  FoodItemView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

private enum ViewType {
    case AllNutrients, Ingredients, Description
}

struct FoodItemView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var item: FoodItem
    @State private var viewType: ViewType = .AllNutrients
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.alwaysShowsDecimalSeparator = false
        return formatter
    }()
    
    private func formatNutrient(nutrient: Nutrient) -> String {
        numberFormatter.string(for: (item.composition.nutrients[nutrient] ?? 0) / 1000.0)!
    }
    
    var body: some View {
        VStack(spacing: 12.0) {
            Grid(horizontalSpacing: 16.0) {
                GridRow {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.storeInfo?.name ?? "Custom")
                            Text("\(currencyFormatter.string(for: Double(item.storeInfo?.price ?? 0) / 100.0)!)")
                                .font(.title).bold()
                            Text("Net Weight: \(numberFormatter.string(for: item.sizeInfo.totalAmount)!)g")
                                .font(.subheadline)
                            Text("\(numberFormatter.string(for: item.sizeInfo.numServings)!) Servings")
                                .font(.subheadline)
                            Text("Serving: \(item.sizeInfo.servingSize) (\(numberFormatter.string(for: item.sizeInfo.servingAmount)!)g)")
                                .font(.caption)
                            Spacer()
                        }
                        Spacer()
                    }.padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Per Serving:")
                            Text("\(numberFormatter.string(for: item.composition.calories)!) Cal")
                                .font(.title).bold()
                            Text("\(formatNutrient(nutrient: .TotalCarbs))g Carbs")
                                .font(.subheadline)
                                .fontWeight(.light)
                            Text("\(formatNutrient(nutrient: .TotalFat))g Fat")
                                .font(.subheadline)
                                .fontWeight(.light)
                            Text("\(formatNutrient(nutrient: .Protein))g Protein")
                                .font(.subheadline)
                                .fontWeight(.light)
                            Spacer()
                        }
                        Spacer()
                    }.padding()
                        .frame(maxWidth: .infinity, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                }
            }.frame(height: 150.0)
            Picker("Test", selection: $viewType) {
                Text("All Nutrients")
                    .tag(ViewType.AllNutrients)
                Text("Description")
                    .tag(ViewType.Description)
                Text("Ingredients")
                    .tag(ViewType.Ingredients)
            }.padding(EdgeInsets(top: 12.0, leading: 0.0, bottom: 0.0, trailing: 0.0)).pickerStyle(.segmented)
            switch (viewType) {
            case .AllNutrients:
                NutrientTable(item: item)
            case .Ingredients:
                VStack(alignment: .leading, spacing: 8.0) {
                    if (item.composition.ingredients.isEmpty && item.composition.allergens.isEmpty) {
                        Text("No ingredients recorded for this food.").padding()
                    } else {
                        if (!item.composition.ingredients.isEmpty) {
                            Text(item.composition.ingredients.joined(separator: ", "))
                                .multilineTextAlignment(.leading)
                        }
                        if (!item.composition.allergens.isEmpty) {
                            Text("Allergens: \(item.composition.allergens.joined(separator: ", "))")
                                .multilineTextAlignment(.leading)
                                .bold()
                        }
                    }
                }.frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12.0))
            case .Description:
                Text(item.metaData.details ?? "No description for this food.")
                    .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
            }
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(item.name).font(.headline)
                    Text(item.metaData.brand ?? "").font(.subheadline)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    FoodItemEditor(item: item)
                } label: {
                    Text("Edit")
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct NutrientTable: View {
    var item: FoodItem
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.alwaysShowsDecimalSeparator = false
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack {
                Grid {
                    createRow(name: "Total Carbohydrates", nutrient: .TotalCarbs)
                        .bold()
                    Divider()
                    createRow(name: "Dietary Fiber", nutrient: .DietaryFiber, indented: true)
                        .font(.subheadline)
                    Divider()
                    createRow(name: "Total Sugars", nutrient: .TotalSugars, indented: true)
                        .font(.subheadline)
                    Divider()
                    createRow(name: "Added Sugars", nutrient: .AddedSugars, indented: true)
                        .font(.subheadline)
                    Divider()
                    createRow(name: "Total Fat", nutrient: .TotalFat)
                        .bold()
                    Divider()
                    createRow(name: "Saturated Fat", nutrient: .SaturatedFat, indented: true)
                        .font(.subheadline)
                    Divider()
                    createRow(name: "Trans Fat", nutrient: .TransFat, indented: true)
                        .font(.subheadline)
                    Divider()
                    createRow(name: "Polyunsaturated Fat", nutrient: .PolyunsaturatedFat, indented: true)
                        .font(.subheadline)
                    Divider()
                    createRow(name: "Monounsaturated Fat", nutrient: .MonounsaturatedFat, indented: true)
                        .font(.subheadline)
                    Divider()
                    createRow(name: "Protein", nutrient: .Protein)
                        .bold()
                    Divider()
                    createRow(name: "Sodium", nutrient: .Sodium, useMg: true)
                        .bold()
                    Divider()
                    createRow(name: "Cholesterol", nutrient: .Cholesterol, useMg: true)
                }
            }
        }.padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
    
    private func formatNutrient(nutrient: Nutrient, useMg: Bool) -> String {
        formatter.string(for: (item.composition.nutrients[nutrient] ?? 0) / (useMg ? 1.0 : 1000.0))!
    }
    
    private func createRow(name: String, nutrient: Nutrient, indented: Bool = false, useMg: Bool = false) -> some View {
        GridRow {
            Text(name).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
            Text("\(formatNutrient(nutrient: nutrient, useMg: useMg)) \(useMg ? "mg" : "g")")
                .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
        }
        .italic(indented)
        .padding(EdgeInsets(top: 0.0, leading: indented ? 8.0 : 0.0, bottom: 0.0, trailing: 0.0))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    let item = FoodItem(name: "Lightly Breaded Chicken Chunks",
                        metaData: FoodMetaData(
                            brand: "Kirkland",
                            details: "Costco's chicken nuggets"),
                        composition: FoodComposition(
                            calories: 120,
                            nutrients: [
                                .TotalCarbs: 4000,
                                .TotalSugars: 1500,
                                .TotalFat: 3000,
                                .SaturatedFat: 1250,
                                .Protein: 13000,
                                .Sodium: 530,
                                .Cholesterol: 25,
                            ],
                            ingredients: ["Salt", "Chicken", "Dunno"],
                        allergens: ["Meat"]),
                        sizeInfo: FoodSizeInfo(
                            numServings: 16,
                            servingSize: "4 oz",
                            totalAmount: 1814,
                            servingAmount: 63,
                            sizeType: .Mass),
                        storeInfo: StoreInfo(name: "Costco", price: 1399))
    return NavigationStack {
        FoodItemView(item: item)
    }.modelContainer(container)
}
