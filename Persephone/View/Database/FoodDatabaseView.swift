//
//  FoodDatabaseView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import SwiftData
import SwiftUI

struct FoodDatabaseView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Food.name) private var foods: [Food]
    
    @StateObject private var navigationStore = NavigationStore()
    
    @State private var foodState: FoodState = .active
    @State private var filter: String = ""
    @State private var confirmDelete = false
    @State private var deleteItem: Food? = nil
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            Form {
                ForEach(foods.filter(foodState.isFiltered).filter({ filter.isEmpty || $0.contains(filter) }), id: \.hashValue) { food in
                    Button {
                        navigationStore.push(FoodViewType.viewFood(food))
                    } label: {
                        foodEntryView(food)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .swipeActions(allowsFullSwipe: false) {
                            deleteButton(food).tint(.red)
                            editButton(food).tint(.blue)
                        }
                        .contextMenu {
                            editButton(food)
                            deleteButton(food)
                        } preview: {
                            FoodPreview(food: food)
                                .padding()
                        }
                }
            }.navigationTitle("Food Database")
                .toolbar(content: toolbarContent)
                .handleDestinations(navigationStore)
                .confirmationDialog("Delete Food", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive) {
                        if let deleteItem {
                            modelContext.delete(deleteItem)
                        }
                    }
                }
        }.environmentObject(navigationStore)
            .searchable(text: $filter)
    }
    
    @ViewBuilder
    private func foodEntryView(_ food: Food) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.name)
                    .font(.headline)
                if let brand = food.brand {
                    Text(brand)
                        .font(.subheadline)
                        .italic()
                }
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private func editButton(_ food: Food) -> some View {
        Button {
            navigationStore.push(FoodViewType.editFood(food))
        } label: {
            Label("Edit", systemImage: "pencil")
        }
    }
    
    @ViewBuilder
    private func deleteButton(_ food: Food) -> some View {
        Button {
            deleteItem = food
            confirmDelete = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Picker("", selection: $foodState) {
                ForEach(FoodState.allCases, id: \.hashValue) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }.pickerStyle(.segmented)
                .frame(width: 160)
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                navigationStore.push(FoodViewType.addFood)
            } label: {
                Label("Add Food", systemImage: "plus").labelStyle(.iconOnly)
            }
        }
    }
    
    private enum FoodState: String, CaseIterable {
        case active
        case retired
        
        func isFiltered(_ food: Food) -> Bool {
            switch self {
            case .active:
                !food.isRetired
            case .retired:
                food.isRetired
            }
        }
    }
}

enum FoodViewType: Hashable {
    case viewFood(_ food: Food)
    case addFood
    case editFood(_ food: Food)
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    FoodDatabaseView()
}
