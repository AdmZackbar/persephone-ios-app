//
//  GroceryListView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/13/26.
//

import SwiftData
import SwiftUI

struct GroceryListView: View {
    @Query(sort: \GroceryList.store) var groceryLists: [GroceryList]
    
    var body: some View {
        SubView(groceryLists: groceryLists)
    }
    
    struct SubView: View {
        @Environment(\.modelContext) var modelContext
        @State var groceryLists: [GroceryList]
        
        var body: some View {
            Form {
                ForEach($groceryLists) { $groceryList in
                    Section(groceryList.store) {
                        List($groceryList.items, id: \.name) { $item in
                            HStack {
                                CustomCheckbox(isOn: $item.checked)
                                Text(item.name)
                                    .strikethrough(item.checked)
                            }
                        }
                    }
                }
            }.onChange(of: groceryLists) { oldValue, newValue in
                try? modelContext.save()
            }
        }
    }
}

struct CustomCheckbox: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.isOn.toggle()
            }
        }) {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
        }
    }
}

#Preview(traits: .sampleData) {
    GroceryListView()
}
