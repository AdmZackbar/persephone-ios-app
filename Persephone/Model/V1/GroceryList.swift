//
//  GroceryList.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/13/26.
//

import Foundation
import SwiftData

typealias GroceryList = SchemaV1.GroceryList
typealias GroceryListItem = SchemaV1.GroceryListItem

extension SchemaV1 {
    @Model
    final class GroceryList {
        var store: String = ""
        var items: [GroceryListItem] = []
        
        init(store: String = "", items: [GroceryListItem] = []) {
            self.store = store
            self.items = items
        }
    }
    
    struct GroceryListItem: Codable {
        var name: String
        var checked: Bool
        
        init(name: String = "", checked: Bool = false) {
            self.name = name
            self.checked = checked
        }
    }
}
