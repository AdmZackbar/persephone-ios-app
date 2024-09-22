//
//  CommercialFoodEditor.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/13/24.
//

import SwiftUI

struct CommercialFoodEditor: View {
    enum Mode {
        case Add
        case Edit
        
        func getTitle() -> String {
            switch self {
            case .Add:
                "Add Food"
            case .Edit:
                "Edit Food"
            }
        }
        
        func getBackText() -> String {
            switch self {
            case .Add:
                "Back"
            case .Edit:
                "Discard"
            }
        }
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    
    @Binding private var path: [FoodDatabaseView.ViewType]
    let mode: Mode
    var food: CommercialFood
    
    @State private var name: String = ""
    @State private var seller: String = ""
    @State private var cost: Int = 0
    @State private var nutrients: NutritionDict = [:]
    @State private var notes: String = ""
    @State private var rating: Double? = nil
    @State private var tags: [String] = []
    
    init(path: Binding<[FoodDatabaseView.ViewType]>, food: CommercialFood? = nil) {
        self._path = path
        if let food {
            mode = .Edit
            self.food = food
        } else {
            mode = .Add
            self.food = CommercialFood(name: "", seller: "", cost: .Cents(0), nutrients: [:], metaData: CommercialFood.MetaData(notes: "", rating: nil, tags: []))
        }
    }
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        Form {
            HStack {
                Text("Name:")
                TextField("required", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            HStack {
                Text("Seller:")
                TextField("required", text: $seller)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            CurrencyTextField(numberFormatter: formatter, value: $cost)
            TextField("notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
            Section("Nutrients") {
                NutrientTableView(nutrients: nutrients)
                    .onTapGesture {
                        sheetCoordinator.presentSheet(.Nutrients(nutrients: $nutrients))
                    }
            }
            Section("Tags") {
                Text(tags.isEmpty ? "No tags" : tags.joined(separator: ","))
                    .onTapGesture {
                        sheetCoordinator.presentSheet(.Tags(tags: $tags))
                    }
            }
            Section("Rating") {
                Picker("", selection: $rating) {
                    Text("N/A").tag(nil as Double?)
                    ForEach(RatingTier.allCases) { tier in
                        Text(tier.rawValue).tag(tier.rating as Double?)
                    }
                }.pickerStyle(.segmented)
            }
        }.navigationTitle(mode.getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear {
                switch mode {
                case .Edit:
                    name = food.name
                    seller = food.seller
                    switch food.cost {
                    case .Cents(let cents):
                        cost = cents
                    }
                    nutrients = food.nutrients
                    notes = food.metaData.notes
                    rating = food.metaData.rating
                    tags = food.metaData.tags
                default:
                    break
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(mode.getBackText()) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save", action: save)
                        .disabled(name.isEmpty || seller.isEmpty || cost < 0)
                }
            }
            .sheetCoordinating(coordinator: sheetCoordinator)
    }
    
    private func save() {
        food.name = name
        food.seller = seller
        food.cost = .Cents(cost)
        food.nutrients = nutrients
        food.metaData = CommercialFood.MetaData(notes: notes, rating: rating, tags: tags)
        switch mode {
        case .Add:
            modelContext.insert(food)
            path.removeLast()
            path.append(.CommercialFoodView(food: food))
        case .Edit:
            dismiss()
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let food = createTestCommercialFood(container.mainContext)
    return NavigationStack {
        CommercialFoodEditor(path: .constant([]), food: food)
    }
}
