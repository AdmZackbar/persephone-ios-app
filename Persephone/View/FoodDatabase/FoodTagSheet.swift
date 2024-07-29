//
//  FoodTagSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/28/24.
//

import SwiftData
import SwiftUI

struct FoodTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: FoodItem
    
    @State private var tags: [String] = []
    @State private var customTag: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                createDefaultTagMenu()
                HStack {
                    TextField("Custom tag", text: $customTag).onSubmit(addCustomTag)
                    Button(action: addCustomTag) {
                        Label("Add", systemImage: "plus").labelStyle(.iconOnly)
                    }.disabled(customTag == "" || !tags.allSatisfy({ t in t != customTag }))
                }
                Section("Tags") {
                    if tags.isEmpty {
                        Text("No tags").italic().opacity(0.5)
                    } else {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                        }.onDelete(perform: { indexSet in
                            for index in indexSet {
                                tags.remove(at: index)
                            }
                        })
                    }
                }
            }.navigationTitle("Food Tags")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .onAppear {
                    tags = item.metaData.tags
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            item.metaData.tags = tags
                            dismiss()
                        }
                    }
                }
        }.presentationDetents([.medium])
    }
    
    private func createDefaultTagMenu() -> some View {
        Menu("Add Default Tag...") {
            createButton("Dairy")
            Menu("Drinks") {
                Menu("Alcohol") {
                    createButton("Alcohol")
                    Divider()
                    createButton("Beer")
                    createButton("Spirits")
                    createButton("Wine")
                }
                createButton("Coffee")
                createButton("Cola")
                createButton("Energy Drink")
                createButton("Juice")
                createButton("Milk")
                createButton("Sports Drink")
                createButton("Tea")
            }
            createButton("Fruit")
            Menu("Grains") {
                createButton("Bread")
            }
            Menu("Meats") {
                createButton("Meat")
                Divider()
                createButton("Beef")
                createButton("Chicken")
                createButton("Fish")
                createButton("Lamb")
                createButton("Pork")
                createButton("Turkey")
            }
            createButton("Vegetable")
        }
    }
    
    private func createButton(_ name: String) -> some View {
        Button(name) {
            tags.append(name)
        }.disabled(tags.contains(where: { tag in tag == name }))
    }
    
    private func addCustomTag() {
        if customTag != "" && tags.allSatisfy({ t in t != customTag }) {
            tags.append(customTag)
            customTag = ""
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    let item = createTestFoodItem(container.mainContext)
    return FoodTagSheet(item: item)
        .modelContainer(container)
}
