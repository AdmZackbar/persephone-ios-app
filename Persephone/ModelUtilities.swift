//
//  ModelUtilities.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Foundation

// Amount

extension Amount {
    func formatted(maxDigits: Int = 2, includeSpace: Bool = false) -> String {
        let valueStr = self.value.formatted(maxDigits: maxDigits)
        if let unitStr {
            return "\(valueStr)\(includeSpace ? " " : "")\(unitStr)"
        }
        return valueStr
    }
    
    static func * (lhs: Amount, rhs: Double) -> Amount {
        return .init(value: lhs.value * rhs, unitStr: lhs.unitStr)
    }
    
    static func / (lhs: Amount, rhs: Double) -> Amount {
        return .init(value: lhs.value / rhs, unitStr: lhs.unitStr)
    }
}

extension Amount.Value {
    // Instances
    
    static let zero = Amount.Value.raw(0)
    static let one = Amount.Value.raw(1)
    
    static func parse(_ str: String) -> Amount.Value? {
        if let match = try? /([\d.]+)\/([\d.]+)/.wholeMatch(in: str) {
            if let num = Double(match.1), let den = Double(match.2) {
                return .rational(num: num, den: den)
            }
        }
        if let value = Double(str) {
            return .raw(value)
        }
        return nil
    }
    
    // Computed value
    
    var raw: Double {
        switch self {
        case .raw(let value):
            return value
        case .rational(let num, let den):
            return num / den
        }
    }
    
    var isNegative: Bool {
        switch self {
        case .raw(let value):
            value < 0
        case .rational(let num, let den):
            (num < 0) ^ (den < 0)
        }
    }
    
    // Functions
    
    func abs() -> Amount.Value {
        return isNegative ? -self : self
    }
    
    func formatted(maxDigits: Int = 2) -> String {
        let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = maxDigits
            formatter.groupingSeparator = ""
            return formatter
        }()
        switch self {
        case .raw(let raw):
            return formatter.string(for: raw)!
        case .rational(let num, let den):
            if let num = tryGetWholeNumber(num), let den = tryGetWholeNumber(den) {
                let gcd = computeGcd(num, den)
                let num = num / gcd
                let den = den / gcd
                if den == 1 {
                    return formatter.string(for: num)!
                }
                return "\(formatter.string(for: num)!)/\(formatter.string(for: den)!)"
            }
            return "\(formatter.string(for: num)!)/\(formatter.string(for: den)!)"
        }
    }
    
    private func tryGetWholeNumber(_ x: Double) -> Int? {
        return x.truncatingRemainder(dividingBy: 1) == 0 ? Int(x) : nil
    }
    
    private func computeGcd(_ x: Int, _ y: Int) -> Int {
        let res = x % y
        if res != 0 {
            return computeGcd(y, res)
        } else {
            return y
        }
    }
    
    // Operations
    
    static prefix func - (x: Amount.Value) -> Amount.Value {
        switch x {
        case .raw(let value):
            return .raw(-value)
        case .rational(let num, let den):
            if x.isNegative {
                return .rational(num: num, den: den)
            }
            return .rational(num: -num, den: den)
        }
    }
    
    static func + (lhs: Amount.Value, rhs: Amount.Value) -> Amount.Value {
        switch lhs {
        case .raw(let l):
            return .raw(l + rhs.raw)
        case .rational(let lNum, let lDen):
            switch rhs {
            case .raw(let r):
                return .rational(num: r * lDen + lNum, den: lDen)
            case .rational(let rNum, let rDen):
                return .rational(num: rNum * lDen + lNum * rDen, den: lDen * rDen)
            }
        }
    }
    
    static func - (lhs: Amount.Value, rhs: Amount.Value) -> Amount.Value {
        return lhs + (-rhs)
    }
    
    static func * (lhs: Amount.Value, rhs: Amount.Value) -> Amount.Value {
        return lhs * rhs.raw
    }
    
    static func * (lhs: Amount.Value, rhs: Double) -> Amount.Value {
        switch lhs {
        case .raw(let value):
            return .raw(value * rhs)
        case .rational(let num, let den):
            if isWholeNumber(rhs) {
                return .rational(num: num * rhs, den: den)
            }
            return .raw(num * rhs / den)
        }
    }
    
    static func / (lhs: Amount.Value, rhs: Amount.Value) -> Amount.Value {
        return lhs / rhs.raw
    }
    
    static func / (lhs: Amount.Value, rhs: Double) -> Amount.Value {
        switch lhs {
        case .raw(let value):
            return .raw(value / rhs)
        case .rational(let num, let den):
            if isWholeNumber(rhs) {
                return .rational(num: num, den: den * rhs)
            }
            return .raw(num / rhs / den)
        }
    }
    
    private static func isWholeNumber(_ x: Double) -> Bool {
        x.truncatingRemainder(dividingBy: 1) == 0
    }
}

// FoodSize

extension FoodSize {
    func formatted(maxDigits: Int = 2) -> String {
        "\(str) (\(value.formatted(maxDigits: maxDigits)))"
    }
    
    static func * (lhs: FoodSize, rhs: Double) -> FoodSize {
        return .init(str: (lhs.amount * rhs).formatted(), val: lhs.val * rhs, isMass: lhs.isMass)
    }
}

// Food

extension Food {
    var brand: String? {
        if metaData.brand.isEmpty {
            nil
        } else {
            metaData.brand
        }
    }
    var category: String? {
        if metaData.category.isEmpty {
            nil
        } else {
            metaData.category
        }
    }
    var notes: String? {
        if metaData.notes.isEmpty {
            nil
        } else {
            metaData.notes
        }
    }
    var rating: RatingTier? {
        get {
            if let value = metaData.rating {
                RatingTier.fromRating(rating: value)
            } else {
                nil
            }
        } set(value) {
            metaData.rating = value?.rating
        }
    }
    var isRetired: Bool {
        metaData.retireDate != nil
    }
    
    var bestStoreEntry: StoreEntry? {
        get {
            storeEntries.filter({ $0.isAvailable })
                .min(by: { $0.costPerServing(servingSize) < $1.costPerServing(servingSize) })
        }
    }
    
    func contains(_ str: String) -> Bool {
        name.localizedCaseInsensitiveContains(str) ||
        metaData.brand.localizedCaseInsensitiveContains(str) ||
        metaData.category.localizedCaseInsensitiveContains(str)
    }
}

extension Food.StoreEntry {
    func numServings(_ servingSize: FoodSize) -> Double {
        self.amount.val / servingSize.val
    }
    
    func costPerServing(_ servingSize: FoodSize) -> Currency {
        cost / numServings(servingSize)
    }
}

// Log Entry

extension FoodLogEntry {
    var numServings: Double {
        if let modifier = amount.unit?.modifier {
            return (amount.value.raw * modifier) / food.servingSize.val
        }
        return amount.value.raw / food.servingSize.amount.value.raw
    }
    
    var nutrients: Nutrients {
        food.ingredients.nutrients * numServings
    }
    
    var cost: Currency? {
        if let servingCost {
            servingCost * numServings
        } else {
            nil
        }
    }
    
    var size: FoodSize {
        food.servingSize * numServings
    }
}

extension [FoodLogEntry] {
    var totalNutrients: Nutrients {
        self.map({ $0.nutrients }).reduce([:], +)
    }
    
    var totalCost: Currency? {
        let prices = self.filter({ $0.cost != nil })
        if !prices.isEmpty {
            return prices.map({ $0.cost! }).reduce(.zero, +)
        } else {
            return nil
        }
    }
}

// Recipes

extension RecipeEntry {
    var remainingScale: Double {
        max(0, min(1, 1 - logEntries.map({ $0.amountScale }).reduce(removedScale, +)))
    }
    
    var hasRemaining: Bool {
        remainingScale >= 0
    }
    
    var nutrients: Nutrients {
        self.ingredients.map({ $0.nutrients }).reduce([:], +)
    }
    
    var cost: Currency? {
        let total = self.ingredients.filter({ $0.cost != nil }).map({ $0.cost! })
        return total.isEmpty ? nil : total.reduce(.zero, +)
    }
    
    var remaining: FoodSize {
        total * remainingScale
    }
    
    var totalNumServings: Double {
        total.amount.value.raw
    }
    
    var servingSize: Amount {
        .init(value: .raw(1), unitStr: total.amount.unitStr)
    }
}

extension RecipeEntryIngredient {
    var numServings: Double {
        if let modifier = amount.unit?.modifier {
            return (amount.value.raw * modifier) / food.servingSize.val
        }
        return amount.value.raw / food.servingSize.amount.value.raw
    }
    
    var nutrients: Nutrients {
        food.ingredients.nutrients * numServings
    }
    
    var cost: Currency? {
        if let servingCost {
            return servingCost * numServings
        }
        return nil
    }
    
    var size: FoodSize {
        food.servingSize * numServings
    }
}

extension RecipeLogEntry {
    var size: FoodSize {
        recipe.total * amountScale
    }
    
    var nutrients: Nutrients {
        recipe.nutrients * amountScale
    }
    
    var cost: Currency? {
        if let totalCost = recipe.cost {
            totalCost * amountScale
        } else {
            nil
        }
    }
}
