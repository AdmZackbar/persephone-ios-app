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
        HStack {
            TextField("", text: Binding(get: {
                amount.value.formatted(maxDigits: 3)
            }, set: { text in
                if let value: Amount.Value = .parse(text) {
                    amount.value = value
                }
            })).font(.title)
                .fontWeight(.bold)
                .keyboardType(.numbersAndPunctuation)
            Picker("Unit", selection: Binding<String>(get: {
                amount.unit?.abbreviation ?? ""
            }, set: { unit in
                amount.unitStr = unit
            })) {
                ForEach(units, id: \.hashValue) { unit in
                    Text(unit.abbreviation).tag(unit.abbreviation)
                }
            }.onChange(of: amount.unitStr ?? "") { oldValue, newValue in
                if let x = getUnit(oldValue)?.modifier, let y = getUnit(newValue)?.modifier {
                    let scale = x / y
                    amount.value = amount.value * scale
                }
            }.pickerStyle(.segmented)
        }
    }
    
    private func getUnit(_ str: String) -> Amount.Unit? {
        units.first(where: { $0.abbreviation == str })
    }
}

#Preview {
    @Previewable @State var amount: Amount = .init(value: .raw(30.2), unit: Units.gram)
    Form {
        Text(amount.formatted(maxDigits: 7))
        ScaledAmountField(amount: $amount, units: [.init(name: "serving", abbreviation: "serving", modifier: 84.0), Units.gram])
        Button("Clear") {
            amount = .init(value: .zero, unit: .none)
        }
    }
}
