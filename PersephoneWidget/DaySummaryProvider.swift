//
//  DaySummaryProvider.swift
//  PersephoneWidget
//
//  Created by Zach Wassynger on 9/15/26.
//

import WidgetKit

struct DaySummaryProvider: TimelineProvider {
    typealias Entry = DaySummaryEntry

    func placeholder(in context: Context) -> DaySummaryEntry { .sample() }

    func getSnapshot(in context: Context,
                      completion: @escaping @Sendable (DaySummaryEntry) -> Void) {
        // In the gallery, show sample data so the widget never looks broken.
        completion(context.isPreview ? .sample() : DaySummaryLoader.summary(for: .now))
    }

    func getTimeline(in context: Context,
                      completion: @escaping @Sendable (Timeline<DaySummaryEntry>) -> Void) {
        let now = Date.now
        let entry = DaySummaryLoader.summary(for: now)
        // One entry - today's totals don't change on their own - then reload
        // at local midnight so the day rolls over. Log changes are pushed by
        // the app via WidgetCenter.reloadTimelines(ofKind:).
        let timeline = Timeline(
            entries: [entry],
            policy: .after(DaySummaryLoader.nextDayBoundary(after: now))
        )
        completion(timeline)
    }
}
