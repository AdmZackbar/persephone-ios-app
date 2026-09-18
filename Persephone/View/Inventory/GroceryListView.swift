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
        if groceryLists.isEmpty {
            ContentUnavailableView("No Grocery Lists", systemImage: "list.clipboard")
        } else {
            SubView(groceryLists: groceryLists)
        }
    }
    
    struct SubView: View {
        @Environment(\.modelContext) var modelContext
        @State var groceryLists: [GroceryList]
        @State private var listAdd: GroceryList? = nil
        @State private var itemName: String = ""
        
        var body: some View {
            List {
                ForEach($groceryLists.enumerated(), id: \.offset) { offset, $groceryList in
                    Section {
                        ForEach($groceryList.items.enumerated(), id: \.offset) { offset, $item in
                            Button {
                                item.checked.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: item.checked ? "checkmark.square.fill" : "square")
                                    Text(item.name)
                                        .strikethrough(item.checked)
                                    Spacer()
                                }.contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }.onDelete { indices in
                            groceryList.items.remove(atOffsets: indices)
                        }.onMove { indices, offset in
                            groceryList.items.move(fromOffsets: indices, toOffset: offset)
                        }
                        Button {
                            listAdd = groceryList
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    } header: {
                        HStack {
                            TextField("Store", text: $groceryList.store, prompt: Text("Store Name"))
                            Spacer()
                            Button(role: .destructive) {
                                // TODO
                                modelContext.delete(groceryList)
                                try? modelContext.save()
                                groceryLists.remove(at: offset)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }.onChange(of: groceryLists) { oldValue, newValue in
                try? modelContext.save()
            }.alert("Item Name", isPresented: .init(get: {
                listAdd != nil
            }, set: { newValue in
                if !newValue {
                    listAdd = nil
                }
            })) {
                TextField("Name", text: $itemName)
                Button("OK") {
                    listAdd?.items.append(.init(itemName))
                    itemName = ""
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    struct GroceryItemView: View {
        @Environment(\.editMode) private var editMode
        @Binding var item: GroceryListItem
        
        var body: some View {
            if editMode?.wrappedValue.isEditing == true {
                TextField("", text: $item.name)
                    .strikethrough(item.checked)
            } else {
                Button {
                    item.checked.toggle()
                } label: {
                    HStack {
                        Image(systemName: item.checked ? "checkmark.square.fill" : "square")
                        Text(item.name)
                            .strikethrough(item.checked)
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        GroceryListView()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
    }
}
