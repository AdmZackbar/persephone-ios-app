//
//  Currency.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

import Foundation

enum Currency: Codable, Equatable, Hashable, Comparable {
    case usd(_ cents: Int)
    
    static let zero: Currency = .usd(0)
    
    static func dollars(_ usd: Double) -> Currency {
        return .usd(Int(round(usd * 100.0)))
    }
    
    var cents: Int {
        switch self {
        case .usd(let c):
            return c
        }
    }
    var dollars: Double {
        return Double(cents) / 100.0
    }
    
    func formatted(maxDigits: Int = 2) -> String {
        let formatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = maxDigits
            return formatter
        }()
        return formatter.string(for: dollars)!
    }
    
    static func < (lhs: Currency, rhs: Currency) -> Bool {
        lhs.cents < rhs.cents
    }
    
    static prefix func - (x: Currency) -> Currency {
        switch x {
        case .usd(let c):
            return .usd(-c)
        }
    }
    
    static func + (lhs: Currency, rhs: Currency) -> Currency {
        switch lhs {
        case .usd(let c):
            return .usd(c + rhs.cents)
        }
    }
    
    static func - (lhs: Currency, rhs: Currency) -> Currency {
        lhs + (-rhs)
    }
    
    static func * (lhs: Currency, rhs: Double) -> Currency {
        switch lhs {
        case .usd(let c):
            return .usd(Int(round(Double(c) * rhs)))
        }
    }
    
    static func / (lhs: Currency, rhs: Double) -> Currency {
        switch lhs {
        case .usd(let c):
            return .usd(Int(round(Double(c) / rhs)))
        }
    }
}
