//
//  CookbookSheetEnum.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/4/24.
//

import SwiftUI

enum CookbookSheetEnum: Identifiable, SheetEnum {
    var id: String {
        switch self {
        case .Tags(_):
            "Tag Editor"
        case .AddItemIngredient(_):
            "Add Item Ingredient"
        case .AddIngredient(_):
            "Add Ingredient"
        case .EditIngredient(_):
            "Edit Ingredient"
        }
    }
    
    case Tags(tags: Binding<[String]>)
    case AddItemIngredient(recipe: Recipe)
    case AddIngredient(recipe: Recipe)
    case EditIngredient(ingredient: RecipeIngredient)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<CookbookSheetEnum>) -> some View {
        switch self {
        case .Tags(let tags):
            RecipeTagSheet(tags: tags)
        case .AddItemIngredient(let recipe):
            RecipeItemIngredientSheet(recipe: recipe)
        case .AddIngredient(let recipe):
            RecipeIngredientSheet(mode: .Add(recipe: recipe))
        case .EditIngredient(let ingredient):
            RecipeIngredientSheet(mode: .Edit(ingredient: ingredient))
        }
    }
}
