//
//  MockDataPreviewModifier.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import SwiftData
import SwiftUI

// Ideally this should reside in Preview Content, but
// because the dead code stripper doesn't work with the
// preview modifier, this has to stay in the main codebase...
struct MockDataPreviewModifier: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let container = try ModelContainer(
            for: Schema(CurrentSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        populateContainer(container)
        return container
    }
    
    static func populateContainer(_ container: ModelContainer) {
        container.mainContext.insert(createTestFoodItem())
        container.mainContext.insert(createCommercialFoodItem())
        container.mainContext.insert(createRecipe())
    }
    
    static func createTestFoodItem() -> FoodItem {
        let item = FoodItem(
            name: "Test Food",
            details: "Preparation: cook at 375 F for 12-14 minutes.",
            metaData: FoodItem.MetaData(barcode: "0123456789", brand: "Some Brand", tags: ["Bread"], rating: 8),
            ingredients: FoodIngredients(
                nutrients: [
                    .Energy: Quantity.calories(120),
                    .TotalFat: Quantity.grams(3.5),
                    .SaturatedFat: Quantity.grams(2),
                    .PolyunsaturatedFat: Quantity.grams(0.5),
                    .Cholesterol: Quantity.milligrams(50),
                    .Sodium: Quantity.milligrams(255),
                    .TotalCarbs: Quantity.grams(12),
                    .DietaryFiber: Quantity.grams(1),
                    .TotalSugars: Quantity.grams(0.5),
                    .Protein: Quantity.grams(5),
                    .Calcium: Quantity.milligrams(20),
                    .Potassium: Quantity.milligrams(15)
                ],
                all: "Salt, Milk, Water, Pectin (for something or other).",
                allergens: "Milk"
            ),
            size: FoodItem.Size(totalAmount: Quantity.grams(225), numServings: 5, servingSize: "1 unit"),
            storeEntries: [
                FoodItem.StoreEntry(storeName: "Store 1", costType: .Collection(cost: .Cents(599), quantity: 2)),
                FoodItem.StoreEntry(storeName: "Store 2", costType: .Collection(cost: .Cents(1099), quantity: 3)),
                FoodItem.StoreEntry(storeName: "Store 3", costType: .PerAmount(cost: .Cents(1000), amount: Quantity(value: .Raw(1), unit: .Pound)))
            ])
//        item.instances = [
//            FoodInstance(
//                foodItem: item,
//                origin: .Store(store: "Costco", price: .Cents(530)),
//                amount: .Single(
//                    total: Quantity(value: .Raw(530), unit: .Gram),
//                    remaining: Quantity(value: .Raw(420), unit: .Gram)),
//                dates: FoodInstance.Dates(
//                    acqDate: Date(),
//                    expDate: Date().addingTimeInterval(100000),
//                    freezeDate: Date().addingTimeInterval(3600)
//                ))
//        ]
        return item
    }
    
    static func createCommercialFoodItem() -> CommercialFood {
        .init(
            name: "Baconator", seller: "Wendy's", cost: .Cents(589),
            nutrients: [
                .Energy: .calories(840),
                .TotalCarbs: .grams(30),
                .TotalFat: .grams(22),
                .SaturatedFat: Quantity.grams(2),
                .PolyunsaturatedFat: Quantity.grams(0.5),
                .Cholesterol: Quantity.milligrams(50),
                .Sodium: Quantity.milligrams(255),
                .Protein: .grams(30),
                .Calcium: Quantity.milligrams(20),
                .Potassium: Quantity.milligrams(15)],
            metaData: CommercialFood.MetaData(
                notes: "Pretty good burger lmao",
                rating: 8.0,
                tags: ["Burger"]
            ))
    }
    
    static func createRecipe() -> Recipe {
        .init(
            name: "Test Recipe",
            metaData: Recipe.MetaData(
                author: "Zach Wassynger",
                details: "My fav waffles, some more text here just put them on the iron for a few minutes and eat",
                prepTime: 8,
                cookTime: 17,
                otherTime: 0,
                tags: ["Breakfast", "Bread"],
                rating: 7.5,
                ratingLeftover: 5,
                difficulty: 5),
            instructions: [
                Recipe.Section(header: "Prep", details: "1. Put the mix with the water\n2. Mix until barely combined"),
                Recipe.Section(header: "Cook", details: "1. Put mix into the iron\n2. Wait until iron signals completion\n3. Remove and allow to cool")],
            size: Recipe.Size(
                numServings: 6,
                servingSize: "1 waffle"
            ),
            ingredients: [
                .init(name: "Water", amount: Quantity(value: .Raw(1.2), unit: .Liter), notes: "Tap water or else"),
                .init(name: "Salt", amount: Quantity(value: .Raw(600), unit: .Milligram))
            ])
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}
