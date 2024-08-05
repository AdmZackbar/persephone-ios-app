//
//  RecipeTagSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/4/24.
//

import SwiftUI

struct RecipeTagSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding private var tagBinding: [String]
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
                    tags = tagBinding
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            tagBinding = tags
                            dismiss()
                        }
                    }
                }
        }.presentationDetents([.medium])
    }
    
    private func createDefaultTagMenu() -> some View {
        Menu("Add Default Tag...") {
            Menu("Baking") {
                createButton("Bread")
                createButton("Cookies")
                createButton("Cakes")
                createButton("Pies")
                createButton("Pastries")
            }
            Menu("Meat") {
                createButton("Beef")
                createButton("Chicken")
                createButton("Pork")
            }
            createButton("Vegetables")
            Menu("Type") {
                createButton("Entree")
                createButton("Side Dish")
                createButton("Dessert")
                createButton("Appetizer")
                createButton("Snack")
                createButton("Beverage")
                createButton("Sauce")
                createButton("Marinade")
            }
            Menu("Equipment") {
                createButton("Airfryer")
                createButton("Grill")
                createButton("Oven")
                createButton("Stovetop")
                createButton("Microwave")
            }
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
    
    init(tags: Binding<[String]>) {
        self._tagBinding = tags
    }
}

#Preview {
    RecipeTagSheet(tags: .constant([]))
}
