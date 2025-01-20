//
//  AmountField 2.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/18/25.
//


import SwiftUI

struct ScaledAmountField: View {
    private let units: [Amount.Unit]
    @Binding private var amount: Amount
    
    init(amount: Binding<Amount>, units: [Amount.Unit] = []) {
        self._amount = amount
        self.units = units
    }
    
    var body: some View {
        Picker(selection: Binding<String>(get: {
            amount.unit?.abbreviation ?? ""
        }, set: { unit in
            amount.unitStr = unit
        })) {
            ForEach(units, id: \.hashValue) { unit in
                Text(unit.abbreviation).tag(unit.abbreviation)
            }
        } label: {
            TextField("", text: Binding(get: {
                amount.value.formatted()
            }, set: { text in
                if let value: Amount.Value = .parse(text) {
                    amount.value = value
                }
            }))
        }.onChange(of: amount.unitStr ?? "") { oldValue, newValue in
            if let x = getUnit(oldValue)?.modifier, let y = getUnit(newValue)?.modifier {
                let scale = x / y
                amount.value = amount.value * scale
            }
        }
    }
    
    private func getUnit(_ str: String) -> Amount.Unit? {
        units.first(where: { $0.abbreviation == str })
    }
}

#Preview {
    @Previewable @State var amount: Amount = .init(value: .raw(30.2), unit: Units.gram)
    Form {
        Text(amount.formatted(includeSpace: true))
        ScaledAmountField(amount: $amount, units: [.init(name: "serving", abbreviation: "serving", modifier: 84.0), Units.gram, Units.ounce])
        Button("Clear") {
            amount = .init(value: .zero, unit: .none)
        }
    }
}
