//
//  MealEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 4/24/26.
//

import SwiftData
import SwiftUI

struct MealEditView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    @State var meal: MealEditItem
    @State private var sheetType: SheetType? = nil
    
    init(meal: MealEditItem = .init()) {
        self.meal = meal
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $meal.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                TextField("Notes", text: $meal.notes, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(4...12)
            }
            ingredientSection()
        }.navigationTitle(meal.isEdit ? "Edit Meal" : "Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheet(item: $sheetType) { type in
                switch type {
                case .add:
                    MealItemSheet(meal: $meal)
                case .edit(let item):
                    MealItemSheet(meal: $meal, item: .init(item: item))
                }
            }
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func ingredientSection() -> some View {
        Section {
            if meal.items.isEmpty {
                Button {
                    sheetType = .add
                } label: {
                    Label("Add Food", systemImage: "plus")
                }
            } else {
                ForEach(meal.items, id: \.hashValue) { item in
                    Button {
                        sheetType = .edit(item: item)
                    } label: {
                        foodItemEntry(item)
                    }.buttonStyle(.plain)
                }
            }
        } header: {
            if meal.items.isEmpty {
                Text("Foods")
            } else {
                Button {
                    sheetType = .add
                } label: {
                    HStack {
                        Text("Foods")
                        Spacer()
                        Image(systemName: "plus")
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
    }
    
    private func foodItemEntry(_ item: MealItem) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(item.food.name)
                    .font(.headline)
                if let brand = item.food.brand {
                    Text(brand)
                        .font(.subheadline)
                        .italic()
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text((item.food.servingSize * item.numServings).formatted())
                    .font(.subheadline)
                if let cost = item.cost {
                    Text(cost.formatted())
                        .font(.subheadline)
                }
            }
        }.contentShape(Rectangle())
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                if let entry = meal.save() {
                    modelContext.insert(entry)
                }
                navigationStore.pop()
            } label: {
                if meal.isEdit {
                    Label("Save", systemImage: "checkmark")
                } else {
                    Label("Add", systemImage: "plus")
                }
            }.disabled(meal.isInvalid)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button {
                navigationStore.pop()
            } label: {
                if meal.isEdit {
                    Label("Cancel", systemImage: "xmark")
                } else {
                    Label("Back", systemImage: "xmark")
                }
            }
        }
    }
    
    enum SheetType: Identifiable {
        var id: String {
            switch self {
            case .add:
                "Add"
            case .edit(let item):
                "Edit \(item.food?.name ?? "")"
            }
        }
        
        case add
        case edit(item: MealItem)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        MealEditView()
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
