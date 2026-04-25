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
        container.mainContext.insert(createTestFood())
        container.mainContext.insert(createTestRecipeEntry())
        container.mainContext.insert(createTestFoodLogEntry())
//        insertTestMeals(container)
//        container.mainContext.insert(createRecipe())
    }
    
    static func createTestFood() -> Food {
        let item = Food(
            name: "Test Food",
            metaData: .init(barcode: "0123456789", brand: "Some Brand", category: "Bread", notes: "Preparation: cook at 375 F for 12-14 minutes.", rating: 8),
            ingredients: .init(
                nutrients: [
                    .Energy: 120,
                    .TotalFat: 3.5,
                    .SaturatedFat: 2,
                    .PolyunsaturatedFat: 0.5,
                    .Cholesterol: 50,
                    .Sodium: 255,
                    .TotalCarbs: 12,
                    .DietaryFiber: 1,
                    .TotalSugars: 0.5,
                    .Protein: 5,
                    .Calcium: 20,
                    .Potassium: 15
                ],
                all: "Salt, Milk, Water, Pectin (for something or other).",
                allergens: "Milk"
            ),
            servingSize: .init(str: "1 unit", val: 35),
            storeEntries: [
                .init(store: "Store 1", cost: .usd(599), amount: .init(str: "1 container", val: 1600)),
                .init(store: "Store 2", cost: .usd(1099), amount: .init(str: "2 containers", val: 3200)),
                .init(store: "Store 3", cost: .usd(1000), amount: .init(str: "1 lb", val: 500))
            ])
//        item.logEntries.append(.init(item: item, amount: .Raw(1.5), category: "Breakfast", unitPrice: .Cents(240)))
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
    
    static func createTestRecipeEntry() -> RecipeEntry {
        let entry = RecipeEntry(
            name: "Baked Pork Tenderloin",
            notes: "In the oven for 20 min",
            total: .init(str: "2 tenderloins", val: 907),
            ingredients: [
                .init(
                    food: .init(
                        name: "Pork Tenderloin",
                        ingredients: .init(nutrients: [.Energy: 170, .Protein: 22, .TotalFat: 7]),
                        servingSize: .init(str: "4 oz", val: 112)),
                    amount: .init(value: .raw(1102), unit: Units.gram))
            ],
            logEntries: [
                .init(amount: .init(value: .raw(140), unit: Units.gram), meal: "Lunch")
            ])
        return entry
    }
    
    static func createTestFoodLogEntry() -> FoodLogEntry {
        .init(food: .init(
            name: "Pork Tenderloin",
            ingredients: .init(nutrients: [.Energy: 170, .Protein: 22, .TotalFat: 7, .TotalCarbs: 3, .DietaryFiber: 1]),
            servingSize: .init(str: "4 oz", val: 112)),
              amount: .init(value: .raw(203), unit: Units.gram),
              meal: "Lunch",
              servingCost: .usd(203))
    }
    
//    static func insertTestMeals(_ container: ModelContainer) {
//        let foods: [Food] = [
//            .init(name: "Artisan Roll", metaData: .init(brand: "Kirkland", category: "Bread"), servingSize: .init(str: "1 loaf", val: 100)),
//            .init(name: "Sharp Cheddar", metaData: .init(brand: "Adams Reserve", category: "Cheese"), servingSize: .init(str: "1 slice", val: 21)),
//            .init(name: "Sliced Ham", metaData: .init(brand: "Kirkland", category: "Ham"), servingSize: .init(str: "2 slices", val: 56)),
//            .init(name: "CFA Sauce", metaData: .init(brand: "Chick-Fil-A", category: "Sauce"), servingSize: .init(str: "1 oz", val: 32)),
//            .init(name: "Jasmine Rice", metaData: .init(brand: "Botan", category: "Rice"), servingSize: .init(str: "45 g", val: 45)),
//            .init(name: "Pork Tenderloin", metaData: .init(brand: "Swift", category: "Pork"), servingSize: .init(str: "4 oz", val: 112)),
//            .init(name: "Green Beans", metaData: .init(brand: "Kirkland", category: "Vegetables"), servingSize: .init(str: "85 g", val: 85)),
//        ]
//        let meals: [Meal] = [
//            .init(name: "Zach's Sandwich"),
//            .init(name: "Slop Bowl"),
//        ]
//        let mealItems: [MealItem] = [
//            .init(meal: meals[0], food: foods[0]),
//            .init(meal: meals[0], food: foods[1]),
//            .init(meal: meals[0], food: foods[2], defaultAmount: .init(value: .raw(2))),
//            .init(meal: meals[0], food: foods[3], defaultAmount: .init(value: .raw(5), unitStr: "g")),
//            .init(meal: meals[1], food: foods[4]),
//            .init(meal: meals[1], food: foods[5]),
//            .init(meal: meals[1], food: foods[6]),
//        ]
//        mealItems.forEach(container.mainContext.insert)
//    }
    
//    static func createRecipe() -> Recipe {
//        .init(
//            name: "Test Recipe",
//            metaData: Recipe.MetaData(
//                author: "Zach Wassynger",
//                details: "My fav waffles, some more text here just put them on the iron for a few minutes and eat",
//                prepTime: 8,
//                cookTime: 17,
//                otherTime: 0,
//                tags: ["Breakfast", "Bread"],
//                rating: 7.5,
//                ratingLeftover: 5,
//                difficulty: 5),
//            instructions: [
//                Recipe.Section(header: "Prep", details: "1. Put the mix with the water\n2. Mix until barely combined"),
//                Recipe.Section(header: "Cook", details: "1. Put mix into the iron\n2. Wait until iron signals completion\n3. Remove and allow to cool")],
//            size: Recipe.Size(
//                numServings: 6,
//                servingSize: "1 waffle"
//            ),
//            ingredients: [
//                .init(name: "Water", amount: .init(value: .raw(120), unit: Units.milliliter), notes: "Tap water or else"),
//                .init(name: "Salt", amount: .init(value: .raw(600), unit: Units.milligram))
//            ])
//    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}
