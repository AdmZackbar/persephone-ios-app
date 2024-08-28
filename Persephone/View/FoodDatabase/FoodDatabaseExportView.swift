//
//  FoodDatabaseExportView.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/25/24.
//

import SwiftUI

struct FoodDatabaseExportView: View {
    let foodItems: [FoodItem]
    
    @State private var exporting = false
    
    var body: some View {
        VStack {
            Button("Export Food Database") {
                exporting = true
            }.fileExporter(isPresented: $exporting, document: FoodDatabaseDocument(entries: foodItems.map(mapFoodItem)), contentType: .json) { result in
                switch result {
                case .success(let file):
                    print(file)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    private func mapFoodItem(item: FoodItem) -> FoodDatabaseDocument.Entry {
        FoodDatabaseDocument.Entry(name: item.name, details: item.details, metaData: item.metaData, ingredients: item.ingredients, size: item.size, storeEntries: item.storeEntries)
    }
}

#Preview {
    FoodDatabaseExportView(foodItems: [])
}
