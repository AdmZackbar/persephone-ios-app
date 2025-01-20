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
    
    var unit: Unit? {
        if let str = self.unitStr {
            if let unit = Units.all.first(where: { $0.abbreviation == str || $0.name == str }) {
                return unit
            }
            return .init(name: str, abbreviation: str)
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

    enum UnitType: Codable, Equatable, Hashable {
        case energy
        case mass
        case volume
    }
}

struct Units {
    // Energy
    
    static let calorie = Amount.Unit(name: "Calorie", abbreviation: "Cal", modifier: 4184, type: .energy)
    
    // Mass
    
    static let kilogram = Amount.Unit(name: "Kilogram", abbreviation: "kg", modifier: 0.001, type: .mass)
    static let gram = Amount.Unit(name: "Gram", abbreviation: "g", modifier: 1, type: .mass)
    static let milligram = Amount.Unit(name: "Milligram", abbreviation: "mg", modifier: 1000, type: .mass)
    static let microgram = Amount.Unit(name: "Microgram", abbreviation: "mcg", modifier: 1000000, type: .mass)
    static let pound = Amount.Unit(name: "Pound", abbreviation: "lb", modifier: 453.592, type: .mass)
    static let ounce = Amount.Unit(name: "Ounce", abbreviation: "oz", modifier: 28.3495, type: .mass)
    
    // Volume
    
    static let liter = Amount.Unit(name: "Liter", abbreviation: "L", modifier: 0.001, type: .volume)
    static let milliliter = Amount.Unit(name: "Milliliter", abbreviation: "mL", modifier: 1, type: .volume)
    static let fluidounce = Amount.Unit(name: "Fluid Ounce", abbreviation: "fl oz", modifier: 0.033814, type: .volume)
    
    static let all: [Amount.Unit] = [
        calorie,
        gram, milligram, microgram, pound, ounce,
        liter, milliliter
    ]
}
