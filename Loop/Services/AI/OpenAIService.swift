//
//  OpenAIService.swift
//  Loop
//
//  Created by Claude on 2026-01-01.
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import Foundation
import os.log

/// Errors that can occur during OpenAI API operations
enum OpenAIServiceError: LocalizedError {
    case missingAPIKey
    case invalidImageData
    case networkError(Error)
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case noContentInResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return NSLocalizedString("OpenAI API key is not configured", comment: "Error when OpenAI API key is missing")
        case .invalidImageData:
            return NSLocalizedString("Unable to process the selected image", comment: "Error when image data is invalid")
        case .networkError(let error):
            return String(format: NSLocalizedString("Network error: %@", comment: "Network error with description"), error.localizedDescription)
        case .invalidResponse(let statusCode):
            return String(format: NSLocalizedString("Server returned error (status %d)", comment: "Server error with status code"), statusCode)
        case .decodingError:
            return NSLocalizedString("Unable to parse the AI response", comment: "Error when response parsing fails")
        case .noContentInResponse:
            return NSLocalizedString("No content returned from AI", comment: "Error when AI returns empty response")
        }
    }
}

/// Response from OpenAI Vision API containing carb estimate and food description
struct OpenAICarbEstimateResponse {
    /// Estimated carbohydrate count in grams
    let estimatedCarbs: Double

    /// Short food description (suitable for form field)
    let foodDescription: String

    /// Detailed description of what the AI observed
    let detailedDescription: String

    /// AI's confidence in the estimate ("high", "medium", "low")
    let confidence: String?
}

/// Service for interacting with OpenAI Vision API to analyze food images
final class OpenAIService {
    static let shared = OpenAIService()

    private let log = OSLog(subsystem: "com.loopkit.Loop", category: "OpenAIService")
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Retrieves the OpenAI API key from the app's Info.plist (configured via LoopConfigOverride.xcconfig)
    private func getAPIKey() throws -> String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String,
              !apiKey.isEmpty,
              apiKey != "$(OPENAI_API_KEY)" else {
            os_log("OpenAI API key not configured in LoopConfigOverride.xcconfig", log: log, type: .error)
            throw OpenAIServiceError.missingAPIKey
        }
        return apiKey
    }

    /// Analyzes a food image and returns estimated carbohydrate content
    /// - Parameter imageData: JPEG image data of the food to analyze
    /// - Returns: OpenAICarbEstimateResponse containing carb estimate and description
    func estimateCarbs(from imageData: Data) async throws -> OpenAICarbEstimateResponse {
        let apiKey = try getAPIKey()
        let base64Image = imageData.base64EncodedString()

        os_log("Sending food image for AI analysis (%d bytes)", log: log, type: .info, imageData.count)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        Analyze this food image and estimate the carbohydrate content. Be accurate and consider portion sizes visible in the image.

        Respond ONLY with valid JSON in this exact format (no other text):
        {
            "estimatedCarbs": <number in grams>,
            "foodDescription": "<short name, max 25 chars>",
            "detailedDescription": "<detailed description of food items and portions>",
            "confidence": "<high|medium|low>"
        }
        """

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            os_log("OpenAI API error: status %d", log: log, type: .error, httpResponse.statusCode)
            if let errorBody = String(data: data, encoding: .utf8) {
                os_log("Error body: %{public}@", log: log, type: .error, errorBody)
            }
            throw OpenAIServiceError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        return try parseResponse(data)
    }

    /// Parses the OpenAI API response to extract carb estimate
    private func parseResponse(_ data: Data) throws -> OpenAICarbEstimateResponse {
        // Parse the OpenAI response structure
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIServiceError.noContentInResponse
        }

        os_log("Received AI response content: %{public}@", log: log, type: .debug, content)

        // Extract JSON from the content (AI might include markdown code blocks)
        let jsonString = extractJSON(from: content)

        guard let jsonData = jsonString.data(using: .utf8),
              let result = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw OpenAIServiceError.decodingError(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON from response"]))
        }

        guard let estimatedCarbs = result["estimatedCarbs"] as? Double ?? (result["estimatedCarbs"] as? Int).map(Double.init),
              let foodDescription = result["foodDescription"] as? String,
              let detailedDescription = result["detailedDescription"] as? String else {
            throw OpenAIServiceError.decodingError(NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields in response"]))
        }

        let confidence = result["confidence"] as? String

        os_log("AI estimated %{public}.1f grams of carbs for: %{public}@", log: log, type: .info, estimatedCarbs, foodDescription)

        return OpenAICarbEstimateResponse(
            estimatedCarbs: estimatedCarbs,
            foodDescription: foodDescription,
            detailedDescription: detailedDescription,
            confidence: confidence
        )
    }

    /// Extracts JSON from a string that might contain markdown code blocks
    private func extractJSON(from content: String) -> String {
        // Try to find JSON in code block first
        if let codeBlockRange = content.range(of: "```json"),
           let endRange = content.range(of: "```", range: codeBlockRange.upperBound..<content.endIndex) {
            return String(content[codeBlockRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try plain code block
        if let codeBlockRange = content.range(of: "```"),
           let endRange = content.range(of: "```", range: codeBlockRange.upperBound..<content.endIndex) {
            return String(content[codeBlockRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try to find JSON object directly
        if let startBrace = content.firstIndex(of: "{"),
           let endBrace = content.lastIndex(of: "}") {
            return String(content[startBrace...endBrace])
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
