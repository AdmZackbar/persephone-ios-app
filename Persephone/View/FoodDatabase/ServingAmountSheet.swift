//
//  ServingAmountSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/27/24.
//

import SwiftUI

struct ServingAmountSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding private var totalAmount: Double
    @Binding private var numServings: Double
    @State private var servingAmount: Double
    
    init(totalAmount: Binding<Double>, numServings: Binding<Double>) {
        self._totalAmount = totalAmount
        self._numServings = numServings
        self.servingAmount = totalAmount.wrappedValue / numServings.wrappedValue
    }
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 5
        formatter.zeroSymbol = ""
        formatter.groupingSeparator = ""
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Serving Size") {
                    TextField("", value: $servingAmount, formatter: formatter)
                        .keyboardType(.decimalPad)
                }
                Section("Total Size") {
                    Text("\(formatter.string(for: totalAmount)!) -> \(formatter.string(for: servingAmount * numServings)!)")
                    Button("Set Total Size") {
                        totalAmount = servingAmount * numServings
                        dismiss()
                    }.disabled(servingAmount <= 0 || servingAmount == totalAmount / numServings)
                }
                Section("Number of Servings") {
                    Text("\(formatter.string(for: numServings)!) -> \(formatter.string(for: totalAmount / servingAmount)!)")
                    Button("Set Number of Servings") {
                        numServings = totalAmount / servingAmount
                        dismiss()
                    }.disabled(servingAmount <= 0 || servingAmount == totalAmount / numServings)
                }
            }.navigationTitle("Serving Size Adjustment")
                .navigationBarTitleDisplayMode(.inline)
        }.presentationDetents([.medium])
    }
}

#Preview {
    ServingAmountSheet(totalAmount: .constant(100), numServings: .constant(5))
}
