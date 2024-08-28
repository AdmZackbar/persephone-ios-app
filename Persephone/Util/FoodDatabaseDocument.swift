//
//  FoodDatabaseDocument.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/26/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct FoodDatabaseDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json]
    }
    
    var entries: [Entry]
    
    init(entries: [Entry] = []) {
        self.entries = entries
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.entries = try JSONDecoder().decode([Entry].self, from: data)
        } else {
            entries = []
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(try JSONEncoder().encode(entries)))
    }
    
    struct Entry: Codable {
        var name: String
        var details: String
        var metaData: FoodItem.MetaData
        var ingredients: FoodIngredients
        var size: FoodItem.Size
        var storeEntries: [FoodItem.StoreEntry]
    }
}
