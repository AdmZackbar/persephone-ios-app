//
//  FoodItemEditor.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct FoodItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    let item: FoodItem?
    @State private var barcode: String?
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var details: String = ""
    @State private var store: String = ""
    @State private var price: Int = 0
    @State private var numServings: Double = 0.0
    @State private var servingSize: String = ""
    @State private var totalAmount: Double = 0.0
    @State private var sizeType: SizeType = .Mass
    
    let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter
    }()
    
    var body: some View {
        Form {
            Section("Main Info") {
                TextField("Name", text: $name)
                TextField("Brand", text: $brand)
                TextField("Store", text: $store)
            }
            Section("Price") {
                CurrencyTextField(numberFormatter: numberFormatter, value: $price)
            }
            Section("Total Size") {
                HStack {
                    Menu("Total \(sizeType == .Mass ? "Weight (g)" : "Volume (mL)"):") {
                        Button("Weight") {
                            sizeType = .Mass
                        }
                        Button("Volume") {
                            sizeType = .Volume
                        }
                    }
                    TextField("", value: $totalAmount, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            Section("Servings") {
                TextField("Number of Servings", value: $numServings, format: .number)
                    .keyboardType(.numberPad)
                TextField("Serving Size", text: $servingSize)
            }
            Section("Description") {
                TextEditor(text: $details).frame(height: 100)
            }
        }
        .onAppear {
            if let item {
                name = item.name
                brand = item.metaData.brand ?? ""
                details = item.metaData.details ?? ""
                store = item.storeInfo?.name ?? ""
                price = item.storeInfo?.price ?? 0
                numServings = item.sizeInfo.numServings
                servingSize = item.sizeInfo.servingSize
                totalAmount = item.sizeInfo.totalAmount
                sizeType = item.sizeInfo.sizeType
            }
        }
        .navigationTitle("\(item == nil ? "Add" : "Edit") Food Entry")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    withAnimation {
                        save()
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || brand.isEmpty || servingSize.isEmpty || price <= 0 || numServings <= 0 || totalAmount <= 0)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func save() {
        if let item {
            item.name = name
            item.metaData.brand = brand
            item.metaData.details = details
            item.storeInfo = StoreInfo(name: store, price: price)
            item.sizeInfo = FoodSizeInfo(numServings: numServings, servingSize: servingSize, totalAmount: totalAmount, servingAmount: round(totalAmount / numServings), sizeType: sizeType)
        } else {
            let newItem = FoodItem(name: name, metaData: FoodMetaData(barcode: barcode, brand: brand, details: details), composition: FoodComposition(nutrients: [:]),sizeInfo: FoodSizeInfo(numServings: numServings, servingSize: servingSize, totalAmount: totalAmount, servingAmount: round(totalAmount / numServings), sizeType: sizeType), storeInfo: StoreInfo(name: store, price: price))
            modelContext.insert(newItem)
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    return NavigationStack {
        FoodItemEditor(item: nil)
    }.modelContainer(container)
}
