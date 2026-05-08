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
    func getFoodView(_ type: FoodViewType) -> some View {
        switch type {
        case .viewFood(let food):
            FoodView(food: food)
        case .addFood:
            FoodEditView()
        case .editFood(let food):
            FoodEditView(item: .init(entry: food))
        }
    }
    
    @ViewBuilder
    func getLogView(_ type: LogViewType) -> some View {
        switch type {
        case .add(let date):
            AddLogEntryView(date: date, mealType: "Snacks")
        case .edit(let entry):
            LogEntryEditView(item: .init(entry: entry))
        case .meals:
            MealsView()
        case .meal(let meal):
            MealView(meal: meal)
        case .addMeal:
            MealEditView()
        case .editMeal(let meal):
            MealEditView(meal: .init(meal: meal))
        }
    }
    
    @ViewBuilder
    func getCookbookView(_ type: CookbookViewType) -> some View {
        switch type {
        case .viewEntry(let entry):
            RecipeEntryView(entry: entry)
        case .addEntry:
            RecipeEntryEditView()
        case .editEntry(let entry):
            RecipeEntryEditView(item: .init(entry: entry))
        }
    }
}

extension View {
    func handleDestinations(_ navigationStore: NavigationStore) -> some View {
        self.navigationDestination(for: FoodViewType.self, destination: navigationStore.getFoodView)
            .navigationDestination(for: LogViewType.self, destination: navigationStore.getLogView)
            .navigationDestination(for: CookbookViewType.self, destination: navigationStore.getCookbookView)
    }
}
