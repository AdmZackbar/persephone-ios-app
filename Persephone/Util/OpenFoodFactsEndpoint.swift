//
//  OpenFoodFactsEndpoint.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/24/24.
//

import Foundation

struct OpenFoodFactsEndpoint: FoodDatabaseEndpoint {
    static func lookupBarcode(_ barcode: String) async throws -> [Food] {
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
    
    private static func parseFoodDataResult(_ data: Data) -> [Food] {
        let decoder = JSONDecoder()
        if let jsonData = try? decoder.decode(BarcodeResult.self, from: data) {
            return [parseProduct(jsonData.product)]
        }
        return []
    }
    
    private static func parseProduct(_ product: Product) -> Food {
//        var allergens: String? = nil
//        if let allergenMatches = product.allergens?.matches(of: /\w+:([^,]+)/) {
//            allergens = allergenMatches.map { match in
//                match.1.capitalized
//            }.joined(separator: ", ")
//        }
//        let rawServingSize = product.serving_size
//        let servingSize = rawServingSize?.replacing(/\(.+\)/, with: "").trimmingCharacters(in: .whitespacesAndNewlines).capitalized
//        let nutrients = [
//            .Energy: product.nutriments?.calories ?? 0,
//            .TotalFat: product.nutriments?.totalFat ?? 0,
//            .SaturatedFat: product.nutriments?.satFat ?? 0,
//            .TransFat: product.nutriments?.transFat ?? 0,
//            .PolyunsaturatedFat: product.nutriments?.polyFat ?? 0,
//            .MonounsaturatedFat: product.nutriments?.monoFat ?? 0,
//            .Cholesterol: toMg(product.nutriments?.cholesterol) ?? 0,
//            .Sodium: toMg(product.nutriments?.sodium) ?? 0,
//            .TotalCarbs: product.nutriments?.totalCarbs ?? 0,
//            .DietaryFiber: product.nutriments?.dietaryFiber ?? 0,
//            .TotalSugars: product.nutriments?.totalSugars ?? 0,
//            .Protein: product.nutriments?.protein ?? 0,
//            .Calcium: toMg(product.nutriments?.calcium) ?? 0,
//            .Iron: toMg(product.nutriments?.iron) ?? 0,
//            .Potassium: toMg(product.nutriments?.potassium ?? 0)
//        ]
//        return .init(name: product.product_name?.capitalized ?? "Unknown",
//                     metaData: .init(barcode: product.code, brand: product.brands?.capitalized ?? ""),
//                     ingredients: .init(nutrients: nutrients, all: product.ingredients_text?.capitalized ?? "", allergens: allergens ?? ""),
//                     servingSize: FoodSize(str: servingSize ?? ""))
        return .init()
    }
    
    static func toMg(_ amount: Double?) -> Double? {
        if let amount {
            return amount * 1000.0
        }
        return nil
    }
    
    static func lookup(query: String, maxResults: Int) async throws -> [Food] {
        let str = "https://us.openfoodfacts.org/cgi/search.pl?action=process&search_terms=\(query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&sort_by=unique_scans_n&page_size=\(maxResults)&json=true"
        guard let url = URL(string: str) else {
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
        return parseQueryResult(data)
    }
    
    private static func parseQueryResult(_ data: Data) -> [Food] {
        let decoder = JSONDecoder()
        do {
            let jsonData = try decoder.decode(QueryResult.self, from: data)
            return jsonData.products.map { product in
                parseProduct(product)
            }
        } catch {
            print("Unable to decode result: \(error)")
            print(String(decoding: data, as: UTF8.self))
            return []
        }
    }
}

private struct BarcodeResult: Codable {
    var code: String
    var product: Product
}

private struct QueryResult: Codable {
    var products: [Product]
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
        // For some reason sodium_serving returns a string
        case sodium = "sodium_value_a"
        case totalCarbs = "carbohydrates_serving"
        case dietaryFiber = "fiber_serving"
        case totalSugars = "sugars_serving"
        case protein = "proteins_serving"
        case calcium = "calcium_serving_a"
        case iron = "iron_serving_a"
        case potassium = "potassium_serving_a"
        case vitaminA = "vitamin-a_serving_a"
        case vitaminC = "vitamin-c_serving_a"
    }
}
