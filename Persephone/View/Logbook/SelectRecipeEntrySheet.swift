//
//  SelectRecipeEntrySheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/22/25.
//

import SwiftData
import SwiftUI

struct SelectRecipeEntrySheet: View {
    @Environment(\.dismiss) var dismiss
    // TODO
    @Query(filter: #Predicate { !$0.retired },
           sort: \RecipeEntry.date, order: .reverse) var entries: [RecipeEntry]
    
    var isFiltered: Bool {
        !filter.isEmpty
    }
    
    @Binding private var selection: RecipeEntry?
    @State private var searchPresented: Bool = false
    @State private var filter: String = ""
    
    init(selection: Binding<RecipeEntry?>) {
        self._selection = selection
    }
    
    var body: some View {
        NavigationStack {
            Form {
                let e: [RecipeEntry] = {
                    if isFiltered {
                        return entries.filter({ $0.name.localizedCaseInsensitiveContains(filter) })
                    }
                    return entries
                }()
                if e.isEmpty {
                    let reason = {
                        if entries.isEmpty {
                            "No Recipe Entries in DB"
                        } else {
                            "No Recipes Matching \(filter)"
                        }
                    }()
                    Text(reason)
                } else {
                    if isFiltered || searchPresented {
                        recipeEntriesView(e)
                    } else {
                        Section("Recipe Entries") {
                            recipeEntriesView(e)
                        }
                    }
                }
            }.navigationTitle("Select Recipe")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            selection = nil
                            dismiss()
                        }.disabled(selection == nil)
                    }
                }
        }.searchable(text: $filter, isPresented: $searchPresented)
    }
    
    @ViewBuilder
    private func recipeEntriesView(_ entries: [RecipeEntry]) -> some View {
        ForEach(entries, id: \.hashValue) { entry in
            Button {
                selection = entry
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .italic()
                        Text(entry.name)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @State var selection: RecipeEntry? = nil
    @Previewable @State var showing: Bool = false
    Form {
        Button(selection?.name ?? "No Selection") {
            showing = true
        }
        Button("Clear") {
            selection = nil
        }
    }.sheet(isPresented: $showing) {
        SelectRecipeEntrySheet(selection: $selection)
    }
}
