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
    
    @Binding private var foodTags: [String]
    @State private var tags: [String] = []
    @State private var customTag: String = ""
    
    init(tags: Binding<[String]>) {
        self._foodTags = tags
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                    tags = foodTags
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            foodTags = tags
                            dismiss()
                        }
                    }
                }
        }.presentationDetents([.medium])
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
    return FoodTagSheet(tags: .constant(item.metaData.tags))
        .modelContainer(container)
}
