//
//  MainUtilities.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import Foundation

extension Bool {
    static func ^ (lhs: Bool, rhs: Bool) -> Bool {
        return lhs != rhs
    }
}

extension Int {
    func monthText() -> String {
        Calendar.current.monthSymbols[self - 1]
    }
    
    func shortMonthText() -> String {
        Calendar.current.shortMonthSymbols[self - 1]
    }
    
    func yearText() -> String {
        self.formatted(.number.grouping(.never))
    }
}

extension Date {
    var year: Int {
        get {
            Calendar.current.component(.year, from: self)
        }
    }
    var month: Int {
        get {
            Calendar.current.component(.month, from: self)
        }
    }
    var day: Int {
        get {
            Calendar.current.component(.day, from: self)
        }
    }
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
