//
//  NavigationStore.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import SwiftUI

@MainActor
final class NavigationStore: ObservableObject {
    @Published var path = NavigationPath()
    @Published var logConfig = LogConfig()
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func encoded() -> Data? {
        try? path.codable.map(encoder.encode)
    }
    
    func restore(from data: Data) {
        do {
            let codable = try decoder.decode(
                NavigationPath.CodableRepresentation.self, from: data
            )
            path = NavigationPath(codable)
        } catch {
            path = NavigationPath()
        }
    }
    
    func push(_ value: any Hashable) {
        path.append(value)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func replace(_ value: any Hashable) {
        pop()
        push(value)
    }
    
    @ViewBuilder
    func getFoodDbView(_ type: FoodDatabaseView.ViewType) -> some View {
        switch type {
        case .ItemsView(let type):
            ItemsView(foodType: type)
        case .ItemView(let item):
            FoodItemView(item: item)
        case .ItemAdd:
            FoodItemEditor()
        case .ItemEdit(let item):
            FoodItemEditor(item: item)
        case .ItemConfirm(let item):
            FoodItemEditor(item: item, mode: .Confirm)
        case .CommercialFoodView(let food):
            CommercialFoodView(food: food)
        case .CommercialFoodAdd:
            CommercialFoodEditor()
        case .CommercialFoodEdit(let food):
            CommercialFoodEditor(food: food)
        case .ScanItem:
            ScanFoodView()
        case .LookupItem:
            LookupFoodView()
        case .ExportItems(let items):
            FoodDatabaseExportView(foodItems: items)
        }
    }
    
    @ViewBuilder
    func getCookbookView(_ type: CookbookView.ViewType) -> some View {
        switch type {
        case .viewRecipe(let recipe):
            RecipeView(recipe: recipe)
        case .addRecipe:
            RecipeEditor()
        case .editRecipe(let recipe):
            RecipeEditor(recipe: recipe)
        }
    }
    
    @ViewBuilder
    func getInventoryView(_ type: InventoryView.ViewType) -> some View {
        switch type {
        case .AddItem:
            AddFoodInstanceView()
        case .InstanceView(let item):
            InventoryFoodView(item: item)
        case .viewCookedFood(let food):
            CookedFoodView(cookedFood: food)
        case .addCookedFood:
            CookedFoodEditView(item: .init())
        case .editCookedFood(let food):
            CookedFoodEditView(item: .init(cookedFood: food))
        }
    }
    
    @ViewBuilder
    func getLogbookView(_ type: LogbookView.ViewType) -> some View {
        switch type {
        case .entries:
            LogCategoryView()
        case .addFoodItem(let category):
            LogFoodItemEntryEditView(item: .init(date: logConfig.date, category: category ?? logConfig.selectedCategory ?? "Other"))
        case .editFoodItem(let entry):
            LogFoodItemEntryEditView(item: .init(entry: entry))
        }
    }
}

extension View {
    func handleDestinations(_ navigationStore: NavigationStore) -> some View {
        self.navigationDestination(for: FoodDatabaseView.ViewType.self, destination: navigationStore.getFoodDbView)
            .navigationDestination(for: CookbookView.ViewType.self, destination: navigationStore.getCookbookView)
            .navigationDestination(for: InventoryView.ViewType.self, destination: navigationStore.getInventoryView)
            .navigationDestination(for: LogbookView.ViewType.self, destination: navigationStore.getLogbookView)
    }
}

struct LogConfig: Hashable, Equatable {
    var date: Date = Date()
    var selectedCategory: String? = nil
    
    func contains(_ date: Date) -> Bool {
        self.date.day == date.day
    }
    
    mutating func prev() {
        date = .from(year: date.year, month: date.month, day: date.day - 1)
    }
    
    mutating func next() {
        date = .from(year: date.year, month: date.month, day: date.day + 1)
    }
}
