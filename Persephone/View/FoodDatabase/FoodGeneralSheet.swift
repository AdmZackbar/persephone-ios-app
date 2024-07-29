//
//  FoodGeneralSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/28/24.
//

import SwiftUI

struct FoodGeneralSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: FoodItem
    
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var details: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("required", text: $name)
                }
                Section("Brand") {
                    TextField("optional", text: $brand)
                }
                Section("Description") {
                    TextEditor(text: $details).frame(height: 100)
                }
            }.navigationTitle("Food Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .onAppear {
                    name = item.name
                    brand = item.metaData.brand ?? ""
                    details = item.details ?? ""
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            item.name = name
                            item.metaData.brand = brand
                            item.details = details
                            dismiss()
                        }
                    }
                }
        }.presentationDetents([.medium])
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return FoodGeneralSheet(item: item)
        .modelContainer(container)
}
