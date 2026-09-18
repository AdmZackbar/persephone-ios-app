//
//  HealthKitManager.swift
//  Persephone
//
//  Created by Zach Wassynger on 9/18/26.
//

import Foundation
import HealthKit

/// Writes daily nutrition totals to HealthKit, overwriting whatever this app
/// previously saved for that day so re-syncing never creates duplicates.
final class HealthKitManager: Sendable {
    static let shared = HealthKitManager()
    
    private let store = HKHealthStore()
    
    private init() {}
    
    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Nutrients with a directly corresponding HealthKit dietary quantity type.
    /// `AddedSugars` and `TransFat` have no HealthKit equivalent and are omitted.
    private static let nutrientMapping: [Nutrient: (identifier: HKQuantityTypeIdentifier, unit: HKUnit)] = [
        .Energy: (.dietaryEnergyConsumed, .kilocalorie()),
        .TotalCarbs: (.dietaryCarbohydrates, .gram()),
        .DietaryFiber: (.dietaryFiber, .gram()),
        .TotalSugars: (.dietarySugar, .gram()),
        .TotalFat: (.dietaryFatTotal, .gram()),
        .SaturatedFat: (.dietaryFatSaturated, .gram()),
        .PolyunsaturatedFat: (.dietaryFatPolyunsaturated, .gram()),
        .MonounsaturatedFat: (.dietaryFatMonounsaturated, .gram()),
        .Protein: (.dietaryProtein, .gram()),
        .Sodium: (.dietarySodium, .gramUnit(with: .milli)),
        .Cholesterol: (.dietaryCholesterol, .gramUnit(with: .milli)),
        .Calcium: (.dietaryCalcium, .gramUnit(with: .milli)),
        .VitaminD: (.dietaryVitaminD, .gramUnit(with: .micro)),
        .Iron: (.dietaryIron, .gramUnit(with: .milli)),
        .Potassium: (.dietaryPotassium, .gramUnit(with: .milli)),
    ]
    
    private static var quantityTypes: Set<HKQuantityType> {
        Set(nutrientMapping.values.compactMap { HKQuantityType.quantityType(forIdentifier: $0.identifier) })
    }
    
    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: Self.quantityTypes, read: [])
    }
    
    /// Overwrites HealthKit's dietary samples for `date` with the totals in `nutrients`.
    func save(nutrients: Nutrients, for date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }
        let dayPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate),
            HKQuery.predicateForObjects(from: .default())
        ])
        
        var samples: [HKQuantitySample] = []
        for (nutrient, mapping) in Self.nutrientMapping {
            guard let quantityType = HKQuantityType.quantityType(forIdentifier: mapping.identifier) else {
                continue
            }
            // Clear this day's existing entry so the new total fully replaces it, rather than adding to it.
            _ = try await store.deleteObjects(of: quantityType, predicate: dayPredicate)
            
            guard let value = nutrients[nutrient], value > 0 else {
                continue
            }
            let quantity = HKQuantity(unit: mapping.unit, doubleValue: value)
            samples.append(HKQuantitySample(type: quantityType, quantity: quantity, start: startOfDay, end: startOfDay))
        }
        
        if !samples.isEmpty {
            try await store.save(samples)
        }
    }
}
