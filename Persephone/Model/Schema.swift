//
//  Schema.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/11/24.
//

import SwiftData

typealias CurrentSchema = SchemaV1

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [FoodItem.self, FoodInstance.self, LogEntry.self, Recipe.self, RecipeInstance.self]
    }
}
