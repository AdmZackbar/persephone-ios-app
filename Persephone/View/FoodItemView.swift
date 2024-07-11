//
//  FoodItemView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftUI

struct FoodItemView: View {
    var item: FoodItem
    
    var body: some View {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        return List {
            Section("Description") {
                Text(item.details)
            }
            Section("Details") {
                Text("Price: \(currencyFormatter.string(for: Double(item.price) / 100.0)!)")
                Text("Servings: \(item.numServings)")
                Text("Serving Size: \(item.servingSize)")
                Text("Net \(item.sizeType == .Mass ? "Weight" : "Volume"): \(item.totalSize) \(item.sizeType == .Mass ? "g" : "mL")")
            }
            Section("Nutrition") {
                // TODO
            }
        }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(item.name).font(.headline)
                        Text(item.brand).font(.subheadline)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        FoodItemEditor(item: item)
                            .navigationBarBackButtonHidden()
                    } label: {
                        Text("Edit")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        FoodItemView(item: FoodItem(timestamp: Date(), name: "Lightly Breaded Chicken Chunks", brand: "Kirkland", details: "Costco's chicken nuggets", price: 1399, store: "Costco", numServings: 16, servingSize: "4 oz", totalSize: 1814, sizeType: .Mass))
    }
}
