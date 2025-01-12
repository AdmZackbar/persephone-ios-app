//
//  NavigationStore.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/12/25.
//

import SwiftUI

@MainActor
final class NavigationStore: ObservableObject {
    @Published var path = NavigationPath()
    @Published var logConfig = LogConfig()
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func encoded() -> Data? {
        try? path.codable.map(encoder.encode)
    }
    
    func restore(from data: Data) {
        do {
            let codable = try decoder.decode(
                NavigationPath.CodableRepresentation.self, from: data
            )
            path = NavigationPath(codable)
        } catch {
            path = NavigationPath()
        }
    }
    
    func push(_ value: any Hashable) {
        path.append(value)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func replace(_ value: any Hashable) {
        pop()
        push(value)
    }
}

struct LogConfig: Hashable, Equatable {
    var date: Date
    var selectedType: LogType
    
    init(date: Date = .now, selectedType: LogType = .actual) {
        self.date = date
        self.selectedType = selectedType
    }
    
    func contains(_ date: Date) -> Bool {
        self.date.day == date.day
    }
    
    mutating func prev() {
        date = .from(year: date.year, month: date.month, day: date.day - 1)
    }
    
    mutating func next() {
        date = .from(year: date.year, month: date.month, day: date.day + 1)
    }
}
