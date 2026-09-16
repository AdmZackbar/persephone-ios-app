//
//  DaySummaryEntry.swift
//  PersephoneWidget
//
//  Created by Zach Wassynger on 9/15/26.
//

import Foundation
import WidgetKit

struct DaySummaryEntry: TimelineEntry, Sendable {
    /// When WidgetKit should display this entry.
    let date: Date
    /// Start of the logged day being summarized.
    let dayStart: Date
    let nutrients: Nutrients
    let entryCount: Int
    let totalCost: Currency
    /// false when the shared store can't be read (app has never migrated, or is missing).
    let isDataAvailable: Bool

    var calories: Double { nutrients[.Energy, default: 0] }

    static func unavailable(date: Date = .now, calendar: Calendar = .current) -> Self {
        .init(date: date, dayStart: calendar.startOfDay(for: date),
              nutrients: [:], entryCount: 0, totalCost: .zero, isDataAvailable: false)
    }

    /// Gallery / preview content.
    static func sample(date: Date = .now, calendar: Calendar = .current) -> Self {
        .init(date: date, dayStart: calendar.startOfDay(for: date),
              nutrients: [.Energy: 1840, .TotalCarbs: 186, .TotalFat: 62,
                          .Protein: 132, .Sodium: 2310, .DietaryFiber: 24],
              entryCount: 7, totalCost: .usd(1451), isDataAvailable: true)
    }

    static func empty(date: Date = .now, calendar: Calendar = .current) -> Self {
        .init(date: date, dayStart: calendar.startOfDay(for: date),
              nutrients: [:], entryCount: 0, totalCost: .zero, isDataAvailable: true)
    }
}
