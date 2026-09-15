//
//  DaySummaryLoader.swift
//  PersephoneWidget
//
//  Created by Zach Wassynger on 9/15/26.
//

import Foundation
import OSLog
import SwiftData

/// Reads a single day's log entries out of the shared store.
///
/// Everything here is synchronous and `nonisolated`. A `ModelContext` is
/// created, used, and dropped inside one function body, so it never crosses
/// an isolation boundary.
struct DaySummaryLoader {
    private static let logger = Logger(
        subsystem: "com.wassynger.Persephone", category: "Widget")

    /// `ModelContainer` is `Sendable`, so a plain `static let` satisfies
    /// strict concurrency with no extra annotation.
    private static let container: ModelContainer? = {
        let configuration = PersephoneStore.widgetConfiguration()

        // The widget must never CREATE the store. If the app hasn't relocated
        // it into the App Group yet, constructing a ModelContainer here would
        // leave an empty store behind. StoreRelocator's migration flag also
        // defends against that, but two guards are cheaper than a lost food log.
        guard FileManager.default.fileExists(
            atPath: configuration.url.path(percentEncoded: false)) else {
            logger.notice("Shared store not present yet; widget has no data.")
            return nil
        }

        do {
            return try ModelContainer(for: PersephoneStore.schema,
                                       configurations: [configuration])
        } catch {
            logger.error("Widget could not open shared store: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }()

    static func summary(for referenceDate: Date,
                         calendar: Calendar = .current) -> DaySummaryEntry {
        guard let container else { return .unavailable(date: referenceDate, calendar: calendar) }

        // [dayStart, dayEnd) - half-open so midnight belongs to exactly one
        // day. Going through Calendar handles 23/25-hour DST days correctly.
        let dayStart = calendar.startOfDay(for: referenceDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)
            ?? dayStart.addingTimeInterval(86_400)

        let context = ModelContext(container)
        context.autosaveEnabled = false // read-only; never mutate from the widget

        var total: Nutrients = [:]
        var count = 0

        do {
            let foodEntries = try context.fetch(
                FetchDescriptor<FoodLogEntry>(
                    predicate: #Predicate { $0.date >= dayStart && $0.date < dayEnd }
                )
            )
            for entry in foodEntries {
                // `food` is declared `Food! = nil`. A dangling relationship
                // would trap on the implicit unwrap inside `numServings`, so
                // guard explicitly rather than crash-looping the widget.
                guard entry.food != nil else { continue }
                total = total + entry.nutrients
                count += 1
            }

            let recipeEntries = try context.fetch(
                FetchDescriptor<RecipeLogEntry>(
                    predicate: #Predicate { $0.date >= dayStart && $0.date < dayEnd }
                )
            )
            for entry in recipeEntries {
                guard entry.recipe != nil else { continue }
                total = total + entry.nutrients
                count += 1
            }
        } catch {
            logger.error("Widget fetch failed: \(error.localizedDescription, privacy: .public)")
            return .unavailable(date: referenceDate, calendar: calendar)
        }

        return DaySummaryEntry(date: referenceDate, dayStart: dayStart,
                                nutrients: total, entryCount: count,
                                isDataAvailable: true)
    }

    /// Next local midnight after `date` - the day-rollover point.
    static func nextDayBoundary(after date: Date,
                                 calendar: Calendar = .current) -> Date {
        calendar.nextDate(after: date,
                           matching: DateComponents(hour: 0, minute: 0, second: 0),
                           matchingPolicy: .nextTime)
            ?? calendar.startOfDay(for: date).addingTimeInterval(86_400)
    }
}
