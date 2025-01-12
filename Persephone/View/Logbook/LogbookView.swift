//
//  LogbookView.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/15/24.
//

import SwiftData
import SwiftUI

struct LogbookView: View {
    @Query(sort: \LogFoodItemEntry.date) var foodItems: [LogFoodItemEntry]
    
    @StateObject private var navigationStore = NavigationStore()
    
    var body: some View {
        let items = foodItems.filter({ navigationStore.logConfig.contains($0.date) && $0.type == navigationStore.logConfig.selectedType })
        NavigationStack(path: $navigationStore.path) {
            VStack(spacing: 24) {
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
                }
                if !items.isEmpty {
                    
                } else {
                    Text("No Entries")
                }
                Spacer()
            }.navigationTitle("Logbook")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("", selection: $navigationStore.logConfig.selectedType) {
                            Text("Actual").tag(LogType.actual)
                            Text("Plan").tag(LogType.plan)
                        }.pickerStyle(.segmented)
                            .frame(width: 150)
                    }
                }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogbookView()
}
