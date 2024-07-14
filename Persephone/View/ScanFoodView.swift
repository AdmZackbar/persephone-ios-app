//
//  ScanFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/13/24.
//

import SwiftData
import SwiftUI

struct ScanFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var scannedItem: FoodItem? = nil
    
    var body: some View {
        VStack {
            if (scannedItem == nil) {
                ScannerView(barcodeHandler: lookupBarcode)
                    .navigationTitle("Scan Barcode")
                    .toolbarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
            } else {
                FoodItemEditor(item: scannedItem, mode: .Confirm)
            }
        }
    }
    
    private func lookupBarcode(barcode: String) {
        var code = barcode
        if (code.count == 13) {
            // Barcode is in EAN13 format, we want UPC-A which has
            // just 12 digits instead of 13
            code.removeFirst()
        }
        
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(code)&pageSize=1&dataType=Branded&sortBy=publishedDate&sortOrder=desc") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("KqxXU5h1uiwyHv300gSqczUVtSKmjkAm1w7mD48k", forHTTPHeaderField: "X-Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Empty data"); return }
            parseFoodDataResult(data: data)
        }.resume()
    }
    
    private func parseFoodDataResult(data: Data) {
        let decoder = JSONDecoder()
        if let jsonData = try? decoder.decode(SearchResult.self, from: data) {
            if let food = jsonData.foods?.count ?? 0 > 0 ? jsonData.foods?[0] : nil {
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
                var nutrientMap: [Nutrient : Double] = [:]
                food.foodNutrients?.forEach({ nutrient in
                    let adjValue = nutrient.value * ratio
                    // Round to nearest half
                    if let nutrient = getNutrient(nutrient.nutrientName) {
                        nutrientMap[nutrient] = round(adjValue * 2.0) / 2.0
                    }
                })
                let metaData = FoodMetaData(barcode: food.gtinUpc, brand: food.brandName)
                let sizeInfo = FoodSizeInfo(numServings: numServings ?? 0, servingSize: food.householdServingFullText ?? "", totalAmount: totalAmount ?? 0, servingAmount: food.servingSize ?? 0, sizeType: .Mass)
                let composition = FoodComposition(nutrients: nutrientMap, ingredients: food.ingredients)
                scannedItem = FoodItem(name: food.description ?? "", metaData: metaData, composition: composition, sizeInfo: sizeInfo)
            }
        }
    }
    
    private func getNutrient(_ name: String) -> Nutrient? {
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    return NavigationStack {
        ScanFoodView()
    }.modelContainer(container)
}
