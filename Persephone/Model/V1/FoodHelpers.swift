//
//  FoodHelpers.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/22/24.
//

import Foundation
import SwiftData

typealias Quantity = SchemaV1.Quantity
typealias Unit = SchemaV1.Unit
typealias RatingTier = SchemaV1.RatingTier
typealias NutritionDict = [Nutrient : Quantity]

extension SchemaV1 {
    struct Quantity: Codable, Equatable, Hashable {
        enum Magnitude: Codable, Equatable, Hashable {
            case Raw(_ value: Double)
            case Rational(num: Double, den: Double)
            
            var value: Double {
                get {
                    switch self {
                    case .Raw(let value):
                        return value
                    case .Rational(let num, let den):
                        return num / den
                    }
                }
            }
            
            func abs() -> Magnitude {
                switch self {
                case .Raw(let value):
                    return .Raw(value >= 0 ? value : -value)
                case .Rational(let num, let den):
                    return .Rational(num: num >= 0 ? num : -num, den: den >= 0 ? den : -den)
                }
            }
            
            static func parseString(_ str: String) -> Magnitude? {
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
            
            static func + (lhs: Magnitude, rhs: Magnitude) -> Magnitude {
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
            
            static func - (lhs: Magnitude, rhs: Magnitude) -> Magnitude {
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
            
            static func * (lhs: Magnitude, rhs: Double) -> Magnitude {
                switch lhs {
                case .Raw(let value):
                    return .Raw(value * rhs)
                case .Rational(let num, let den):
                    return rhs > 1 ? .Rational(num: num * rhs, den: den) : .Rational(num: num, den: den / rhs)
                }
            }
            
            static func / (lhs: Magnitude, rhs: Double) -> Magnitude {
                switch lhs {
                case .Raw(let value):
                    return .Raw(value / rhs)
                case .Rational(let num, let den):
                    return rhs > 1 ? .Rational(num: num, den: den * rhs) : .Rational(num: num / rhs, den: den)
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
                    return "\(formatter.string(for: num)!)/\(formatter.string(for: den)!)"
                }
            }
        }
        
        static func calories(_ value: Double) -> Quantity {
            Quantity(value: .Raw(value), unit: .Calorie)
        }
        
        static func grams(_ value: Double) -> Quantity {
            Quantity(value: .Raw(value), unit: .Gram)
        }
        
        static func milligrams(_ value: Double) -> Quantity {
            Quantity(value: .Raw(value), unit: .Milligram)
        }
        
        // The raw value of the amount
        var value: Magnitude
        // The unit of the amount
        var unit: Unit
        
        func toGrams() throws -> Quantity {
            var modifier: Double!
            switch unit {
            case .Microgram:
                modifier = 0.000001
            case .Milligram:
                modifier = 0.001
            case .Gram:
                modifier = 1
            case .Kilogram:
                modifier = 1000
            case .Ounce:
                modifier = 28.3495
            case .Pound:
                modifier = 453.592
            default:
                throw ParseError.invalidUnit(unit: unit)
            }
            return Quantity(value: value * modifier, unit: .Milligram)
        }
        
        func toMilligrams() throws -> Quantity {
            var modifier: Double!
            switch unit {
            case .Microgram:
                modifier = 0.001
            case .Milligram:
                modifier = 1
            case .Gram:
                modifier = 1000
            case .Kilogram:
                modifier = 1000000
            case .Ounce:
                modifier = 28349.5
            case .Pound:
                modifier = 453592
            default:
                throw ParseError.invalidUnit(unit: unit)
            }
            return Quantity(value: value * modifier, unit: .Milligram)
        }
        
        func toMilliliters() throws -> Quantity {
            var modifier: Double!
            switch unit {
            case .Milliliter:
                modifier = 1
            case .Liter:
                modifier = 1000
            case .Teaspoon:
                modifier = 4.92892
            case .Tablespoon:
                modifier = 14.7868
            case .FluidOunce:
                modifier = 29.5735
            case .Cup:
                modifier = 240
            case .Pint:
                modifier = 473.176
            case .Quart:
                modifier = 946.353
            case .Gallon:
                modifier = 3785.41
            default:
                throw ParseError.invalidUnit(unit: unit)
            }
            return Quantity(value: value * modifier, unit: .Milligram)
        }
    }
    
    enum Unit: Codable, Equatable, Hashable {
        // Energy
        case Calorie
        // Weight (US)
        case Ounce, Pound
        // Weight (SI)
        case Microgram, Milligram, Gram, Kilogram
        // Volume (US)
        case Teaspoon, Tablespoon, FluidOunce, Cup, Pint, Quart, Gallon
        // Volume (SI)
        case Milliliter, Liter
        // Other
        case Serving
        case Custom(name: String)
        
        var isSi: Bool {
            get {
                switch self {
                case .Microgram, .Milligram, .Gram, .Kilogram, .Milliliter, .Liter:
                    true
                default:
                    false
                }
            }
        }
        
        var isWeight: Bool {
            switch self {
            case .Ounce, .Pound, .Microgram, .Milligram, .Gram, .Kilogram:
                return true
            default:
                return false
            }
        }
        
        var isVolume: Bool {
            switch self {
            case .Milliliter, .Liter, .Teaspoon, .Tablespoon, .FluidOunce, .Cup, .Pint, .Quart, .Gallon:
                return true
            default:
                return false
            }
        }
        
        var abbreviation: String {
            switch self {
            case .Calorie:
                ""
            case .Ounce:
                "oz"
            case .Pound:
                "lb"
            case .Microgram:
                "mcg"
            case .Milligram:
                "mg"
            case .Gram:
                "g"
            case .Kilogram:
                "kg"
            case .Teaspoon:
                "tsp"
            case .Tablespoon:
                "tbsp"
            case .FluidOunce:
                "fl oz"
            case .Cup:
                "c"
            case .Pint:
                "pint"
            case .Quart:
                "qt"
            case .Gallon:
                "gal"
            case .Milliliter:
                "mL"
            case .Liter:
                "L"
            case .Serving:
                "serving"
            case .Custom(let name):
                name
            }
        }
    }
    
    enum ParseError: Error {
        case invalidUnit(unit: Unit)
    }
    
    enum RatingTier: String, CaseIterable, Codable, Identifiable {
        var id: String {
            get {
                rawValue
            }
        }
        
        case S, A, B, C, D, F
        
        var rating: Double {
            switch self {
            case .S:
                9.5
            case .A:
                8
            case .B:
                6.5
            case .C:
                5
            case .D:
                3.5
            case .F:
                1
            }
        }
        
        static func fromRating(rating: Double?) -> RatingTier? {
            if rating == nil {
                return nil
            }
            let rating = rating!
            if rating >= 9 {
                return .S
            }
            if rating >= 7.5 {
                return .A
            }
            if rating >= 6 {
                return .B
            }
            if rating >= 4.5 {
                return .C
            }
            if rating >= 3 {
                return .D
            }
            return .F
        }
    }
}
