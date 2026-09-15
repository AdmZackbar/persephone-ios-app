//
//  GroceryListView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/13/26.
//

import SwiftData
import SwiftUI

struct GroceryListView: View {
    @Query var groceryLists: [GroceryList]
    
    var body: some View {
        ListViewImpl(groceryLists: groceryLists)
    }
    
    struct ListViewImpl: View {
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
            }
        }
    }
}

struct CustomCheckbox: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            self.isOn.toggle()
        }) {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
        }
    }
}

#Preview {
    GroceryListView.ListViewImpl(groceryLists: [
        .init(store: "Costco",
             items: [
                .init(name: "Chicken Thighs"),
                .init(name: "Coke Zero"),
                .init(name: "Lightly Breaded Chicken Chunks", checked: true),
                .init(name: "Frozen Green Beans"),
                .init(name: "Ice Cream"),
             ])
    ])
}
