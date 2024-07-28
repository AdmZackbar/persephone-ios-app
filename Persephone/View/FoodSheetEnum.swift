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
        case .Tags(let f):
            return f.name
        case .Nutrients(let f):
            return f.name
        case .StoreItem(_, let i):
            return i?.store.name ?? "item editor"
        case .Store(let s):
            return s?.name ?? "store editor"
        }
    }
    
    case Tags(item: FoodItem)
    case Nutrients(item: FoodItem)
    case StoreItem(foodItem: FoodItem, item: StoreItem?)
    case Store(store: Store?)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<FoodSheetEnum>) -> some View {
        switch self {
        case .Tags(let f):
            FoodTagSheet(item: f)
        case .Nutrients(let f):
            NutrientSheet(item: f)
        case .StoreItem(let f, let i):
            StoreItemSheet(foodItem: f, item: i)
        case .Store(let s):
            StoreSheet(store: s)
        }
    }
}
