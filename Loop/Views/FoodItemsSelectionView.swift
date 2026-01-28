//
//  FoodItemsSelectionView.swift
//  Loop
//
//  Created by Claude on 2026-01-27.
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

/// A collapsible view for displaying and selecting individual food items from AI analysis
struct FoodItemsSelectionView: View {
    @Binding var selection: FoodItemSelection?
    @Binding var isExpanded: Bool
    let onToggleItem: (UUID) -> Void

    var body: some View {
        if let selection = selection {
            VStack(spacing: 0) {
                // Collapsed header row
                collapsedHeader(selection: selection)

                // Expanded content
                if isExpanded {
                    expandedContent(selection: selection)
                }
            }
        }
    }

    private func collapsedHeader(selection: FoodItemSelection) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text(selection.collapsedSummary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Text(formatCarbs(selection.selectedCarbs))
                    .font(.body.monospacedDigit())
                    .foregroundColor(.primary)
                    .fixedSize()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func expandedContent(selection: FoodItemSelection) -> some View {
        VStack(spacing: 0) {
            ForEach(selection.response.foodItems) { item in
                foodItemRow(item: item, isSelected: selection.isSelected(item.id))

                if item.id != selection.response.foodItems.last?.id {
                    Divider()
                        .padding(.leading, 32)
                }
            }
        }
        .padding(.top, 4)
    }

    private func foodItemRow(item: AIFoodItem, isSelected: Bool) -> some View {
        Button(action: {
            onToggleItem(item.id)
        }) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 24)

                if let emoji = item.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.body)
                }

                Text(item.name)
                    .font(.body)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Text(formatCarbs(item.carbs))
                    .font(.body.monospacedDigit())
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .fixedSize()
            }
            .padding(.vertical, 8)
            .padding(.leading, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatCarbs(_ carbs: Double) -> String {
        if carbs == floor(carbs) {
            return "\(Int(carbs))g"
        } else {
            return String(format: "%.1fg", carbs)
        }
    }
}

#if DEBUG
struct FoodItemsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleItems = [
            AIFoodItem(name: "Sandwich (turkey, cheese)", carbs: 32, emoji: "🥪", absorptionTime: .medium),
            AIFoodItem(name: "Apple", carbs: 15, emoji: "🍎", absorptionTime: .fast),
            AIFoodItem(name: "Diet Soda", carbs: 0, emoji: "🥤", absorptionTime: .fast)
        ]
        let response = AIFoodItemsResponse(foodItems: sampleItems, overallConfidence: 0.85)

        return VStack {
            StatefulPreviewWrapper(FoodItemSelection(response: response)) { selection in
                StatefulPreviewWrapper(false) { isExpanded in
                    FoodItemsSelectionView(
                        selection: Binding(
                            get: { selection.wrappedValue },
                            set: { selection.wrappedValue = $0! }
                        ),
                        isExpanded: isExpanded,
                        onToggleItem: { itemId in
                            selection.wrappedValue.toggleSelection(for: itemId)
                        }
                    )
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
#endif
