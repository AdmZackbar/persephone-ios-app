//
//  Amount.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

struct Amount: Codable, Hashable, Equatable {
    var value: Value
    var unitStr: String?
    
    init(value: Value = .raw(0), unitStr: String? = nil) {
        self.value = value
        self.unitStr = unitStr
    }
    
    enum Value: Codable, Equatable, Hashable {
        case raw(_ value: Double)
        case rational(num: Double, den: Double)
    }
}
