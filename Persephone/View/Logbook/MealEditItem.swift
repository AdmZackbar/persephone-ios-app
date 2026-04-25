//
//  MealEditItem.swift
//  Persephone
//
//  Created by Zach Wassynger on 4/24/26.
//

import Foundation

struct MealEditItem {
    private var meal: Meal?
    var isEdit: Bool {
        meal != nil
    }
    
    var name: String
    var notes: String
    var items: [MealItem]
    
    var isInvalid: Bool {
        name.isEmpty
    }
    
    init(meal: Meal? = nil) {
        self.meal = meal
        self.name = meal?.name ?? ""
        self.notes = meal?.notes ?? ""
        self.items = meal?.items ?? []
    }
    
    mutating func save() -> Meal? {
        if let meal {
            meal.name = name
            meal.notes = notes
            meal.items = items
            return nil
        }
        meal = .init(name: name, notes: notes, items: items)
        return meal
    }
}

struct MealItemEditItem {
    private var item: MealItem?
    var isEdit: Bool {
        item != nil
    }
    
    var food: Food?
    var defaultAmount: Amount
    var servingCost: Currency?
    
    var isInvalid: Bool {
        food == nil || defaultAmount.value.raw <= 0
    }
    
    init(item: MealItem? = nil) {
        self.item = item
        self.food = item?.food
        self.defaultAmount = item?.defaultAmount ?? .init()
        self.servingCost = item?.servingCost
    }
    
    mutating func save() -> MealItem? {
        if let item {
            item.food = food
            item.defaultAmount = defaultAmount
            item.servingCost = servingCost
            return nil
        }
        item = .init(food: food, defaultAmount: defaultAmount, servingCost: servingCost)
        return item
    }
}
