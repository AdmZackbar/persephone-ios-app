//
//  RecipeEntryEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/20/25.
//

import SwiftData
import SwiftUI

struct RecipeEntryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    @State var item: RecipeEntryItem
    @State private var sheetType: SheetType? = nil
    
    init(item: RecipeEntryItem = .init()) {
        self.item = item
    }
    
    var body: some View {
        Form {
            Section {
                DatePicker("Date:", selection: $item.date)
                TextField("Name", text: $item.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                TextField("Notes", text: $item.notes, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(4...12)
            }
            Section("Total Size") {
                let formatter = {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 2
                    formatter.zeroSymbol = ""
                    return formatter
                }()
                TextField("Servings", text: $item.total.str)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                Picker(selection: $item.total.isMass) {
                    Text("g").tag(true)
                    Text("mL").tag(false)
                } label: {
                    TextField("Total \(item.total.isMass ? "Mass" : "Volume")", value: $item.total.val, formatter: formatter)
                        .keyboardType(.decimalPad)
                }
            }
            ingredientSection()
        }.navigationTitle(item.isEdit ? "Edit Recipe Entry" : "Add Recipe Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheet(item: $sheetType) { type in
                switch type {
                case .addIngredient:
                    RecipeEntryIngredientSheet(recipeItem: $item)
                case .editIngredient(let ingredient):
                    RecipeEntryIngredientSheet(recipeItem: $item, item: .init(ingredient: ingredient))
                }
            }
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func ingredientSection() -> some View {
        Section {
            if item.ingredients.isEmpty {
                Button {
                    sheetType = .addIngredient
                } label: {
                    Label("Add Ingredient", systemImage: "plus")
                }
            } else {
                ForEach(item.ingredients, id: \.hashValue) { ingredient in
                    Button {
                        sheetType = .editIngredient(ingredient: ingredient)
                    } label: {
                        RecipeEntryIngredientListEntryView(ingredient: ingredient)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        } header: {
            if item.ingredients.isEmpty {
                Text("Ingredients")
            } else {
                Button {
                    sheetType = .addIngredient
                } label: {
                    HStack {
                        Text("Ingredients")
                        Image(systemName: "plus")
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(item.isEdit ? "Save" : "Add") {
                if let entry = item.save() {
                    modelContext.insert(entry)
                }
                navigationStore.pop()
            }.disabled(item.isInvalid)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(item.isEdit ? "Cancel" : "Back") {
                navigationStore.pop()
            }
        }
    }
    
    enum SheetType: Identifiable {
        var id: String {
            switch self {
            case .addIngredient:
                "Add"
            case .editIngredient(let ingredient):
                "Edit \(ingredient.food?.name ?? "")"
            }
        }
        
        case addIngredient
        case editIngredient(ingredient: RecipeEntryIngredient)
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        RecipeEntryEditView()
            .handleDestinations(navigationStore)
    }.environmentObject(navigationStore)
}
