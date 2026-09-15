//
//  StoreRelocator.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/15/26.
//

import CoreData
import Foundation
import OSLog
import SwiftData

/// One-time, non-destructive relocation of the SwiftData store from the app
/// sandbox into the shared App Group container.
enum StoreRelocator {
    private static let logger = Logger(
        subsystem: "com.wassynger.Persephone", category: "StoreRelocator")

    private static let didMigrateKey = "storeRelocatedToAppGroup.v1"

    static func migrateIfNeeded(from source: URL, to destination: URL) {
        let defaults = UserDefaults(suiteName: PersephoneStore.appGroupIdentifier)
            ?? .standard
        guard !defaults.bool(forKey: didMigrateKey) else { return }

        let fm = FileManager.default
        let sourcePath = source.path(percentEncoded: false)

        // Fresh install: nothing to move. Mark done so we never look again.
        guard fm.fileExists(atPath: sourcePath) else {
            logger.info("No legacy store found; nothing to relocate.")
            defaults.set(true, forKey: didMigrateKey)
            return
        }

        guard source.standardizedFileURL != destination.standardizedFileURL else {
            logger.error("Source and destination are the same URL; refusing to migrate.")
            return
        }

        do {
            try fm.createDirectory(at: destination.deletingLastPathComponent(),
                                    withIntermediateDirectories: true)

            // The Apple-sanctioned way to relocate a Core Data / SwiftData
            // SQLite store: checkpoints the -wal, writes a clean copy of the
            // store plus its sidecars, and leaves the SOURCE UNTOUCHED. This
            // avoids ever publishing a store whose WAL is inconsistent with
            // its main file, which hand-copying store/-wal/-shm would risk.
            // The model only needs to describe the store's entities well
            // enough for Core Data to open it; it doesn't need SwiftData's
            // own schema instance.
            guard let model = NSManagedObjectModel.makeManagedObjectModel(for: CurrentSchema.models) else {
                logger.error("Could not build a managed object model for relocation.")
                return
            }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            try coordinator.replacePersistentStore(
                at: destination,
                destinationOptions: nil,
                withPersistentStoreFrom: source,
                sourceOptions: nil,
                type: .sqlite
            )

            // Only now is the migration considered complete.
            defaults.set(true, forKey: didMigrateKey)
            logger.notice("Relocated store into App Group container.")
            // The original is deliberately LEFT IN PLACE as a backup.
        } catch {
            logger.error("Store relocation failed: \(error.localizedDescription, privacy: .public)")
            // Flag stays false, so we retry next launch from the intact original.
        }
    }
}
