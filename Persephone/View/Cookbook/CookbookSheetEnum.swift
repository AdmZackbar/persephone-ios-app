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
        case .Ingredients(_):
            "Ingredient Editor"
        }
    }
    
    case Tags(tags: Binding<[String]>)
    case Ingredients(ingredient: RecipeIngredient?)
    
    @ViewBuilder
    func view(coordinator: SheetCoordinator<CookbookSheetEnum>) -> some View {
        switch self {
        case .Tags(let tags):
            RecipeTagSheet(tags: tags)
        case .Ingredients(let ingredient):
            RecipeIngredientSheet(ingredient: ingredient)
        }
    }
}
