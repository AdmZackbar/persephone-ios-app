//
//  AmountField.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/18/25.
//

import SwiftUI

struct AmountField: View {
    private let units: [Amount.Unit]
    @Binding private var amount: Amount
    
    init(amount: Binding<Amount>, units: [Amount.Unit] = []) {
        self._amount = amount
        self.units = units
    }
    
    var body: some View {
        Picker(selection: Binding<String>(get: {
            amount.unitStr ?? ""
        }, set: { unit in
            amount.unitStr = unit
        })) {
            ForEach(units, id: \.hashValue) { unit in
                Text(unit.abbreviation).tag(unit.abbreviation)
            }
        } label: {
            TextField("", text: Binding(get: {
                amount.value.formatted(maxDigits: 7)
            }, set: { text in
                if let value: Amount.Value = .parse(text) {
                    amount.value = value
                }
            }))
        }
    }
}

#Preview {
    @Previewable @State var amount: Amount = .init(value: .raw(30.2), unit: .gram)
    Form {
        Text(amount.formatted(maxDigits: 7))
        AmountField(amount: $amount, units: [.gram, .milliliter])
        Button("Clear") {
            amount = .init(value: .zero, unit: .none)
        }
    }
}
