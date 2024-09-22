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
                    if let tier = RatingTier.fromRating(rating: item.metaData.rating) {
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
                    Text("\(item.size.servingAmount.value.toString())\(item.size.servingAmount.unit.abbreviation)")
                        .font(.subheadline).bold()
                    Text("\(formatter.string(for: item.size.numServings)!) servings")
                        .font(.subheadline)
                    if item.size.totalAmount.unit.isWeight {
                        if item.size.totalAmount.unit == .Gram && item.size.totalAmount.value.value > 1000 {
                            Text("Net Wt: \((item.size.totalAmount.value / 1000).toString())kg")
                                .font(.subheadline)
                        } else {
                            Text("Net Wt: \(item.size.totalAmount.value.toString())\(item.size.totalAmount.unit.abbreviation)")
                                .font(.subheadline)
                        }
                    } else if item.size.totalAmount.unit.isVolume {
                        if item.size.totalAmount.unit == .Milliliter && item.size.totalAmount.value.value > 1000 {
                            Text("Net Vol: \((item.size.totalAmount.value / 1000).toString())L")
                                .font(.subheadline)
                        } else {
                            Text("Net Vol: \(item.size.totalAmount.value.toString())\(item.size.totalAmount.unit.abbreviation)")
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
                        , id: \.hashValue) { storeEntry in
                    Divider()
                    createStoreEntryView(storeEntry)
                }
            }
        }.padding()
    }
    
    func createStoreEntryView(_ storeEntry: FoodItem.StoreEntry) -> some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(storeEntry.storeName).bold()
                    if storeEntry.sale {
                        Text("(Sale)").font(.subheadline).italic()
                    } else if !storeEntry.available {
                        Text("(Retired)").font(.subheadline).italic()
                    }
                }
                Text(formatItemCost(storeEntry.costType))
                    .italic()
                    .font(.subheadline)
            }
            Spacer()
            if let perEnergy = storeEntry.costPerEnergy(foodItem: item) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(perEnergy.toString())
                        .font(.subheadline).bold()
                    Text("100 cal")
                        .font(.caption).italic()
                }
            } else if item.size.totalAmount.unit.isWeight {
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeEntry.costPerWeight(size: item.size).toString())
                        .font(.subheadline).bold()
                    Text("100 g")
                        .font(.caption).italic()
                }
            } else if item.size.totalAmount.unit.isVolume {
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeEntry.costPerVolume(size: item.size).toString())
                        .font(.subheadline).bold()
                    Text("100 mL")
                        .font(.caption).italic()
                }
            }
            if item.size.numServings != 1 && item.size.servingSizeAmount.value.value != 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeEntry.costPerServing(size: item.size).toString())
                        .font(.subheadline).bold()
                    Text("serving")
                        .font(.caption).italic()
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(storeEntry.costPerServingAmount(size: item.size).toString())
                    .font(.subheadline).bold()
                Text(item.size.servingSizeAmount.unit.abbreviation.lowercased())
                    .font(.caption).italic()
            }
        }
    }
    
    private func formatItemCost(_ costType: FoodItem.CostType) -> String {
        switch costType {
        case .Collection(let cost, let quantity):
            if quantity == 1 {
                return cost.toString()
            } else {
                return "\(quantity) for \(cost.toString())"
            }
        case .PerAmount(let cost, let amount):
            if amount.value.value == 1 {
                return "\(cost.toString()) per \(amount.unit.abbreviation)"
            } else {
                return "\(cost.toString()) per \(formatter.string(for: amount.value.value)!) \(amount.unit.abbreviation)"
            }
        }
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
