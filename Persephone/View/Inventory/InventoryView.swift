//
//  InventoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/8/26.
//

import SwiftData
import SwiftUI

struct InventoryView: View {
    @StateObject private var navigationStore = NavigationStore()
    
    @Query(sort: \FoodInstance.acquireDate, order: .reverse)
    private var instances: [FoodInstance]
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            Form {
                ForEach(instances, id: \.id) { instance in
                    Button {
                        // TODO
                    } label: {
                        instanceListView(instance)
                    }.buttonStyle(.plain)
                }
            }.navigationTitle("Inventory")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            navigationStore.push(InventoryViewType.addFood)
                        } label: {
                            Label("Add Food", systemImage: "plus")
                        }
                    }
                }
                .handleDestinations(navigationStore)
        }.environmentObject(navigationStore)
    }
    
    private func instanceListView(_ instance: FoodInstance) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(instance.food.name)
                    .bold()
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        if let brand = instance.food.brand {
                            Text(brand).italic()
                        }
                        Text(instance.acquireDate.formatted())
                            .fontWeight(.light)
                    }.font(.subheadline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(instance.remaining.amount.formatted(maxDigits: 1))
                        Text(instance.remaining.value.formatted())
                    }.font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            Gauge(value: instance.remainder, in: 0...1.0) {
                Text(instance.remainder.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline)
            }.gaugeStyle(.accessoryCircularCapacity)
        }
    }
}

enum InventoryViewType: Hashable {
    case addFood
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    InventoryView()
}
