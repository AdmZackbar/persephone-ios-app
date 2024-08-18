//
//  InventoryFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/31/24.
//

import SwiftUI

struct InventoryFoodView: View {
    let item: FoodInstance
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.foodItem.metaData.brand ?? "Custom").font(.headline)
                    if !item.foodItem.metaData.tags.isEmpty {
                        Label(item.foodItem.metaData.tags.joined(separator: ", "), systemImage: "tag.fill").italic()
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    switch item.origin {
                    case .Store(let store, let price):
                        Text(store).font(.headline)
                        Text(price.toString()).italic()
                    case .Gift(let from):
                        Text("Gift from \(from)")
                    case .Grown(let location):
                        Text("Grown at \(location)")
                    }
                }
            }
            switch item.amount {
            case .Single(let total, let remaining):
                Gauge(value: remaining.value.toValue(), in: 0...total.value.toValue()) {
                    
                } currentValueLabel: {
                    Text("\(formatter.string(for: remaining.value)!) \(remaining.unit.getAbbreviation())")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(formatter.string(for: total.value)!) \(total.unit.getAbbreviation())")
                }
            case .Collection(let total, let remaining):
                Gauge(value: Double(total) / Double(remaining)) {
                    
                } currentValueLabel: {
                    Text("\(remaining)")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(total)")
                }
            }
            HStack(spacing: 2) {
                Spacer()
                createDateView(item.dates.acqDate, field: getAcqField())
                Spacer()
                if item.dates.freezeDate != nil {
                    createDateView(item.dates.freezeDate!, field: "Freeze")
                    Spacer()
                }
                createDateView(item.dates.acqDate, field: "Expires")
                Spacer()
                
            }
            Spacer()
        }.navigationBarTitleDisplayMode(.inline)
            .padding()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(item.foodItem.name).font(.title3).bold()
                }
            }
    }
    
    private func getAcqField() -> String {
        switch item.origin {
        case .Store(_, _):
            "Bought"
        case .Gift(_):
            "Gift"
        case .Grown(_):
            "Grown"
        }
    }
    
    // TODO use days/months ago?
    private func createDateView(_ date: Date, field: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text("\(date.formatted(date: .numeric, time: .omitted))").font(.subheadline).bold()
            Text(field.uppercased()).font(.caption)
        }
    }
}

// TODO
struct FoodAmountGaugeStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(.black, lineWidth: 8)
                .rotationEffect(.degrees(180))
            configuration.currentValueLabel
        }.frame(width: 200, height: 200)
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodInstance(container.mainContext)
    return NavigationStack {
        InventoryFoodView(item: item)
    }.modelContainer(container)
}
