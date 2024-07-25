//
//  FoodDatabaseEndpoint.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/24/24.
//

import Foundation

protocol FoodDatabaseEndpoint {
    static func lookupBarcode(_ barcode: String) async throws -> [FoodItem]
    
    static func lookup(query: String, maxResults: Int) async throws -> [FoodItem]
}
