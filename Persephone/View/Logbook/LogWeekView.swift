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
    
    @State var date: Date
    @State private var weekOffset: CGSize
    
    init(date: Date = .now) {
        self.date = date
        self.weekOffset = .zero
    }
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            VStack(spacing: 12) {
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
                    .frame(width: 32, height: 32)
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
    @State private var editDate = false
    @State private var showNutrients: Nutrients? = nil
    @State private var editItem: PersistentIdentifier? = nil
    @State private var healthKitErrorMessage: String? = nil
    @State private var showHealthKitSuccess = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                headerView()
                entriesView()
            }
            Menu {
                ForEach(MealType.allCases) { mealType in
                    Button {
                        navigationStore.push(LogViewType.add(date: date.atCurrentTime(), mealType: mealType.rawValue))
                    } label: {
                        Label(mealType.rawValue, systemImage: mealType.getIconName())
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 42, height: 42)
                    .font(.title2)
                    .bold()
            }.buttonStyle(.glass)
                .clipShape(Circle())
                .glassEffect(in: Circle())
                .padding(16)
        }.background(Color(uiColor: UIColor.systemGroupedBackground))
            .sheet(isPresented: $editDate) {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .presentationDetents([.height(380)])
                    .padding([.leading, .trailing], 16)
            }
            .sheet(isPresented: .isPresent($showNutrients)) {
                NutrientsView(nutrients: showNutrients ?? [:])
                    .padding(.top, 16)
                    .padding([.leading, .trailing], 32)
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
                    SaveLogEntryAmountSheet(item: .init(entry: entry))
                }
                else {
                    Text("Error getting item")
                }
            }
            .alert("Couldn't Sync to Health", isPresented: .isPresent($healthKitErrorMessage)) {
                Button("OK") { }
            } message: {
                Text(healthKitErrorMessage ?? "")
            }
            .overlay(alignment: .top) {
                if showHealthKitSuccess {
                    Label("Health Synced", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.green, in: Capsule())
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
    }
    
    @ViewBuilder
    func headerView() -> some View {
        HStack {
            Button {
                editDate.toggle()
            } label: {
                Text(date.formatted(date: .long, time: .omitted))
                    .font(.title)
                    .fontWeight(.bold)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
            Spacer()
            Menu {
                Button {
                    syncToHealthKit(entryMap.values.map { $0.nutrients }.reduce([:], +))
                } label: {
                    Label("Save Log", systemImage: "square.and.arrow.down")
                }
                Button(role: .destructive) {
                    // Override with empty data, effectively clearing existing data
                    syncToHealthKit([:])
                } label: {
                    Label("Delete Log", systemImage: "trash")
                }
            } label: {
                Image(systemName: "heart.text.square")
                    .frame(width: 30, height: 30)
                    .bold()
            }.buttonStyle(.glass)
                .clipShape(Circle())
                .glassEffect(in: Circle())
        }.padding(.leading, 24)
            .padding(.trailing, 12)
    }
    
    @ViewBuilder
    func entriesView() -> some View {
        Form {
            LogEntriesSummaryView(entries: entryMap.values.flatMap { $0 })
                .contentShape(Rectangle())
                .onTapGesture {
                    showNutrients = entryMap.values.map { $0.nutrients }.reduce([:], +)
                }
            ForEach(MealType.allCases.filter({ entryMap[$0.rawValue] != nil })) { mealType in
                mealView(mealType, entryMap[mealType.rawValue]!)
            }
        }.scrollContentBackground(.hidden)
            // Remove hidden margin above form
            .contentMargins(.top, 0, for: .scrollContent)
    }

    private func syncToHealthKit(_ nutrients: Nutrients) {
        guard HealthKitManager.isAvailable else {
            healthKitErrorMessage = "Health data isn't available on this device."
            return
        }
        Task {
            do {
                try await HealthKitManager.shared.requestAuthorization()
                try await HealthKitManager.shared.save(nutrients: nutrients, for: date)
                withAnimation {
                    showHealthKitSuccess = true
                }
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    showHealthKitSuccess = false
                }
            } catch {
                healthKitErrorMessage = error.localizedDescription
            }
        }
    }

    private func mealView(_ mealType: MealType, _ entries: [LogEntry]) -> some View {
        Section {
            ForEach(entries, id: \.hashValue) { entry in
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
            let cost = entries.map({ $0.cost ?? .zero }).reduce(.zero, +)
            let nutrients = entries.map({ $0.nutrients }).reduce([:], +)
            VStack(spacing: 8) {
                HStack(alignment: .bottom) {
                    Button {
                        showNutrients = nutrients
                    } label: {
                        Label(mealType.rawValue, systemImage: mealType.getIconName())
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Button {
                        showNutrients = nutrients
                    } label: {
                        Text(nutrients.calories.formatted())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }.buttonStyle(.glass)
                    Button {
                        // TODO
                    } label: {
                        Text(cost.formatted())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }.buttonStyle(.glass)
                }
                MacroBarChart(nutrients: nutrients, textFormat: .gram)
                    .font(.caption2)
                    .frame(height: 8)
                    .padding(.bottom, 10)
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
    case add(date: Date, mealType: String)
}

enum MealType: String, Identifiable, Hashable, CaseIterable {
    var id: String {
        rawValue
    }
    
    case Breakfast, Brunch, Lunch, Dinner, Snacks, Workout
    
    func getIconName() -> String {
        switch self {
        case .Breakfast:
            return "sunrise"
        case .Brunch:
            return "sun.min"
        case .Lunch:
            return "sun.max"
        case .Dinner:
            return "sunset"
        case .Snacks:
            return "carrot"
        case .Workout:
            return "scalemass"
        }
    }
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

#Preview(traits: .sampleData) {
    LogWeekView()
}
