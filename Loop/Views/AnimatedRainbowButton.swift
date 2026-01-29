//
//  AnimatedRainbowButton.swift
//  Loop
//
//  Created for AI-assisted carb entry feature.
//  Copyright © 2024 LoopKit Authors. All rights reserved.
//

import SwiftUI
import UIKit

/// An animated rainbow outline button with a rotating gradient border,
/// designed for AI-related features with a modern, magical appearance.
struct AnimatedRainbowButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void

    @State private var rotation: Double = 0
    @State private var isAnimating = false
    @State private var introGlow: Double = 1.0

    // Rainbow colors for the animated gradient
    private let rainbowColors: [Color] = [
        Color(hue: 0.0, saturation: 0.8, brightness: 1.0),   // Red
        Color(hue: 0.08, saturation: 0.9, brightness: 1.0),  // Orange
        Color(hue: 0.13, saturation: 0.9, brightness: 1.0),  // Yellow
        Color(hue: 0.35, saturation: 0.8, brightness: 0.9),  // Green
        Color(hue: 0.55, saturation: 0.8, brightness: 1.0),  // Cyan
        Color(hue: 0.65, saturation: 0.8, brightness: 1.0),  // Blue
        Color(hue: 0.75, saturation: 0.7, brightness: 1.0),  // Purple
        Color(hue: 0.85, saturation: 0.8, brightness: 1.0),  // Magenta
        Color(hue: 0.0, saturation: 0.8, brightness: 1.0),   // Back to Red
    ]

    init(
        title: String,
        icon: String = "sparkles",
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Animated rainbow border
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 2.5
                    )
                    .blur(radius: 0.5)

                // Subtle glow effect behind the border
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 4 + (introGlow * 4)
                    )
                    .blur(radius: 6 + (introGlow * 6))
                    .opacity(0.4 + (introGlow * 0.4))

                // Clear background with slight tint
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.systemBackground).opacity(0.95))

                // Button content
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }

                    Text(title)
                        .bold()
                }
                .foregroundColor(introGlow > 0.01 ? Color(hue: 0.70, saturation: 0.6 * introGlow, brightness: 0.5 + (0.3 * introGlow)) : .primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
        .onAppear {
            startAnimation()
            // Fade intro glow to normal after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 2.0)) {
                    introGlow = 0
                }
            }
        }
    }

    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        withAnimation(
            .linear(duration: 3)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedRainbowButton(
            title: "Analyze Food with AI",
            icon: "sparkles",
            isLoading: false,
            action: {}
        )
        .padding(.horizontal)

        AnimatedRainbowButton(
            title: "Analyzing...",
            icon: "sparkles",
            isLoading: true,
            action: {}
        )
        .padding(.horizontal)
    }
    .padding(.vertical)
    .background(Color(UIColor.systemGroupedBackground))
}
