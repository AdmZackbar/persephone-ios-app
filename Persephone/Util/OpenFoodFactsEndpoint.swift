//
//  OpenFoodFactsEndpoint.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/24/24.
//

import Foundation

struct OpenFoodFactsEndpoint: FoodDatabaseEndpoint {
    static func lookupBarcode(_ barcode: String) async throws -> [FoodItem] {
        var code = barcode
        if (code.count == 13) {
            // Barcode is in EAN13 format, we want UPC-A which has
            // just 12 digits instead of 13
            code.removeFirst()
        }
        guard let url = URL(string: "https://us.openfoodfacts.org/api/v0/product/\(code)") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Persephone - iOS - Version 0.1.0", forHTTPHeaderField: "User-Agent")
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
        if let jsonData = try? decoder.decode(BarcodeResult.self, from: data) {
            return [parseProduct(jsonData.product)]
        }
        return []
    }
    
    private static func parseProduct(_ product: Product) -> FoodItem {
        var allergens: String? = nil
        if let allergenMatches = product.allergens?.matches(of: /\w+:([^,]+)/) {
            allergens = allergenMatches.map { match in
                match.1.string.capitalized
            }.joined(separator: ", ")
        }
        let rawServingSize = product.serving_size
        let servingSize = rawServingSize?.replacing(/\(.+\)/, with: "").trimmingCharacters(in: .whitespacesAndNewlines).capitalized
        return FoodItem(name: product.product_name?.capitalized ?? "Unknown",
                 metaData: FoodMetaData(barcode: product.code, brand: product.brands?.capitalized),
                 ingredients: FoodIngredients(nutrients: [
                    .Energy: FoodAmount.calories(product.nutriments?.calories ?? 0),
                    .TotalFat: FoodAmount.grams(product.nutriments?.totalFat ?? 0),
                    .SaturatedFat: FoodAmount.grams(product.nutriments?.satFat ?? 0),
                    .TransFat: FoodAmount.grams(product.nutriments?.transFat ?? 0),
                    .PolyunsaturatedFat: FoodAmount.grams(product.nutriments?.polyFat ?? 0),
                    .MonounsaturatedFat: FoodAmount.grams(product.nutriments?.monoFat ?? 0),
                    .Cholesterol: try! FoodAmount.grams(product.nutriments?.cholesterol ?? 0).toMilligrams(),
                    .Sodium: try! FoodAmount.grams(product.nutriments?.sodium ?? 0).toMilligrams(),
                    .TotalCarbs: FoodAmount.grams(product.nutriments?.totalCarbs ?? 0),
                    .DietaryFiber: FoodAmount.grams(product.nutriments?.dietaryFiber ?? 0),
                    .TotalSugars: FoodAmount.grams(product.nutriments?.totalSugars ?? 0),
                    .Protein: FoodAmount.grams(product.nutriments?.protein ?? 0),
                    .Calcium: try! FoodAmount.grams(product.nutriments?.calcium ?? 0).toMilligrams(),
                    .Iron: try! FoodAmount.grams(product.nutriments?.iron ?? 0).toMilligrams(),
                    .Potassium: try! FoodAmount.grams(product.nutriments?.potassium ?? 0).toMilligrams(),
                 ], all: product.ingredients_text?.capitalized ?? "", allergens: allergens ?? ""),
                 size: FoodSize(totalAmount: FoodAmount.grams(0), numServings: 0, servingSize: servingSize ?? ""))
    }
    
    static func lookup(query: String, maxResults: Int) async throws -> [FoodItem] {
        // TODO
        return []
    }
}

private struct BarcodeResult: Codable {
    var code: String
    var product: Product
}

private struct Product: Codable {
    var allergens: String?
    var brand_owner: String?
    var brands: String?
    var categories: String?
    var code: String?
    var ingredients_text: String?
    var link: String?
    var nutriments: Nutriments?
    var product_name: String?
    var serving_quantity: String?
    var serving_size: String?
}

private struct Nutriments: Codable {
    var calories: Double?
    var totalFat: Double?
    var satFat: Double?
    var transFat: Double?
    var monoFat: Double?
    var polyFat: Double?
    var cholesterol: Double?
    var sodium: Double?
    var totalCarbs: Double?
    var dietaryFiber: Double?
    var totalSugars: Double?
    var protein: Double?
    var calcium: Double?
    var iron: Double?
    var potassium: Double?
    var vitaminA: Double?
    var vitaminC: Double?
    
    private enum CodingKeys: String, CodingKey {
        case calories = "energy-kcal_serving"
        case totalFat = "fat_serving"
        case satFat = "saturated-fat_serving"
        case transFat = "trans-fat_serving"
        case monoFat = "monounsaturated-fat_serving"
        case polyFat = "polyunsaturated-fat_serving"
        case cholesterol = "cholesterol_serving"
        case sodium = "sodium_serving"
        case totalCarbs = "carbohydrates_serving"
        case dietaryFiber = "fiber_serving"
        case totalSugars = "sugars_serving"
        case protein = "proteins_serving"
        case calcium = "calcium_serving"
        case iron = "iron_serving"
        case potassium = "potassium_serving"
        case vitaminA = "vitamin-a_serving"
        case vitaminC = "vitamin-c_serving"
    }
}
