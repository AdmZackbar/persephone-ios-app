//
//  PersephoneWidget.swift
//  PersephoneWidget
//
//  Created by Zach Wassynger on 9/15/26.
//

import SwiftUI
import WidgetKit

struct DaySummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: PersephoneStore.daySummaryWidgetKind, provider: DaySummaryProvider()) { entry in
            DaySummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Nutrition")
        .description("Calories and macros you've logged today.")
        .supportedFamilies([.systemSmall, .systemMedium,
                             .accessoryCircular, .accessoryRectangular])
    }
}

struct DaySummaryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DaySummaryEntry

    var body: some View {
        content
            // Required on iOS 17+; covers all four families in one place.
            .containerBackground(for: .widget) { Color.background }
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .systemSmall:
            SmallDaySummaryView(entry: entry)
        case .systemMedium:
            MediumDaySummaryView(entry: entry)
        case .accessoryCircular:
            CircularDaySummaryView(entry: entry)
        case .accessoryRectangular:
            RectangularDaySummaryView(entry: entry)
        default:
            SmallDaySummaryView(entry: entry)
        }
    }
}

#Preview("Small", as: .systemSmall) {
    DaySummaryWidget()
} timeline: {
    DaySummaryEntry.sample()
    DaySummaryEntry.empty()
}

#Preview("Medium", as: .systemMedium) {
    DaySummaryWidget()
} timeline: {
    DaySummaryEntry.sample()
}

#Preview("Circular", as: .accessoryCircular) {
    DaySummaryWidget()
} timeline: {
    DaySummaryEntry.sample()
}

#Preview("Rectangular", as: .accessoryRectangular) {
    DaySummaryWidget()
} timeline: {
    DaySummaryEntry.sample()
}
