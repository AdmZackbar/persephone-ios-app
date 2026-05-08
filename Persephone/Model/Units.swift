//
//  Units.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

extension Amount {
    init(value: Amount.Value, unit: Amount.Unit?) {
        self.value = value
        self.unitStr = unit?.abbreviation
    }
    
    /// Attempts to parse the unit into a known unit struct
    var unit: Unit? {
        if let str = self.unitStr {
            return Unit.abbreviationMap[str] ?? Unit.nameMap[str] ?? .init(name: str, abbreviation: str)
        }
        return nil
    }
    
    struct Unit: Codable, Equatable, Hashable {
        var name: String
        var abbreviation: String
        var modifier: Double?
        var type: UnitType?
        
        init(name: String,
             abbreviation: String,
             modifier: Double? = nil,
             type: UnitType? = nil) {
            self.name = name
            self.abbreviation = abbreviation
            self.modifier = modifier
            self.type = type
        }
    }

    /// Defines types of units: i.e. energy, mass, volume
    enum UnitType: Codable, Equatable, Hashable {
        case energy
        case mass
        case volume
    }
}

// Defines common units
extension Amount.Unit {
    // Energy
    /// Calorie (kcal): basic unit of energy - 4184 J
    static let calorie = Amount.Unit(name: "Calorie", abbreviation: "Cal", modifier: 4184, type: .energy)
    
    // Mass
    /// 1000 grams
    static let kilogram = Amount.Unit(name: "Kilogram", abbreviation: "kg", modifier: 0.001, type: .mass)
    /// Base metric unit of mass
    static let gram = Amount.Unit(name: "Gram", abbreviation: "g", modifier: 1, type: .mass)
    /// 1/1000 of a gram
    static let milligram = Amount.Unit(name: "Milligram", abbreviation: "mg", modifier: 1000, type: .mass)
    /// 1/1000000 of a gram
    static let microgram = Amount.Unit(name: "Microgram", abbreviation: "mcg", modifier: 1000000, type: .mass)
    /// Base imperial unit of mass (~453 g)
    static let pound = Amount.Unit(name: "Pound", abbreviation: "lb", modifier: 453.592, type: .mass)
    /// 1/16 of a pound
    static let ounce = Amount.Unit(name: "Ounce", abbreviation: "oz", modifier: 28.3495, type: .mass)
    
    // Volume
    /// Base metric unit of volume
    static let liter = Amount.Unit(name: "Liter", abbreviation: "L", modifier: 0.001, type: .volume)
    /// 1/1000 of a liter
    static let milliliter = Amount.Unit(name: "Milliliter", abbreviation: "mL", modifier: 1, type: .volume)
    /// Base imperial unit of volume
    static let fluidounce = Amount.Unit(name: "Fluid Ounce", abbreviation: "fl oz", modifier: 0.033814, type: .volume)
    
    /// Enumerates all common unit types
    static let all: [Amount.Unit] = [
        calorie,
        gram, milligram, microgram, pound, ounce,
        liter, milliliter
    ]
    /// Caches name -> unit
    static let nameMap: [String : Amount.Unit] = .init(uniqueKeysWithValues: all.map({ ($0.name, $0) }))
    /// Caches abbreviation -> unit
    static let abbreviationMap: [String : Amount.Unit] = .init(uniqueKeysWithValues: all.map({ ($0.abbreviation, $0) }))
}
