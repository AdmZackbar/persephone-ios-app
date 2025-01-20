//
//  CookbookView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/20/25.
//

import SwiftData
import SwiftUI

struct CookbookView: View {
    @StateObject private var navigationStore = NavigationStore()
    
    @State private var viewType: ViewType = .current
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            Form {
                Section("Recipes") {
                    switch viewType {
                    case .current:
                        CurrentRecipeEntryView()
                    case .past:
                        OldRecipeEntryView()
                    }
                }.headerProminence(.increased)
            }.navigationTitle("Cookbook")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbarContent)
                .handleDestinations(navigationStore)
        }.environmentObject(navigationStore)
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Picker("", selection: $viewType) {
                ForEach(ViewType.allCases, id: \.hashValue) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }.pickerStyle(.segmented)
                .frame(width: 160)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                Button("Recipe Entry") {
                    navigationStore.push(CookbookViewType.addEntry)
                }
            } label: {
                Label("Add...", systemImage: "plus").labelStyle(.iconOnly)
            }
        }
    }
    
    private enum ViewType: String, CaseIterable {
        case current
        case past
    }
}

private struct CurrentRecipeEntryView: View {
    @Query(filter: #Predicate { $0.remainingScale > 0 },
           sort: \RecipeEntry.date,
           order: .reverse) private var recipeEntries: [RecipeEntry]
    
    var body: some View {
        if recipeEntries.isEmpty {
            Text("No Remaining Entries")
        } else {
            ForEach(recipeEntries, id: \.hashValue, content: RecipeEntryButton.init)
        }
    }
}

private struct OldRecipeEntryView: View {
    @Query(filter: #Predicate { $0.remainingScale <= 0 },
           sort: \RecipeEntry.date,
           order: .reverse) private var recipeEntries: [RecipeEntry]
    
    var body: some View {
        if recipeEntries.isEmpty {
            Text("No Old Entries")
        } else {
            ForEach(recipeEntries, id: \.hashValue, content: RecipeEntryButton.init)
        }
    }
}

private struct RecipeEntryButton: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let entry: RecipeEntry
    
    init(_ entry: RecipeEntry) {
        self.entry = entry
    }
    
    var body: some View {
        Button {
            navigationStore.push(CookbookViewType.viewEntry(entry))
        } label: {
            buttonView()
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .swipeActions(allowsFullSwipe: false) {
                deleteButton().tint(.red)
                editButton().tint(.blue)
            }
            .contextMenu {
                editButton()
                deleteButton()
            } preview: {
                RecipeEntryPreview(entry: entry)
                    .padding()
            }
        
    }
    
    private func editButton() -> some View {
        Button {
            navigationStore.push(CookbookViewType.editEntry(entry))
        } label: {
            Label("Edit", systemImage: "pencil.circle")
        }
    }
    
    private func deleteButton() -> some View {
        Button(role: .destructive) {
            withAnimation {
                modelContext.delete(entry)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func buttonView() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .opacity(0.7)
                    .italic()
                    .fontWeight(.semibold)
                Text(entry.name)
                    .font(.title3)
                    .bold()
                Text(entry.total.formatted())
                    .font(.subheadline)
            }
            Spacer()
            Gauge(value: entry.remainingScale, in: 0...1) {
                Text(entry.remaining.value.formatted(maxDigits: 0))
            }.gaugeStyle(.accessoryCircularCapacity)
        }
    }
}

enum CookbookViewType: Hashable {
    case viewEntry(_ entry: RecipeEntry)
    case addEntry
    case editEntry(_ entry: RecipeEntry)
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    CookbookView()
}
