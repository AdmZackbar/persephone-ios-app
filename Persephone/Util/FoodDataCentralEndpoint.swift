//
//  FoodDataCentralEndpoint.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/24/24.
//

import Foundation

struct FoodDataCentralEndpoint: FoodDatabaseEndpoint {
    static func lookupBarcode(_ barcode: String) async throws -> [FoodItem] {
        var code = barcode
        if (code.count == 13) {
            // Barcode is in EAN13 format, we want UPC-A which has
            // just 12 digits instead of 13
            code.removeFirst()
        }
        return try await lookup(query: code, maxResults: 5)
    }
    
    static func lookup(query: String, maxResults: Int) async throws -> [FoodItem] {
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(query)&pageSize=\(maxResults)&dataType=Branded") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("KqxXU5h1uiwyHv300gSqczUVtSKmjkAm1w7mD48k", forHTTPHeaderField: "X-Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // TODO throw error
                return []
            }
        return parseFoodDataResult(data)
    }
    
    private static func parseFoodDataResult(_ data: Data) -> [FoodItem] {
        let decoder = JSONDecoder()
        if let jsonData = try? decoder.decode(SearchResult.self, from: data) {
            if let foods = jsonData.foods {
                return foods.map { food in
                    parseFood(food)
                }
            }
        }
        return []
    }
    
    private static func parseFood(_ food: BrandedFoodItem) -> FoodItem {
        let gramPattern = /([\d.]+)\s*[gG]/
        let kgPattern = /([\d.]+)\s*[kK][gG]/
        var totalAmount: Double? = nil
        if let match = try? gramPattern.firstMatch(in: food.packageWeight ?? "") {
            totalAmount = Double(match.1)!
        } else if let match = try? kgPattern.firstMatch(in: food.packageWeight ?? "") {
            totalAmount = Double(match.1)! * 1000.0
        }
        var numServings: Double? = nil
        if (totalAmount != nil && totalAmount! > 0 && food.servingSize != nil && food.servingSizeUnit == "g") {
            numServings = totalAmount! / food.servingSize!
        }
        var ratio = 1.0
        if (food.servingSize != nil && food.servingSizeUnit == "g") {
            ratio = food.servingSize! / 100.0
        }
        var nutrientMap: [Nutrient : FoodAmount] = [:]
        food.foodNutrients?.forEach({ nutrient in
            let adjValue = nutrient.value * ratio
            // Round to nearest half
            if let nutrient = getNutrient(nutrient.nutrientName) {
                nutrientMap[nutrient] = FoodAmount(value: .Raw(round(adjValue * 2.0) / 2.0), unit: nutrient.getCommonUnit())
            }
        })
        let metaData = FoodMetaData(
            barcode: food.gtinUpc,
            brand: food.brandName?.capitalized)
        let size = FoodSize(
            totalAmount: FoodAmount.grams(totalAmount ?? 0),
            numServings: numServings ?? 0,
            servingSize: food.householdServingFullText?.capitalized ?? "")
        let ingredients = FoodIngredients(
            nutrients: nutrientMap,
            all: food.ingredients?.capitalized ?? "")
        return FoodItem(
            name: food.description?.capitalized ?? "",
            metaData: metaData,
            ingredients: ingredients,
            size: size)
    }
    
    private static func getNutrient(_ name: String) -> Nutrient? {
        switch name {
        case "Energy":
            return .Energy
        case "Total lipid (fat)":
            return .TotalFat
        case "Fatty acids, total saturated":
            return .SaturatedFat
        case "Fatty acids, total trans":
            return .TransFat
        case "Carbohydrate, by difference":
            return .TotalCarbs
        case "Total Sugars":
            return .TotalSugars
        case "Fiber, total dietary":
            return .DietaryFiber
        case "Protein":
            return .Protein
        case "Sodium, Na":
            return .Sodium
        case "Cholesterol":
            return .Cholesterol
        default:
            return nil
        }
    }
}

private struct SearchResult: Codable {
    let totalHits: Int?
    let currentPage: Int?
    let totalPages: Int?
    let foodSearchCriteria: FoodSearchCriteria?
    let foods: [BrandedFoodItem]?
}

private struct FoodSearchCriteria: Codable {
    let query: String?
    let dataType: [String]?
    let generalSearchInput: String?
    let numberOfResultsPerPage: Int?
    let pageSize: Int?
    let pageNumber: Int?
    let sortBy: String?
    let sortOrder: String?
}

private struct BrandedFoodItem: Codable {
    let fdcId: Int
    let description: String?
    let dataType: String
    let gtinUpc: String?
    let publishedDate: String?
    let brandOwner: String?
    let brandName: String?
    let ingredients: String?
    let marketCountry: String?
    let foodCategory: String?
    let modifiedDate: String?
    let dataSource: String?
    let packageWeight: String?
    let servingSizeUnit: String?
    let servingSize: Double?
    let householdServingFullText: String?
    let tradeChannels: [String]?
    let allHighlightFields: String?
    let score: Double?
    let foodNutrients: [FoodNutrient]?
}

private struct FoodNutrient: Codable {
    let nutrientId: Int
    let nutrientName: String
    let nutrientNumber: String
    let unitName: String
    let derivationCode: String
    let derivationDescription: String
    let derivationId: Int
    let value: Double
    let foodNutrientSourceId: Int
    let foodNutrientSourceCode: String
    let foodNutrientSourceDescription: String
    let rank: Int
    let indentLevel: Int
    let foodNutrientId: Int
}
