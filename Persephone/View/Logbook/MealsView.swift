//
//  MealsView.swift
//  Persephone
//
//  Created by Zach Wassynger on 4/24/26.
//

import SwiftData
import SwiftUI

struct MealsView: View {
    @Query(sort: \Meal.name) private var meals: [Meal]
    
    @EnvironmentObject var navigationStore: NavigationStore
    
    var body: some View {
        List(meals) { meal in
            Button {
                navigationStore.push(LogViewType.meal(meal))
            } label: {
                Text(meal.name)
            }.buttonStyle(.plain)
        }.navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        navigationStore.push(LogViewType.addMeal)
                    } label: {
                        Label("Add Meal", systemImage: "plus")
                    }
                }
            }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        MealsView()
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
