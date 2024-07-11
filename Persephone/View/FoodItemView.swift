//
//  FoodItemView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct FoodItemView: View {
    var item: FoodItem
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.alwaysShowsDecimalSeparator = false
        return formatter
    }()
    
    var body: some View {
        List {
            Section("Description") {
                Text(item.metaData.details ?? "")
            }
            Section("Details") {
                if (item.storeInfo != nil) {
                    Text("Price: \(currencyFormatter.string(for: Double(item.storeInfo!.price) / 100.0)!)")
                }
                Text("Servings: \(numberFormatter.string(for: item.sizeInfo.numServings)!)")
                Text("Serving Size: \(item.sizeInfo.servingSize)")
                Text("Net \(item.sizeInfo.sizeType == .Mass ? "Weight" : "Volume"): \(numberFormatter.string(for: item.sizeInfo.totalAmount)!) \(item.sizeInfo.sizeType == .Mass ? "g" : "mL")")
            }
            Section("Nutrition") {
                ForEach(Array(item.composition.nutrients.keys), id: \.self) { nutrient in
                    Text("\(nutrient): \(numberFormatter.string(for: item.composition.nutrients[nutrient]!)!)")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(item.name).font(.headline)
                    Text(item.metaData.brand ?? "").font(.subheadline)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    FoodItemEditor(item: item)
                } label: {
                    Text("Edit")
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    let item = FoodItem(name: "Lightly Breaded Chicken Chunks", metaData: FoodMetaData(brand: "Kirkland", details: "Costco's chicken nuggets"), composition: FoodComposition(nutrients: [.Calorie: 120, .Protein: 13]), sizeInfo: FoodSizeInfo(numServings: 16, servingSize: "4 oz", totalAmount: 1814, servingAmount: 63, sizeType: .Mass), storeInfo: StoreInfo(name: "Costco", price: 1399))
    return NavigationStack {
        FoodItemView(item: item)
    }.modelContainer(container)
}
