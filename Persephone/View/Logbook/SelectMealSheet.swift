//
//  SelectMealSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 4/24/26.
//

import SwiftData
import SwiftUI

struct SelectMealSheet: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Meal.name) var meals: [Meal]
    
    var isFiltered: Bool {
        !filter.isEmpty
    }
    
    @Binding private var selection: Meal?
    @State private var searchPresented: Bool = false
    @State private var filter: String = ""
    
    init(selection: Binding<Meal?>) {
        self._selection = selection
    }
    
    var body: some View {
        NavigationStack {
            Form {
                let e: [Meal] = {
                    if isFiltered {
                        return meals.filter({ $0.name.localizedCaseInsensitiveContains(filter) })
                    }
                    return meals
                }()
                if e.isEmpty {
                    let reason = {
                        if meals.isEmpty {
                            "No Meals in DB"
                        } else {
                            "No Meals Matching \(filter)"
                        }
                    }()
                    Text(reason)
                } else {
                    if isFiltered || searchPresented {
                        mealsView(e)
                    } else {
                        Section("Meals") {
                            mealsView(e)
                        }
                    }
                }
            }.navigationTitle("Select Meal")
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
    private func mealsView(_ meals: [Meal]) -> some View {
        ForEach(meals) { meal in
            Button {
                selection = meal
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(meal.creationDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .italic()
                        Text(meal.name)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @State var selection: Meal? = nil
    @Previewable @State var showing: Bool = false
    Form {
        Button(selection?.name ?? "No Selection") {
            showing = true
        }
        Button("Clear") {
            selection = nil
        }
    }.sheet(isPresented: $showing) {
        SelectMealSheet(selection: $selection)
    }
}
