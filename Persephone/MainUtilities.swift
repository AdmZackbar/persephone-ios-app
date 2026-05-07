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
        Calendar.current.component(.year, from: self)
    }
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
    
    func atCurrentTime() -> Date {
        var components = Calendar.current.dateComponents(in: .current, from: self)
        let current = Calendar.current.dateComponents(in: .current, from: .now)
        components.hour = current.hour
        components.minute = current.minute
        components.second = current.second
        return Calendar.current.date(from: components)!
    }
    
    func lastSaturday(_ calendar: Calendar = .current) -> Date {
        let components = DateComponents(weekday: 7)
        return calendar.nextDate(
            after: self,
            matching: components,
            matchingPolicy: .nextTime,
            direction: .backward
        ) ?? self
    }
    
    func addDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
