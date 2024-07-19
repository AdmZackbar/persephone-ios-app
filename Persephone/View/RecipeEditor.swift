//
//  RecipeEditor.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/16/24.
//

import SwiftUI

struct RecipeEditor: View {
    var recipe: Recipe?
    
    @State private var ingredients: [FoodItem] = []
    @State private var steps: [String] = []
    @State private var viewType: ViewType = .Instructions
    @State private var totalTime: Double = 0.0
    @State private var prepTime: Double = 0.0
    @State private var cookTime: Double = 0.0
    
    private enum ViewType {
        case Instructions, Times, Sizing
    }
    
    let durationFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    var body: some View {
        Form {
            Section("Ingredients") {
                List(ingredients) { ingredient in
                    Text(ingredient.name)
                }
                Button("Add Ingredient") {
                    
                }
            }
            Picker("", selection: $viewType) {
                Text("Instructions").tag(ViewType.Instructions)
                Text("Times").tag(ViewType.Times)
                Text("Sizing").tag(ViewType.Sizing)
            }.pickerStyle(.segmented)
            switch viewType {
            case .Instructions:
                List(steps, id: \.self) { step in
                    Text(step)
                }
                Button("Add Step") {
                    
                }
            case .Times:
                VStack {
                    HStack {
                        Text("Prep Time:")
                        TextField("minutes", value: $prepTime, formatter: durationFormatter)
                            .multilineTextAlignment(.trailing)
                        if (prepTime > 0.0) {
                            Text("minutes")
                        }
                    }
                    Divider()
                    HStack {
                        Text("Cook Time:")
                        TextField("minutes", value: $cookTime, formatter: durationFormatter)
                            .multilineTextAlignment(.trailing)
                        if (cookTime > 0.0) {
                            Text("minutes")
                        }
                    }
                    Divider()
                    HStack {
                        Text("Total Time:")
                        TextField("minutes", value: $totalTime, formatter: durationFormatter)
                            .multilineTextAlignment(.trailing)
                        if (totalTime > 0.0) {
                            Text("minutes")
                        }
                    }
                }
            case .Sizing:
                Text("Sizing")
            }
        }.navigationTitle(recipe != nil ? "Edit Recipe" : "Create Recipe")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RecipeEditor()
    }
}
