//
//  MacroData.swift
//  Persephone
//
//  Created by Zach Wassynger on 5/8/26.
//

/// Container for nutrient amounts for Macronutrients
struct MacroData: Identifiable {
    /// The macro (can be null if this represents empty data)
    let macro: Macro?
    /// Amount in grams
    let grams: Double
    /// Identifiable name
    var id: String {
        if let macro {
            macro.rawValue
        } else {
            "None"
        }
    }
    /// Amount in calories
    var calories: Double {
        if let macro {
            grams * macro.modifier
        } else {
            1.0
        }
    }
    
    /// Used to represent empty data
    init() {
        self.macro = nil
        self.grams = 1.0
    }
    
    /// Builds data for the given macro with the given amounts
    init(macro: Macro, nutrients: Nutrients) {
        self.macro = macro
        self.grams = nutrients[macro.nutrient, default: 0.0]
    }
}

extension Nutrients {
    /// Builds a set of macro data for the given nutrients. If no applicable data exists,
    /// a single instance of the 'none' data is returned
    func toMacroData() -> [MacroData] {
        let data = Macro.allCases.map({ MacroData(macro: $0, nutrients: self) })
        if data.allSatisfy({ $0.grams <= 0.0 }) {
            // Return 'none' value
            return [.init()]
        }
        return data
    }
}

extension [MacroData] {
    /// Sums up all calories in the list
    var totalCalories: Double {
        return self.map({ $0.calories }).reduce(0, +)
    }
}
