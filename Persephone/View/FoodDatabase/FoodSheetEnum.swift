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
        case .Nutrients(let f):
            return f.name
        case .NutrientsScale(let f):
            return f.name
        case .AddStoreItem(let i, _):
            return i.name
        case .EditStoreItem(let i):
            return i.foodItem.name
        case .Store(let s):
            return s?.name ?? "store editor"
        }
    }
    
    case General(item: FoodItem)
    case Tags(item: FoodItem)
    case Nutrients(item: FoodItem)
    case NutrientsScale(item: FoodItem)
    case AddStoreItem(foodItem: FoodItem, storeItems: Binding<[StoreItem]>)
    case EditStoreItem(item: StoreItem)
    case Store(store: Store?)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<FoodSheetEnum>) -> some View {
        switch self {
        case .General(let f):
            FoodGeneralSheet(item: f)
        case .Tags(let f):
            FoodTagSheet(item: f)
        case .Nutrients(let f):
            NutrientSheet(item: f)
        case .NutrientsScale(let f):
            NutrientScaleSheet(item: f)
        case .AddStoreItem(let foodItem, let storeItems):
            StoreItemSheet(mode: .Add(foodItem: foodItem, items: storeItems))
        case .EditStoreItem(let item):
            StoreItemSheet(mode: .Edit(item: item))
        case .Store(let s):
            StoreSheet(store: s)
        }
    }
}
