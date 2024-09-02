//
//  FoodItemPreview.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/2/24.
//

import SwiftUI

struct FoodItemPreview: View {
    let item: FoodItem
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline).bold()
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                HStack(alignment: .top) {
                    Text(item.metaData.brand ?? "Generic Brand")
                        .font(.subheadline).italic()
                    Spacer()
                    if let tier = FoodTier.fromRating(rating: item.metaData.rating) {
                        Text("\(tier.rawValue) Tier")
                            .font(.subheadline).bold()
                    }
                }
                let tags = item.metaData.tags.joined(separator: ", ")
                if !tags.isEmpty {
                    Label(tags, systemImage: "tag.fill")
                        .font(.caption).bold()
                }
            }
            HStack(alignment: .top, spacing: 16) {
                MacroChartView(nutrients: item.ingredients.nutrients)
                    .frame(width: 140, height: 100)
                Divider()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.size.servingSize)
                        .bold()
                    Text("\(item.size.servingAmount.value.toString())\(item.size.servingAmount.unit.getAbbreviation())")
                        .font(.subheadline).bold()
                    Text("\(formatter.string(for: item.size.numServings)!) servings")
                        .font(.subheadline)
                    if item.size.totalAmount.unit.isWeight() {
                        if item.size.totalAmount.unit == .Gram && item.size.totalAmount.value.toValue() > 1000 {
                            Text("Net Wt: \((item.size.totalAmount.value / 1000).toString())kg")
                                .font(.subheadline)
                        } else {
                            Text("Net Wt: \(item.size.totalAmount.value.toString())\(item.size.totalAmount.unit.getAbbreviation())")
                                .font(.subheadline)
                        }
                    } else if item.size.totalAmount.unit.isVolume() {
                        if item.size.totalAmount.unit == .Milliliter && item.size.totalAmount.value.toValue() > 1000 {
                            Text("Net Vol: \((item.size.totalAmount.value / 1000).toString())L")
                                .font(.subheadline)
                        } else {
                            Text("Net Vol: \(item.size.totalAmount.value.toString())\(item.size.totalAmount.unit.getAbbreviation())")
                                .font(.subheadline)
                        }
                    }
                }.frame(maxWidth: 120)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(item.storeEntries
                    // Only include non-retired entries
                    .filter { $0.available }
                    // Sort by best to worst price
                    .sorted { $0.costPerUnit(size: item.size) < $1.costPerUnit(size: item.size) }
                        , id: \.storeName) { storeEntry in
                    Divider()
                    createStoreEntryView(storeEntry)
                }
            }
        }.padding()
    }
    
    func createStoreEntryView(_ storeEntry: FoodItem.StoreEntry) -> some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(storeEntry.storeName).bold()
                Text(formatItemCost(storeEntry.costType))
                    .italic()
                    .font(.subheadline)
            }
            Spacer()
            if let perEnergy = storeEntry.costPerEnergy(foodItem: item) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatCost(perEnergy))
                        .font(.subheadline).bold()
                    Text("100 cal")
                        .font(.caption).italic()
                }
            } else if item.size.totalAmount.unit.isWeight() {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatCost(storeEntry.costPerWeight(size: item.size)))
                        .font(.subheadline).bold()
                    Text("100 g")
                        .font(.caption).italic()
                }
            } else if item.size.totalAmount.unit.isVolume() {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatCost(storeEntry.costPerVolume(size: item.size)))
                        .font(.subheadline).bold()
                    Text("100 mL")
                        .font(.caption).italic()
                }
            }
            if item.size.numServings != 1 && item.size.servingSizeAmount.value.toValue() != 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatCost(storeEntry.costPerServing(size: item.size)))
                        .font(.subheadline).bold()
                    Text("serving")
                        .font(.caption).italic()
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCost(storeEntry.costPerServingAmount(size: item.size)))
                    .font(.subheadline).bold()
                Text(item.size.servingSizeAmount.unit.getAbbreviation().lowercased())
                    .font(.caption).italic()
            }
        }
    }
    
    private func formatItemCost(_ costType: FoodItem.CostType) -> String {
        switch costType {
        case .Collection(let cost, let quantity):
            if quantity == 1 {
                return costToString(cost)
            } else {
                return "\(quantity) for \(costToString(cost))"
            }
        case .PerAmount(let cost, let amount):
            if amount.value.toValue() == 1 {
                return "\(costToString(cost)) per \(amount.unit.getAbbreviation())"
            } else {
                return "\(costToString(cost)) per \(formatter.string(for: amount.value.toValue())!) \(amount.unit.getAbbreviation())"
            }
        }
    }
    
    private func costToString(_ cost: FoodItem.Cost) -> String {
        switch cost {
        case .Cents(let cents):
            return formatCost(Double(cents) / 100)
        }
    }
    
    private func formatCost(_ cost: Double) -> String {
        currencyFormatter.string(for: cost)!
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return Form {
        Text(item.name).contextMenu {
            Button("test") {
                
            }
        } preview: {
            FoodItemPreview(item: item)
        }
    }
}
