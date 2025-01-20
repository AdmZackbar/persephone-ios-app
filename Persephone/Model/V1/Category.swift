//
//  Category.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import SwiftData

typealias Category = SchemaV1.Category

extension SchemaV1 {
    @Model
    final class Category {
        var name: String = ""
        var parent: Category? = nil
        @Relationship(deleteRule: .cascade, inverse: \Category.parent)
        var children: [Category]! = []
        
        init(name: String = "",
             parent: Category? = nil,
             children: [Category]! = []) {
            self.name = name
            self.parent = parent
            self.children = children
        }
    }
}
