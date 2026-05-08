//
//  StoreEntryEditSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/19/25.
//

import SwiftUI

struct StoreEntryEditSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let units: [Amount.Unit]
    
    @Binding private var foodItem: FoodItem
    @State private var item: StoreEntryItem
    @State private var unit: Amount.Unit
    
    init(foodItem: Binding<FoodItem>, item: StoreEntryItem = .init()) {
        self._foodItem = foodItem
        self.item = item
        if foodItem.wrappedValue.servingSize.isMass {
            self.unit = .gram
            self.units = [.gram, .pound, .ounce]
        } else {
            self.unit = .milliliter
            self.units = [.milliliter, .liter, .fluidounce]
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Store:")
                    TextField("required", text: $item.store)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                CurrencyField(value: $item.cost)
                HStack {
                    Toggle("Available:", isOn: $item.isAvailable)
                    Divider()
                    Toggle("Sale:", isOn: $item.isSale)
                }
                Section("Total Amount") {
                    TextField("required", text: $item.amount.str)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    AmountField(amount: Binding(get: {
                        .init(value: .raw(item.amount.val / (unit.modifier ?? 1)), unit: unit)
                    }, set: { value in
                        unit = value.unit!
                        item.amount.val = value.value.raw * (unit.modifier ?? 1)
                    }), units: units)
                    if let unit = foodItem.servingSize.amount.unit {
                        Text("\(computeNumServings().formatted()) servings (\(unit.abbreviation))")
                            .italic()
                    }
                }
            }.navigationTitle(item.isEdit ? "Edit Store Entry" : "Add Store Entry")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar(content: toolbarContent)
        }.presentationDetents([.medium])
    }
    
    private func computeNumServings() -> Double {
        return item.amount.val / foodItem.servingSize.val
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(item.isEdit ? "Save" : "Add") {
                item.amount.isMass = foodItem.servingSize.isMass
                if let storeEntry = item.save() {
                    foodItem.storeEntries.append(storeEntry)
                }
                dismiss()
            }.disabled(item.isInvalid)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(item.isEdit ? "Cancel" : "Back") {
                dismiss()
            }
        }
    }
}

#Preview {
    @Previewable @State var foodItem = FoodItem(entry: .init(servingSize: .init(str: "1 portion", val: 5)))
    StoreEntryEditSheet(foodItem: $foodItem)
}
