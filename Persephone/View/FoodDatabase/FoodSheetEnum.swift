//
//  FoodSheetEnum.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/28/24.
//

import SwiftUI

enum FoodSheetEnum: Identifiable, SheetEnum {
    var id: String {
        switch self {
        case .General(let f):
            return f.name
        case .Tags(let f):
            return f.name
        case .ServingAmount(_, _):
            return "Serving Amount"
        case .Nutrients(let f):
            return f.name
        case .NutrientsScale(let f):
            return f.name
        case .AddStoreItem(_):
            return "Add Store Item"
        case .EditStoreItem(let i):
            return i.storeName
        }
    }
    
    case General(item: FoodItem)
    case Tags(item: FoodItem)
    case ServingAmount(totalAmount: Binding<Double>, numServings: Binding<Double>)
    case Nutrients(item: FoodItem)
    case NutrientsScale(item: FoodItem)
    case AddStoreItem(storeItems: Binding<[FoodItem.StoreEntry]>)
    case EditStoreItem(item: FoodItem.StoreEntry)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<FoodSheetEnum>) -> some View {
        switch self {
        case .General(let f):
            FoodGeneralSheet(item: f)
        case .Tags(let f):
            FoodTagSheet(item: f)
        case .ServingAmount(let totalAmount, let numServings):
            ServingAmountSheet(totalAmount: totalAmount, numServings: numServings)
        case .Nutrients(let f):
            NutrientSheet(item: f)
        case .NutrientsScale(let f):
            NutrientScaleSheet(item: f)
        case .AddStoreItem(let storeItems):
            StoreItemSheet(mode: .Add(items: storeItems))
        case .EditStoreItem(let item):
            StoreItemSheet(mode: .Edit(item: item))
        }
    }
}
