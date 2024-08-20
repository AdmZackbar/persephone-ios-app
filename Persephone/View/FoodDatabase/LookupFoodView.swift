//
//  LookupFoodView.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/14/24.
//

import SwiftData
import SwiftUI

struct LookupFoodView: View {
    @Environment(\.modelContext) var modelContext
    @StateObject var sheetCoordinator = SheetCoordinator<FoodSheetEnum>()
    
    private enum ViewState {
        case GetQuery
        case Querying
        case NoResult
        case ResultList(items: [FoodItem])
    }
    
    @Binding private var path: [FoodDatabaseView.ViewType]
    @State private var viewState: ViewState = .GetQuery
    @State private var query: String = ""
    
    init(path: Binding<[FoodDatabaseView.ViewType]>) {
        self._path = path
    }
    
    var body: some View {
        VStack {
            switch viewState {
            case .GetQuery:
                Form {
                    TextField("Query...", text: $query)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit(onSearch)
                    Button("Search", action: onSearch)
                }.navigationTitle("Search Foods")
                    .navigationBarTitleDisplayMode(.inline)
            case .Querying:
                Text("Looking up \(query)...")
            case .NoResult:
                Text("No results found for \(query)")
                    .navigationTitle("Search Results")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") {
                                viewState = .GetQuery
                            }
                        }
                    }
            case .ResultList(let items):
                List(items, id: \.name) { item in
                    Button {
                        path.append(.ItemConfirm(item: item))
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                if item.metaData.brand != nil {
                                    Text(item.metaData.brand!).font(.subheadline).italic()
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .opacity(0.5)
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }.navigationTitle("Search Results")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .sheetCoordinating(coordinator: sheetCoordinator)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") {
                                viewState = .GetQuery
                            }
                        }
                    }
            }
        }
    }
    
    private func onSearch() {
        queryEndpoint(query: query) { results in
            if results.isEmpty {
                viewState = .NoResult
            } else {
                viewState = .ResultList(items: results)
            }
        }
    }
    
    private func queryEndpoint(query: String, completion: @escaping ([FoodItem]) -> Void) {
        viewState = .Querying
        Task {
            var results: [FoodItem] = []
            results.append(contentsOf: try await FoodDataCentralEndpoint.lookup(query: query, maxResults: 20))
            completion(results)
        }
    }
}

#Preview {
    let container = createTestModelContainer()
    return NavigationStack {
        LookupFoodView(path: .constant([]))
    }.modelContainer(container)
}
