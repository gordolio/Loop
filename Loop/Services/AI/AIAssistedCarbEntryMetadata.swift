//
//  AIAssistedCarbEntryMetadata.swift
//  Loop
//
//  Created by Claude on 2026-01-01.
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import Foundation

/// Metadata captured when a carb entry is created using AI-assisted food photo analysis
struct AIAssistedCarbEntryMetadata: Codable, Equatable {
    /// Detailed description of the food as analyzed by AI
    let detailedDescription: String

    /// AI's estimated carbohydrate count in grams
    let estimatedCarbs: Double

    /// AI's confidence level in the estimate ("high", "medium", "low")
    let confidence: String?

    /// Whether the user modified the AI-suggested values before submission
    var userModified: Bool

    /// When the AI analysis was performed
    let analyzedAt: Date

    init(
        detailedDescription: String,
        estimatedCarbs: Double,
        confidence: String?,
        userModified: Bool = false,
        analyzedAt: Date = Date()
    ) {
        self.detailedDescription = detailedDescription
        self.estimatedCarbs = estimatedCarbs
        self.confidence = confidence
        self.userModified = userModified
        self.analyzedAt = analyzedAt
    }

    /// Returns a dictionary representation suitable for logging to external services
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "detailedDescription": detailedDescription,
            "estimatedCarbs": estimatedCarbs,
            "userModified": userModified,
            "analyzedAt": ISO8601DateFormatter().string(from: analyzedAt)
        ]
        if let confidence = confidence {
            dict["confidence"] = confidence
        }
        return dict
    }

    /// Returns a formatted string suitable for Nightscout notes field
    var asNightscoutNotes: String {
        var notes = "AI-Assisted Entry | Est: \(Int(estimatedCarbs))g"
        if let confidence = confidence {
            notes += " (\(confidence) confidence)"
        }
        if userModified {
            notes += " | User modified"
        }
        notes += " | \(detailedDescription)"
        return notes
    }
}
