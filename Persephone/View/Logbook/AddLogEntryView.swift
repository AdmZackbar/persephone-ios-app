//
//  AddLogEntryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

import SwiftUI

struct AddLogEntryView: View {
    let date: Date
    let meal: String
    
    @State private var viewType: ViewType = .food
    
    init(date: Date, meal: String) {
        self.date = date
        self.meal = meal
    }
    
    var body: some View {
        mainView()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $viewType) {
                        ForEach(ViewType.allCases, id: \.hashValue) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }.pickerStyle(.segmented)
                        .frame(width: 160)
                }
            }
    }
    
    @ViewBuilder
    private func mainView() -> some View {
        switch viewType {
        case .food:
            FoodLogEntryEditView(item: .init(date: date, meal: meal))
        case .recipe:
            RecipeLogEntryEditView(item: .init(date: date, meal: meal))
        }
    }
    
    private enum ViewType: String, CaseIterable {
        case food
        case recipe
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        AddLogEntryView(date: .now, meal: "Breakfast")
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
