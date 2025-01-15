//
//  ModelUtilities.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Foundation

extension Quantity {
    static func calories(_ value: Double) -> Quantity {
        Quantity(value: .Raw(value), unit: .Calorie)
    }
    
    static func grams(_ value: Double) -> Quantity {
        Quantity(value: .Raw(value), unit: .Gram)
    }
    
    static func milligrams(_ value: Double) -> Quantity {
        Quantity(value: .Raw(value), unit: .Milligram)
    }
    
    func formatted(maxDigits: Int = 0, includeSpace: Bool = false) -> String {
        "\(self.value.toString(maxDigits: maxDigits))\(includeSpace ? " " : "")\(self.unit.abbreviation)"
    }
    
    static func * (lhs: Quantity, rhs: Double) -> Quantity {
        switch lhs.value {
        case .Raw(let value):
            return .init(value: .Raw(value * rhs), unit: lhs.unit)
        case .Rational(let num, let den):
            return .init(value: .Rational(num: num * rhs, den: den), unit: lhs.unit)
        }
    }
}

extension Quantity.Magnitude {
    func abs() -> Quantity.Magnitude {
        switch self {
        case .Raw(let value):
            return .Raw(value >= 0 ? value : -value)
        case .Rational(let num, let den):
            return .Rational(num: num >= 0 ? num : -num, den: den >= 0 ? den : -den)
        }
    }
    
    static func parseString(_ str: String) -> Quantity.Magnitude? {
        if let match = try? /([\d.]+)\/([\d.]+)/.wholeMatch(in: str) {
            if let num = Double(match.1), let den = Double(match.2) {
                return .Rational(num: num, den: den)
            }
        }
        if let value = Double(str) {
            return .Raw(value)
        }
        return nil
    }
    
    static func + (lhs: Quantity.Magnitude, rhs: Quantity.Magnitude) -> Quantity.Magnitude {
        switch lhs {
        case .Raw(let l):
            switch rhs {
            case .Raw(let r):
                return .Raw(l + r)
            case .Rational(let rNum, let rDen):
                return .Rational(num: l * rDen + rNum, den: rDen)
            }
        case .Rational(let lNum, let lDen):
            switch rhs {
            case .Raw(let r):
                return .Rational(num: r * lDen + lNum, den: lDen)
            case .Rational(let rNum, let rDen):
                return .Rational(num: rNum * lDen + lNum * rDen, den: lDen * rDen)
            }
        }
    }
    
    static func - (lhs: Quantity.Magnitude, rhs: Quantity.Magnitude) -> Quantity.Magnitude {
        switch lhs {
        case .Raw(let l):
            switch rhs {
            case .Raw(let r):
                return .Raw(l - r)
            case .Rational(let rNum, let rDen):
                return .Rational(num: l * rDen - rNum, den: rDen)
            }
        case .Rational(let lNum, let lDen):
            switch rhs {
            case .Raw(let r):
                return .Rational(num: r * lDen - lNum, den: lDen)
            case .Rational(let rNum, let rDen):
                return .Rational(num: rNum * lDen - lNum * rDen, den: lDen * rDen)
            }
        }
    }
    
    static func * (lhs: Quantity.Magnitude, rhs: Double) -> Quantity.Magnitude {
        switch lhs {
        case .Raw(let value):
            return .Raw(value * rhs)
        case .Rational(let num, let den):
            if tryGetWholeNumber(rhs) != nil {
                return .Rational(num: num * rhs, den: den)
            }
            return .Raw(num * rhs / den)
        }
    }
    
    static func / (lhs: Quantity.Magnitude, rhs: Double) -> Quantity.Magnitude {
        switch lhs {
        case .Raw(let value):
            return .Raw(value / rhs)
        case .Rational(let num, let den):
            if tryGetWholeNumber(rhs) != nil {
                return .Rational(num: num, den: den * rhs)
            }
            return .Raw(num / rhs / den)
        }
    }
    
    func toString(maxDigits: Int = 2) -> String {
        let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = maxDigits
            formatter.groupingSeparator = ""
            return formatter
        }()
        switch self {
        case .Raw(let raw):
            return formatter.string(for: raw)!
        case .Rational(let num, let den):
            if let num = Self.tryGetWholeNumber(num), let den = Self.tryGetWholeNumber(den) {
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
    
    private static func tryGetWholeNumber(_ x: Double) -> Int? {
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
}

extension FoodItem {
    func contains(_ str: String) -> Bool {
        name.localizedCaseInsensitiveContains(str) ||
        (metaData.brand?.localizedCaseInsensitiveContains(str) ?? false)
    }
}

extension FoodItem.CostType {
    func toString() -> String {
        switch self {
        case .Collection(let cost, let quantity):
            if quantity > 1 {
                return "\(cost.toString()) for \(quantity)"
            }
            return cost.toString()
        case .PerAmount(let cost, let amount):
            if amount.value.value == 1 {
                return "\(cost.toString()) / \(amount.unit.abbreviation)"
            }
            return "\(cost.toString()) / \(amount.value.toString())\(amount.unit.abbreviation)"
        }
    }
}

extension NutritionDict {
    var calories: Double {
        return self[.Energy]?.value.value ?? 0
    }
    
    static func + (lhs: NutritionDict, rhs: NutritionDict) -> NutritionDict {
        lhs.merging(rhs) { x, y in
            if x.unit == y.unit {
                return .init(value: x.value + y.value, unit: x.unit)
            } else if x.unit.isWeight {
                return try! .init(value: x.convert(unit: .Gram).value + y.convert(unit: .Gram).value, unit: .Gram)
            }
            return try! .init(value: x.convert(unit: .Milliliter).value + y.convert(unit: .Milliliter).value, unit: .Milliliter)
        }
    }
    
    static func * (lhs: NutritionDict, rhs: Double) -> NutritionDict {
        lhs.mapValues { x in
            return .init(value: x.value * rhs, unit: x.unit)
        }
    }
    
    static func / (lhs: NutritionDict, rhs: Double) -> NutritionDict {
        lhs.mapValues { x in
            return .init(value: x.value / rhs, unit: x.unit)
        }
    }
}

extension [LogFoodItemEntry] {
    var totalNutrients: NutritionDict {
        self.map({ $0.nutrients }).reduce([:], +)
    }
    
    var totalPrice: Price {
        self.map{ $0.price ?? .Cents(0) }.reduce(.Cents(0), +)
    }
}

extension CookedFood {
    var isAvailable: Bool {
        remaining > 0
    }
    
    var totalNutrition: NutritionDict {
        self.ingredients!.map({ $0.foodItem.ingredients.nutrients }).reduce(adjustNutrition, +)
    }
    
    var totalCost: Price? {
        let prices = self.ingredients!.filter({ $0.price != nil }).map({ $0.price! })
        if prices.isEmpty {
            return nil
        }
        return prices.reduce(.Cents(0), +)
    }
}
