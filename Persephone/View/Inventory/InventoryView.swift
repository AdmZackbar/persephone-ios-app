//
//  InventoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/31/24.
//

import SwiftData
import SwiftUI

struct InventoryView: View {
    @Environment(\.modelContext) var modelContext
    @Query var foodInstances: [FoodInstance]
    @Query(sort: \CookedFood.date, order: .reverse) var cookedFood: [CookedFood]
    
    enum ViewType: Hashable {
        case AddItem
        case InstanceView(item: FoodInstance)
        case viewCookedFood(food: CookedFood)
        case addCookedFood
        case editCookedFood(food: CookedFood)
    }
    
    @StateObject private var navigationStore = NavigationStore()
    @State private var searchText: String = ""
    
    var body: some View {
        return NavigationStack(path: $navigationStore.path) {
            Form {
                foodSection()
                cookedFoodSection()
            }.searchable(text: $searchText)
                .navigationTitle("Inventory")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                navigationStore.push(ViewType.AddItem)
                            } label: {
                                Label("Add Food", systemImage: "fork.knife")
                            }
                            Button {
                                navigationStore.push(ViewType.addCookedFood)
                            } label: {
                                Label("Add Cooked Food", systemImage: "list.bullet.rectangle.portrait")
                            }
                        } label: {
                            Label("Add...", systemImage: "plus")
                        }
                    }
                }
                .navigationDestination(for: ViewType.self, destination: handleNavigation)
        }.environmentObject(navigationStore)
    }
    
    @ViewBuilder
    private func foodSection() -> some View {
        let items = foodInstances.filter({ isFiltered($0) })
        Section("Food") {
            if items.isEmpty {
                Text("No food on record")
            } else {
                ForEach(items, id: \.hashValue) { food in
                    Button {
                        navigationStore.push(ViewType.InstanceView(item: food))
                    } label: {
                        HStack {
                            Text(food.foodItem.name)
                            Spacer()
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .contextMenu {
                        Button {
                            navigationStore.push(ViewType.InstanceView(item: food))
                        } label: {
                            Label("View", image: "magnifyingglass")
                        }
                        Button(role: .destructive) {
                            modelContext.delete(food)
                        } label: {
                            Label("Delete", image: "trash.fill")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func cookedFoodSection() -> some View {
        Section("Cooked Food") {
            ForEach(cookedFood, id: \.hashValue) { food in
                Button {
                    navigationStore.push(ViewType.viewCookedFood(food: food))
                } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(food.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                            Text(food.name)
                                .font(.subheadline)
                            if let cost = food.totalCost {
                                Text(cost.toString())
                                    .font(.subheadline)
                                    .italic()
                            }
                        }
                        Spacer()
                        Gauge(value: food.remaining, in: 0...food.total) {
                            Text("\(food.remaining.formatted())g")
                        }.gaugeStyle(.accessoryCircularCapacity)
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain).contextMenu {
                    Button(role: .destructive) {
                        modelContext.delete(food)
                    } label: {
                        Label("Delete", image: "trash.fill")
                    }
                }
            }
        }
    }
    
    private func isFiltered(_ item: FoodInstance) -> Bool {
        if searchText.isEmpty {
            return true
        }
        return item.foodItem.name.localizedCaseInsensitiveContains(searchText)
    }
    
    @ViewBuilder
    private func handleNavigation(viewType: ViewType) -> some View {
        switch viewType {
        case .AddItem:
            AddFoodInstanceView()
        case .InstanceView(let item):
            InventoryFoodView(item: item)
        case .viewCookedFood(let food):
            CookedFoodView(cookedFood: food)
        case .addCookedFood:
            CookedFoodEditView(item: .init())
        case .editCookedFood(let food):
            CookedFoodEditView(item: .init(cookedFood: food))
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    InventoryView()
}
