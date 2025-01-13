//
//  LogCategoryView.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import SwiftData
import SwiftUI

struct LogCategoryView: View {
    @Query(sort: \LogFoodItemEntry.date) var foodItems: [LogFoodItemEntry]
    
    @EnvironmentObject
    private var navigationStore: NavigationStore
    
    var body: some View {
        let items = foodItems.filter({ navigationStore.logConfig.contains($0.date) && navigationStore.logConfig.selectedType == $0.type }).filter({ navigationStore.logConfig.selectedCategory == nil || $0.category == navigationStore.logConfig.selectedCategory })
        VStack(spacing: 0) {
            HStack {
                Button {
                    navigationStore.logConfig.prev()
                } label: {
                    Label("Prev", systemImage: "chevron.left").labelStyle(.iconOnly)
                }
                Spacer()
                Text(navigationStore.logConfig.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .bold()
                Spacer()
                Button {
                    navigationStore.logConfig.next()
                } label: {
                    Label("Next", systemImage: "chevron.right").labelStyle(.iconOnly)
                }
            }.padding()
            Form {
                Section {
                    ForEach(items, id: \.hashValue, content: itemView)
                } header: {
                    Menu {
                        Button("All Entries") {
                            navigationStore.logConfig.selectedCategory = nil
                        }
                        ForEach(LogbookView.Categories, id: \.hashValue) { category in
                            Button(category) {
                                navigationStore.logConfig.selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(navigationStore.logConfig.selectedCategory ?? "All Entries")
                                .font(.title2)
                                .bold()
                            Spacer()
                        }.clipShape(Rectangle())
                    }.buttonStyle(.plain)
                }.headerProminence(.increased)
            }.scrollContentBackground(.hidden)
            Spacer()
        }.navigationTitle("Logbook")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.init(uiColor: UIColor.secondarySystemBackground))
            .toolbar(content: toolbarContent)
    }
    
    @ViewBuilder
    private func itemView(_ item: LogFoodItemEntry) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.item.name)
                    .font(.headline)
                if let brand = item.item.metaData.brand {
                    Text(brand)
                        .font(.subheadline)
                        .italic()
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(item.nutrients.calories.formatted()) Cal")
                    .font(.headline)
                if let price = item.price {
                    Text(price.toString())
                        .font(.subheadline)
                        .italic()
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("", selection: $navigationStore.logConfig.selectedType) {
                Text("Actual").tag(LogType.actual)
                Text("Plan").tag(LogType.plan)
            }.pickerStyle(.segmented)
                .frame(width: 150)
        }
        ToolbarItem(placement: .topBarTrailing) {
            if navigationStore.logConfig.selectedCategory != nil {
                Button {
                    navigationStore.push(LogViewType.addFoodItem())
                } label: {
                    Label("Add", systemImage: "plus")
                }
            } else {
                Menu {
                    ForEach(LogbookView.Categories, id: \.hashValue) { category in
                        Button(category) {
                            navigationStore.push(LogViewType.addFoodItem(category: category))
                        }
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    @Previewable @StateObject var navigationStore = NavigationStore()
    NavigationStack(path: $navigationStore.path) {
        LogCategoryView()
    }.environmentObject(navigationStore)
}
