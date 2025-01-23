//
//  OptionalDatePicker.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/21/25.
//

import SwiftUI

struct OptionalDatePicker: View {
    var text: String
    
    @Binding private var selection: Date?
    @State private var prevDate: Date
    
    init(text: String, selection: Binding<Date?>) {
        self.text = text
        self._selection = selection
        self.prevDate = selection.wrappedValue ?? .now
    }
    
    var body: some View {
        Toggle(isOn: Binding(get: {
            selection != nil
        }, set: { value in
            selection = value ? prevDate : nil
        })) {
            if selection != nil {
                DatePicker(text, selection: Binding(get: {
                    selection ?? prevDate
                }, set: { value in
                    selection = value
                    prevDate = value
                }), displayedComponents: .date)
            } else {
                Text(text)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: Date? = nil
    Form {
        OptionalDatePicker(text: "Retired:", selection: $selection)
    }
}
