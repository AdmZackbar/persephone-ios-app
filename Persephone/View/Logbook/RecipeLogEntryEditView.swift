//
//  RecipeLogEntryEditView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

import SwiftUI
import SwiftData

struct RecipeLogEntryEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var item: RecipeLogEntryItem
    @State private var unit: Amount.Unit? = nil
    @State private var sheetType: SheetType? = nil
    
    init(item: RecipeLogEntryItem = .init()) {
        self.item = item
    }
    
    var body: some View {
        Form {
            DatePicker("Date:", selection: $item.date)
            Picker("Meal:", selection: $item.meal) {
                ForEach(LogbookView.Meals, id: \.hashValue) { meal in
                    Text(meal).tag(meal)
                }
            }
            Section("Recipe") {
                if let recipe = item.recipe {
                    let units: [Amount.Unit] = {
                        let servingUnit = Amount.Unit(name: "Serving", abbreviation: recipe.total.amount.unit?.abbreviation ?? "serving", modifier: recipe.total.val / recipe.total.amount.value.raw)
                        if recipe.total.isMass {
                            return [servingUnit, Units.gram, Units.ounce, Units.pound]
                        } else {
                            return [servingUnit, Units.milliliter, Units.fluidounce]
                        }
                    }()
                    AmountField(amount: Binding(get: {
                        if let modifier = unit?.modifier {
                            return .init(value: .raw(recipe.total.val * modifier * item.amountScale), unitStr: unit!.abbreviation)
                        }
                        return recipe.total.amount * item.amountScale
                    }, set: { value in
                        unit = value.unit
                        if let modifier = value.unit?.modifier {
                            item.amountScale = value.value.raw * modifier / recipe.total.val
                        } else {
                            item.amountScale = value.value.raw / recipe.total.amount.value.raw
                        }
                    }), units: units)
                }
                Button {
                    sheetType = .recipe
                } label: {
                    recipeView().contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.navigationTitle(item.isEdit ? "Edit Entry" : "Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: item.recipe) { oldValue, newValue in
                if let newValue {
                    // TODO
                    item.amountScale = 1 / newValue.totalNumServings
                }
            }
            .sheet(item: $sheetType) { type in
                switch type {
                case .recipe:
                    SelectRecipeEntrySheet(selection: $item.recipe)
                }
            }
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func recipeView() -> some View {
        if let recipe = item.recipe {
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text((recipe.total * item.amountScale).amount.formatted(includeSpace: true))
                        Text("(\((recipe.total * item.amountScale).value.formatted()))")
                    }.font(.subheadline)
                        .fontWeight(.semibold)
                    if let totalCost = recipe.cost {
                        Text((totalCost * item.amountScale).formatted())
                            .font(.subheadline)
                            .italic()
                    }
                    Gauge(value: recipe.remainingScale - item.amountScale, in: 0...1) {
                        EmptyView()
                    }
                    Spacer()
                }.padding(.top, 8)
                Spacer()
                NutrientPieChart(nutrients: recipe.nutrients * item.amountScale)
                    .frame(width: 120, height: 120)
            }
        } else {
            HStack {
                Text("Select Recipe")
                Spacer()
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(item.isEdit ? "Save" : "Add") {
                if let recipe = item.save() {
                    modelContext.insert(recipe)
                }
                dismiss()
            }.disabled(item.isInvalid)
        }
    }
    
    private enum SheetType: String, Identifiable {
        var id: String {
            rawValue
        }
        
        case recipe
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        RecipeLogEntryEditView(item: .init(meal: "Breakfast"))
    }.environmentObject(navigationStore)
}
