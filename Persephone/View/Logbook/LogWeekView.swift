//
//  LogWeekView.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/6/26.
//

import SwiftData
import SwiftUI

struct LogWeekView: View {
    @StateObject private var navigationStore = NavigationStore()
    
    @Query(sort: \FoodLogEntry.date) private var foodEntries: [FoodLogEntry]
    @Query(sort: \RecipeLogEntry.date) private var recipeEntries: [RecipeLogEntry]
    
    @State var date: Date = .now
    @State private var weekOffset: CGSize = .zero
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            VStack(spacing: 24) {
                // Top view with all the days in the week
                weekView()
                // Filter entries for just the selected day
                let entries: [LogEntry] = foodEntries.filter({ filter($0.date) }).map(LogEntry.food) + recipeEntries.filter({ filter($0.date) }).map(LogEntry.recipe)
                LogDayView(entryMap: .init(grouping: entries) { $0.meal }, date: $date)
            }.background(Color(uiColor: UIColor.systemGroupedBackground))
                .navigationTitle("Log: \(date.formatted(date: .abbreviated, time: .omitted))")
                .toolbar(.hidden)
                .handleDestinations(navigationStore)
        }.environmentObject(navigationStore)
    }
    
    private func filter(_ date: Date) -> Bool {
        self.date.day == date.day && self.date.month == date.month && self.date.year == date.year
    }
    
    private func filter(baseDate: Date, date: Date) -> Bool {
        baseDate.day == date.day && baseDate.month == date.month && baseDate.year == date.year
    }
    
    private func weekView() -> some View {
        Grid {
            let startDate = date.lastSaturday()
            GridRow {
                ForEach(1..<8) { dayIndex in
                    dayView(startDate.addDays(dayIndex))
                }
            }.frame(maxWidth: .infinity)
        }.padding([.leading, .trailing], 12)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        weekOffset = gesture.translation
                    }
                    .onEnded { _ in
                        if weekOffset.width > 100 {
                            date = date.addDays(-7)
                        } else if weekOffset.width < -100 {
                            date = date.addDays(7)
                        }
                        weekOffset = .zero // Reset position
                    }
            )
    }
    
    private func dayView(_ d: Date) -> some View {
        Button {
            self.date = d
        } label: {
            VStack(spacing: 0) {
                Text(d.formatted(.dateTime.weekday()))
                    .font(.subheadline)
                    .fontWeight(d.day == date.day ? .bold : .regular)
                let nutrients = computeDayNutrients(d)
                MiniNutrientPieChart(text: d.day.formatted(), nutrients: nutrients)
                    .frame(width: 40, height: 40)
                    .font(.subheadline)
                    .fontWeight(d.day == date.day ? .bold : .regular)
                Text(nutrients.calories.value.formatted())
                    .font(.footnote)
                    .fontWeight(.bold)
            }.contentShape(Rectangle())
                .scaleEffect(d.day == date.day ? 1.1 : 1.0)
        }.buttonStyle(.plain)
    }
    
    private func computeDayNutrients(_ d: Date) -> Nutrients {
        (foodEntries.filter({ filter(baseDate: d, date: $0.date) }).map({ $0.nutrients })
         + recipeEntries.filter({ filter(baseDate: d, date: $0.date) }).map({ $0.nutrients }))
        .reduce([:], +)
    }
}

private struct LogDayView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @Environment(\.modelContext) private var modelContext
    
    let entryMap: [String : [LogEntry]]
    
    @Binding var date: Date
    @State private var showNutrientSheet = false
    @State private var editItem: PersistentIdentifier? = nil
    
    var body: some View {
        let nutrients = entryMap.values.map({ $0.nutrients }).reduce([:], +)
        VStack {
            HStack {
                Text(date.formatted(date: .long, time: .omitted))
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    navigationStore.push(LogViewType.add(date.atCurrentTime()))
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 30, height: 30)
                }.buttonStyle(.glass)
                    .clipShape(Circle())
                    .glassEffect(in: Circle())
            }.padding(.leading, 24)
                .padding(.trailing, 12)
            Form {
                summaryView(nutrients: nutrients)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showNutrientSheet.toggle()
                    }
                ForEach(MealType.allCases.filter({ entryMap[$0.rawValue] != nil }), id: \.rawValue) { mealType in
                    mealView(mealType.rawValue)
                }
            }.scrollContentBackground(.hidden)
                // Remove hidden margin above form
                .contentMargins(.top, 0, for: .scrollContent)
        }.background(Color(uiColor: UIColor.systemGroupedBackground))
            .sheet(isPresented: $showNutrientSheet) {
                NutrientsView(nutrients: nutrients)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showNutrientSheet.toggle()
                    }
                    .padding()
                    .presentationDetents([.height(500)])
                    // Don't use liquid glass as main background
                    .presentationBackground(.regularMaterial)
            }
            .sheet(isPresented: .isPresent($editItem)) {
                if let entry = entryMap.values.flatMap({ $0 }).first(where: { e in
                    switch e {
                    case .food(let f):
                        return f.id == editItem
                    case .recipe(let r):
                        return r.id == editItem
                    }
                }) {
                    SetAmountSheet(item: .init(entry: entry))
                }
                else {
                    Text("Error getting item")
                }
            }
    }
    
    private func summaryView(nutrients: Nutrients) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(nutrients.calories.value.formatted()) Calories")
                .font(.title2)
                .fontWeight(.bold)
            Text(entryMap.values.map({ $0.cost ?? .zero }).reduce(.zero, +).formatted())
                .fontWeight(.bold)
            Spacer()
            // TODO improve this layout and styling
            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 2) {
                GridRow {
                    Text("Carbs")
                    Text("Fat")
                    Text("Protein")
                    Text("Sodium")
                }.fontWeight(.light)
                // Used to expand grid to full width - don't show
                Divider().hidden()
                GridRow {
                    Text(nutrients.get(.TotalCarbs)?.formatted() ?? "0 g")
                        .foregroundStyle(.carbs)
                    Text(nutrients.get(.TotalFat)?.formatted() ?? "0 g")
                        .foregroundStyle(.fat)
                    Text(nutrients.get(.Protein)?.formatted() ?? "0 g")
                        .foregroundStyle(.protein)
                    Text(nutrients.get(.Sodium)?.formatted() ?? "0 mg")
                }.fontWeight(.semibold)
            }
        }
    }
    
    private func mealView(_ name: String) -> some View {
        Section {
            ForEach(entryMap[name]!, id: \.hashValue) { entry in
                Button {
                    switch entry {
                    case .food(let food):
                        editItem = food.id
                    case .recipe(let recipe):
                        editItem = recipe.id
                    }
                } label: {
                    LogEntryListView(entry: entry)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .contextMenu {
                        deleteButton(entry)
                    }
                    .swipeActions {
                        deleteButton(entry)
                    }
            }
        } header: {
            HStack {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(entryMap[name]!.map({ $0.nutrients }).reduce([:], +).calories.formatted())
            }.foregroundStyle(.primary)
        }
    }
    
    private func deleteButton(_ entry: LogEntry) -> some View {
        Button(role: .destructive) {
            withAnimation {
                switch entry {
                case .food(let food):
                    modelContext.delete(food)
                case .recipe(let recipe):
                    modelContext.delete(recipe)
                }
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

enum LogViewType: Hashable {
    case add(_ date: Date)
    case edit(_ entry: LogEntry)
    case meals
    case meal(_ meal: Meal)
    case addMeal
    case editMeal(_ meal: Meal)
}

enum MealType: String, Hashable, CaseIterable {
    case Breakfast, Brunch, Lunch, Dinner, Snacks
}

extension Binding {
    /// Creates a Bool Binding representing “non-nil” from an Optional Binding.
    static func isPresent<T: Sendable>(_ binding: Binding<T?>) -> Binding<Bool> {
        Binding<Bool>(
            get: { binding.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    binding.wrappedValue = nil
                }
            }
        )
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogWeekView()
}
