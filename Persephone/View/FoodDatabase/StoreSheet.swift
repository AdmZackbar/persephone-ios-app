//
//  StoreSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/25/24.
//

import SwiftUI

struct StoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var modelContext
    
    let store: Store?
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("Name:")
                    TextField("required", text: $name).textInputAutocapitalization(.words)
                }
            }.navigationTitle(store == nil ? "Add Store" : "Edit Store")
                .navigationBarBackButtonHidden()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(store == nil ? "Cancel" : "Revert") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            if let store {
                                store.name = name
                            } else {
                                let store = Store(name: name)
                                modelContext.insert(store)
                            }
                            dismiss()
                        }.disabled(name.isEmpty)
                    }
                }
        }.presentationDetents([.medium])
            .onAppear {
                if let store {
                    name = store.name
                }
            }
    }
    
    init(store: Store? = nil) {
        self.store = store
    }
}

#Preview {
    StoreSheet().modelContainer(createTestModelContainer())
}
