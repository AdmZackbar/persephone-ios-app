//
//  RatingTier.swift
//  Persephone
//
//  Created by Zach Wassynger on 1/17/25.
//

enum RatingTier: String, CaseIterable, Codable, Identifiable {
    var id: String {
        rawValue
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
