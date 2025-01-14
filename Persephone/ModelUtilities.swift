//
//  ModelUtilities.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

extension Quantity {
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

extension [LogFoodItemEntry] {
    var totalNutrients: NutritionDict {
        self.map({ $0.item.ingredients.nutrients * $0.amount.value }).reduce([:], +)
    }
    
    var totalPrice: Price {
        self.map{ $0.price ?? .Cents(0) }.reduce(.Cents(0), +)
    }
}
