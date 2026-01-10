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

    /// Emoji representation of the food (1-3 emojis)
    let emoji: String

    /// AI's recommended absorption time category
    let absorptionTime: AbsorptionTimeCategory

    /// Confidence level for the carb estimate (0.0-1.0)
    let carbConfidence: Double

    /// Confidence level for the absorption time estimate (0.0-1.0)
    let absorptionConfidence: Double

    /// Confidence level for the emoji selection (0.0-1.0)
    let emojiConfidence: Double

    /// Whether the user modified the AI-suggested values before submission
    var userModified: Bool

    /// When the AI analysis was performed
    let analyzedAt: Date

    init(
        detailedDescription: String,
        estimatedCarbs: Double,
        emoji: String,
        absorptionTime: AbsorptionTimeCategory,
        carbConfidence: Double,
        absorptionConfidence: Double,
        emojiConfidence: Double,
        userModified: Bool = false,
        analyzedAt: Date = Date()
    ) {
        self.detailedDescription = detailedDescription
        self.estimatedCarbs = estimatedCarbs
        self.emoji = emoji
        self.absorptionTime = absorptionTime
        self.carbConfidence = carbConfidence
        self.absorptionConfidence = absorptionConfidence
        self.emojiConfidence = emojiConfidence
        self.userModified = userModified
        self.analyzedAt = analyzedAt
    }

    /// Returns a dictionary representation suitable for logging to external services
    var asDictionary: [String: Any] {
        return [
            "detailedDescription": detailedDescription,
            "estimatedCarbs": estimatedCarbs,
            "emoji": emoji,
            "absorptionTime": absorptionTime.rawValue,
            "absorptionTimeHours": absorptionTime.typicalHours,
            "carbConfidence": carbConfidence,
            "absorptionConfidence": absorptionConfidence,
            "emojiConfidence": emojiConfidence,
            "userModified": userModified,
            "analyzedAt": ISO8601DateFormatter().string(from: analyzedAt)
        ]
    }

    /// Returns a formatted string suitable for Nightscout notes field
    var asNightscoutNotes: String {
        var notes = "AI-Assisted Entry"
        if !emoji.isEmpty {
            notes += " \(emoji)"
        }
        notes += " | Est: \(Int(estimatedCarbs))g (conf: \(Int(carbConfidence * 100))%)"
        notes += " | Absorption: \(absorptionTime.rawValue) (conf: \(Int(absorptionConfidence * 100))%)"
        if userModified {
            notes += " | User modified"
        }
        notes += " | \(detailedDescription)"
        return notes
    }
}
