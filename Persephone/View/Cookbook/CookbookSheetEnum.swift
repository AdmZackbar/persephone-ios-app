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
        case .EditItemIngredient(_):
            "Edit Item Ingredient"
        case .AddIngredient(_):
            "Add Ingredient"
        case .EditIngredient(_):
            "Edit Ingredient"
        case .AddInstructions(_):
            "Add Instructions"
        case .EditInstructions(_):
            "Edit Instructions"
        }
    }
    
    case Tags(tags: Binding<[String]>)
    case AddItemIngredient(recipe: Recipe)
    case EditItemIngredient(ingredient: RecipeIngredient)
    case AddIngredient(recipe: Recipe)
    case EditIngredient(ingredient: RecipeIngredient)
    case AddInstructions(instructions: Binding<[Recipe.Section]>)
    case EditInstructions(section: Recipe.Section)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<CookbookSheetEnum>) -> some View {
        switch self {
        case .Tags(let tags):
            RecipeTagSheet(tags: tags)
        case .AddItemIngredient(let recipe):
            RecipeItemIngredientSheet(recipe: recipe)
        case .EditItemIngredient(let ingredient):
            RecipeItemIngredientSheet(recipe: ingredient.recipe, mode: .Edit(ingredient: ingredient))
        case .AddIngredient(let recipe):
            RecipeIngredientSheet(mode: .Add(recipe: recipe))
        case .EditIngredient(let ingredient):
            RecipeIngredientSheet(mode: .Edit(ingredient: ingredient))
        case .AddInstructions(let instructions):
            RecipeInstructionsSheet(mode: .Add(instructions: instructions))
        case .EditInstructions(let section):
            RecipeInstructionsSheet(mode: .Edit(section: section))
        }
    }
}
