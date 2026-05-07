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
        }.padding([.leading, .trailing], 4)
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
    
    var body: some View {
        let nutrients = entryMap.values.map({ $0.nutrients }).reduce([:], +)
        VStack {
            HStack {
                Text(date.formatted(date: .long, time: .omitted))
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    navigationStore.push(LogViewType.add())
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
                ForEach(entryMap.keys.sorted(), id: \.self) { meal in
                    mealView(meal)
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
                    .presentationDetents([.height(520)])
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
                        .foregroundStyle(Colors.carbs)
                    Text(nutrients.get(.TotalFat)?.formatted() ?? "0 g")
                        .foregroundStyle(Colors.fat)
                    Text(nutrients.get(.Protein)?.formatted() ?? "0 g")
                        .foregroundStyle(Colors.protein)
                    Text(nutrients.get(.Sodium)?.formatted() ?? "0 mg")
                }.fontWeight(.semibold)
            }
        }
    }
    
    private func mealView(_ name: String) -> some View {
        Section {
            ForEach(entryMap[name]!, id: \.hashValue) { entry in
                Button {
                    navigationStore.push(LogViewType.edit(entry))
                } label: {
                    LogEntryListView(entry: entry)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .swipeActions {
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
        } header: {
            HStack {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(entryMap[name]!.map({ $0.nutrients }).reduce([:], +).calories.formatted())
            }
        }
    }
}

enum LogViewType: Hashable {
    case add(meal: String? = nil)
    case edit(_ entry: LogEntry)
    case meals
    case meal(_ meal: Meal)
    case addMeal
    case editMeal(_ meal: Meal)
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    LogWeekView()
}
