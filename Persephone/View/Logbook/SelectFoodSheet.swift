//
//  SelectFoodSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/18/25.
//

import SwiftData
import SwiftUI

struct SelectFoodSheet: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Food.name) var foods: [Food]
    
    let suggestedFoods: [Food]
    
    var isFiltered: Bool {
        filter.count > 1
    }
    
    @Binding private var selection: Food?
    @State private var searchPresented: Bool = false
    @State private var filter: String = ""
    
    init(selection: Binding<Food?>, suggestedFoods: [Food] = []) {
        self._selection = selection
        self.suggestedFoods = suggestedFoods
    }
    
    var body: some View {
        NavigationStack {
            Form {
                let f: [Food] = {
                    if isFiltered {
                        return foods.filter({ $0.contains(filter) })
                    }
                    return suggestedFoods
                }()
                if f.isEmpty {
                    let reason = {
                        if foods.isEmpty {
                            "No Foods in DB"
                        } else if isFiltered {
                            "No Foods Matching \(filter)"
                        } else {
                            "No Suggested Foods"
                        }
                    }()
                    Text(reason)
                } else {
                    if isFiltered || searchPresented {
                        foodsView(f)
                    } else {
                        Section("Recent Foods") {
                            foodsView(f)
                        }
                    }
                }
            }.navigationTitle("Select Food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            selection = nil
                            dismiss()
                        }.disabled(selection == nil)
                    }
                }
        }.searchable(text: $filter, isPresented: $searchPresented)
    }
    
    @ViewBuilder
    private func foodsView(_ foods: [Food]) -> some View {
        ForEach(foods, id: \.hashValue) { food in
            Button {
                selection = food
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        if let brand = food.brand {
                            Text(brand)
                                .font(.caption)
                                .italic()
                        }
                        Text(food.name)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @State var selection: Food? = nil
    @Previewable @State var showing: Bool = false
    Form {
        Button(selection?.name ?? "No Selection") {
            showing = true
        }
        Button("Clear") {
            selection = nil
        }
    }.sheet(isPresented: $showing) {
        SelectFoodSheet(selection: $selection)
    }
}
