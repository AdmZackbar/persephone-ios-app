//
//  CommercialFoodPreview.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/13/24.
//

import SwiftUI

struct CommercialFoodPreview: View {
    let food: CommercialFood
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(food.name).font(.headline).bold()
            Text(food.seller).font(.subheadline).bold()
            HStack {
                Label(food.metaData.tags.joined(separator: ", "), systemImage: "tag.fill")
                    .font(.subheadline)
                    .italic()
                Spacer()
                if let
                    rating = RatingTier.fromRating(rating: food.metaData.rating)?.rawValue {
                    Text("\(rating) Tier").font(.subheadline).bold()
                }
            }
            HStack(spacing: 4) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(food.cost.toString())
                            .font(.title)
                            .bold()
                        Spacer()
                    }
                    HStack {
                        if let cal = food.nutrients[.Energy]?.value.value {
                            VStack(alignment: .leading) {
                                Text((food.cost * 100 / cal).toString())
                                    .font(.subheadline)
                                    .bold()
                                Text("100 cal").font(.caption).italic()
                            }
                        }
                        Spacer()
                        if let protein = food.nutrients[.Protein]?.value.value {
                            VStack(alignment: .trailing) {
                                Text((food.cost / protein).toString())
                                    .font(.subheadline)
                                    .bold()
                                Text("1g Protein").font(.caption).italic()
                            }
                        }
                    }
                    Spacer()
                }
                Spacer()
                NutrientPieChart(nutrients: food.nutrients)
                    .frame(width: 140, height: 100)
            }
        }.navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        // TODO
                    }
                }
            }
            .padding()
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    VStack {
        Text("Test").contextMenu {
            Button("Test") {
                // Do nothing
            }
        } preview: {
            CommercialFoodPreview(food: .init(name: "Test"))
        }
    }
}
