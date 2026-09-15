//
//  PersephoneStore.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/15/26.
//

import Foundation
import SwiftData

/// Single source of truth for the SwiftData stack shared by the app and the
/// widget extension. Compiled into BOTH targets so the two processes can
/// never disagree about schema, store location, or CloudKit options.
enum PersephoneStore {
    /// Must match `com.apple.security.application-groups` in BOTH targets' entitlements.
    static let appGroupIdentifier = "group.com.wassynger.Persephone"

    /// `DaySummaryWidget`'s `kind`. Declared here (not in the widget target)
    /// because the app target can't import symbols from the widget extension
    /// module - this file is a member of both, so both sides stay in sync.
    static let daySummaryWidgetKind = "PersephoneDaySummary"

    /// The schema MUST be byte-identical in both processes, or SwiftData will
    /// believe the store needs a migration.
    static var schema: Schema { Schema(CurrentSchema.models) }

    /// The shared store, inside the App Group container. Used by the app,
    /// which keeps CloudKit sync (`.automatic`, matching the existing entitlements).
    static func appConfiguration() -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .automatic
        )
    }

    /// The same store, opened read-only by the widget. The widget never
    /// writes and must not spin up its own CloudKit stack inside an extension.
    static func widgetConfiguration() -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .none
        )
    }

    /// Where the store lived before the App Group migration: the app's own
    /// sandbox at ~/Library/Application Support/default.store.
    ///
    /// `groupContainer: .none` is load-bearing. With the default `.automatic`
    /// this would resolve to the App Group the instant the entitlement
    /// exists, and we'd "migrate" the new empty store onto itself.
    static var legacyConfiguration: ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .none,
            cloudKitDatabase: .automatic
        )
    }

    /// App only. Relocates the store if needed, then opens it.
    static func makeAppContainer() throws -> ModelContainer {
        let configuration = appConfiguration()
        StoreRelocator.migrateIfNeeded(
            from: legacyConfiguration.url,
            to: configuration.url
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
