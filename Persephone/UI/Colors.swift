//
//  Colors.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/13/25.
//

import SwiftUI

/// Defines colors that are set in the asset library
struct Colors {
    static let carbs = Color("CarbsColor")
    static let fat = Color("FatColor")
    static let protein = Color("ProteinColor")
}

// Maps colors to macros
extension Macro {
    var color: Color {
        switch self {
        case .carbs:
            return .carbs
        case .fat:
            return .fat
        case .protein:
            return .protein
        }
    }
}
