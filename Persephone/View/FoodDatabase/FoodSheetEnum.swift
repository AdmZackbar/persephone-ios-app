//
//  FoodSheetEnum.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/28/24.
//

import SwiftUI

enum FoodSheetEnum: Identifiable, SheetEnum {
    var id: Int {
        switch self {
        case .General(let f):
            return f.hashValue
        case .Tags(_):
            return "Edit Tags".hashValue
        case .ServingAmount(_, _):
            return "Serving Amount".hashValue
        case .Nutrients(_):
            return "Nutrient Editor".hashValue
        case .NutrientsScale(let f):
            return f.hashValue
        case .AddStoreItem(_):
            return "Add Store Item".hashValue
        case .EditStoreItem(let i):
            return i.wrappedValue.hashValue
        }
    }
    
    case General(item: FoodItem)
    case Tags(tags: Binding<[String]>)
    case ServingAmount(totalAmount: Binding<Double>, numServings: Binding<Double>)
    case Nutrients(nutrients: Binding<NutritionDict>)
    case NutrientsScale(item: FoodItem)
    case AddStoreItem(storeItems: Binding<[FoodItem.StoreEntry]>)
    case EditStoreItem(item: Binding<FoodItem.StoreEntry>)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<FoodSheetEnum>) -> some View {
        switch self {
        case .General(let f):
            FoodGeneralSheet(item: f)
        case .Tags(let tags):
            FoodTagSheet(tags: tags)
        case .ServingAmount(let totalAmount, let numServings):
            ServingAmountSheet(totalAmount: totalAmount, numServings: numServings)
        case .Nutrients(let n):
            NutrientSheet(nutrients: n)
        case .NutrientsScale(let f):
            NutrientScaleSheet(item: f)
        case .AddStoreItem(let storeItems):
            StoreItemSheet(mode: .Add(items: storeItems))
        case .EditStoreItem(let item):
            StoreItemSheet(mode: .Edit(item: item))
        }
    }
}
