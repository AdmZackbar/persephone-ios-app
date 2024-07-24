//
//  FoodItemView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

private enum ViewType {
    case AllNutrients, Ingredients
}

private let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 2
    return formatter
}()

private let gramFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.alwaysShowsDecimalSeparator = false
    return formatter
}()

private func format(item: FoodItem, nutrient: Nutrient) -> String {
    gramFormatter.string(for: item.ingredients.nutrients[nutrient]?.value ?? 0)!
}

struct FoodItemView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var item: FoodItem
    @State private var viewType: ViewType = .AllNutrients
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12.0) {
                Grid(horizontalSpacing: 16.0) {
                    GridRow {
                        StoreInfoView(item: item)
                        NutritionView(item: item)
                    }
                }.frame(height: 150.0)
                Picker("Test", selection: $viewType) {
                    Text("All Nutrients")
                        .tag(ViewType.AllNutrients)
                    Text("Ingredients")
                        .tag(ViewType.Ingredients)
                }.padding(EdgeInsets(top: 12.0, leading: 0.0, bottom: 0.0, trailing: 0.0)).pickerStyle(.segmented)
                switch (viewType) {
                case .AllNutrients:
                    NutrientTable(item: item)
                case .Ingredients:
                    VStack(alignment: .leading, spacing: 8.0) {
                        if (item.ingredients.all.isEmpty && item.ingredients.allergens.isEmpty) {
                            Text("No ingredients recorded for this food.").padding()
                        } else {
                            if (!item.ingredients.all.isEmpty) {
                                Text(item.ingredients.all)
                                    .multilineTextAlignment(.leading)
                            }
                            if (!item.ingredients.allergens.isEmpty) {
                                Text("Allergens: \(item.ingredients.allergens)")
                                    .multilineTextAlignment(.leading)
                                    .bold()
                            }
                        }
                    }.frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BackgroundColor"))
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
        }.background(Color(UIColor.secondarySystemBackground))
    }
}

private struct StoreInfoView: View {
    var item: FoodItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
//                Text(item.storeInfo?.name ?? "Custom")
//                Text("\(currencyFormatter.string(for: Double(item.storeInfo?.price ?? 0) / 100.0)!)")
//                    .font(.title).bold()
//                Text(item.sizeInfo.sizeType == .Mass ? "Net Wt. \(formatWeight(item.sizeInfo.totalAmount))" : "Net Vol. \(formatVolume(item.sizeInfo.totalAmount))")
//                    .font(.subheadline)
                Text("\(gramFormatter.string(for: item.size.numServings)!) Servings")
                    .font(.subheadline)
                Text("\(item.size.servingSize) (\(gramFormatter.string(for: item.size.servingAmount.value)!)g)")
                    .font(.subheadline)
                Spacer()
            }
            Spacer()
        }.padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if (volume > 500.0) {
            return "\(gramFormatter.string(for: volume / 1000.0)!)L"
        }
        return "\(gramFormatter.string(for: volume)!)mL"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if (weight > 500.0) {
            return "\(gramFormatter.string(for: weight / 1000.0)!)kg"
        }
        return "\(gramFormatter.string(for: weight)!)g"
    }
}

private struct NutritionView: View {
    var item: FoodItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Per Serving")
                Text("\(gramFormatter.string(for: item.ingredients.nutrients[.Energy]?.value ?? 0)!) Cal")
                    .font(.title).bold()
                Text("\(format(item: item, nutrient: .TotalFat))g Fat")
                    .font(.subheadline)
                    .fontWeight(.light)
                Text("\(format(item: item, nutrient: .TotalCarbs))g Carbs")
                    .font(.subheadline)
                    .fontWeight(.light)
                Text("\(format(item: item, nutrient: .Protein))g Protein")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
            }
            Spacer()
        }.padding()
            .frame(maxWidth: .infinity, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            .background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }
}

private struct NutrientTable: View {
    var item: FoodItem
    
    var body: some View {
        VStack {
            Grid {
                createRow(name: "Calories", nutrient: .Energy)
                    .bold()
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
                createRow(name: "Cholesterol", nutrient: .Cholesterol)
                    .bold()
                Divider()
                createRow(name: "Sodium", nutrient: .Sodium)
                    .bold()
                Divider()
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
                createRow(name: "Protein", nutrient: .Protein)
                    .bold()
            }.padding()
                .background(Color("BackgroundColor"))
                .clipShape(RoundedRectangle(cornerRadius: 12.0))
            Grid {
                createRow(name: "Vitamin D", nutrient: .VitaminD)
                Divider()
                createRow(name: "Calcium", nutrient: .Calcium)
                Divider()
                createRow(name: "Iron", nutrient: .Iron)
                Divider()
                createRow(name: "Potassium", nutrient: .Potassium)
            }.padding()
                .background(Color("BackgroundColor"))
                .clipShape(RoundedRectangle(cornerRadius: 12.0))
        }
    }
    
    private func createRow(name: String, nutrient: Nutrient, indented: Bool = false) -> some View {
        GridRow {
            Text(name).gridCellAnchor(UnitPoint(x: 0, y: 0.5))
            if (nutrient == .Energy) {
                Text(format(item: item, nutrient: nutrient))
                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
            } else {
                Text("\(format(item: item, nutrient: nutrient)) \(nutrient.getCommonUnit().getAbbreviation())")
                    .gridCellAnchor(UnitPoint(x: 1, y: 0.5))
            }
        }
        .italic(indented)
        .padding(EdgeInsets(top: 0.0, leading: indented ? 8.0 : 0.0, bottom: 0.0, trailing: 0.0))
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return NavigationStack {
        FoodItemView(item: item)
    }.modelContainer(container)
}
