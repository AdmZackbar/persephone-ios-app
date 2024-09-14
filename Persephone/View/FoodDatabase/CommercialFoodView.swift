//
//  CommercialFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/13/24.
//

import SwiftUI

struct CommercialFoodView: View {
    @Binding private var path: [FoodDatabaseView.ViewType]
    
    let food: CommercialFood
    
    init(path: Binding<[FoodDatabaseView.ViewType]>, food: CommercialFood) {
        self._path = path
        self.food = food
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(food.seller)
                        .bold()
                    Spacer()
                    Label(food.metaData.tags.joined(separator: ", "), systemImage: "tag.fill")
                        .font(.subheadline)
                        .italic()
                }
                HStack(spacing: 4) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(food.cost.toString())
                                .font(.title)
                                .bold()
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            if let cal = food.nutrients[.Energy]?.value.toValue() {
                                VStack(alignment: .leading) {
                                    Text((food.cost * 100 / cal).toString())
                                        .font(.subheadline)
                                        .bold()
                                    Text("100 cal").font(.caption).italic()
                                }
                            }
                            Spacer()
                            if let protein = food.nutrients[.Protein]?.value.toValue() {
                                VStack(alignment: .trailing) {
                                    Text((food.cost / protein).toString())
                                        .font(.subheadline)
                                        .bold()
                                    Text("1g Protein").font(.caption).italic()
                                }
                            }
                        }
                    }.padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                        .background(Color("BackgroundColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                    MacroChartView(nutrients: food.nutrients)
                        .frame(width: 160, height: 120)
                        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                        .background(Color("BackgroundColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let rating = FoodTier.fromRating(rating: food.metaData.rating)?.rawValue {
                    Text("\(rating) Tier").bold()
                }
                if !food.metaData.notes.isEmpty {
                    Text(food.metaData.notes).italic()
                }
                NutrientTableView(nutrients: food.nutrients)
                    .padding()
                    .background(Color("BackgroundColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }.navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        path.append(.CommercialFoodEdit(food: food))
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
    }
}

#Preview {
    let container = createTestModelContainer()
    let food = createTestCommercialFood(container.mainContext)
    return NavigationStack {
        CommercialFoodView(path: .constant([]), food: food)
    }
}
