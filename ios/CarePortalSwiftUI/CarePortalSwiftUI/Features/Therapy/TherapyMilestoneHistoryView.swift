import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TherapyMilestoneHistoryView: View {
    let milestones: [TherapyMilestone]

    @State private var selectedCategoryIDs: Set<String> = []
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    @State private var endDate = Date()

    private var sortedMilestones: [TherapyMilestone] {
        milestones.sorted { $0.date > $1.date }
    }

    private var filteredMilestones: [TherapyMilestone] {
        sortedMilestones.filter { milestone in
            let matchesCategory = selectedCategoryIDs.isEmpty || selectedCategoryIDs.contains(milestone.categoryID)
            let dateRange = normalizedDateRange
            return matchesCategory && milestone.date >= dateRange.start && milestone.date <= dateRange.end
        }
    }

    private var normalizedDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let earlier = min(startDate, endDate)
        let later = max(startDate, endDate)
        let start = calendar.startOfDay(for: earlier)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: later)) ?? later
        return (start, end)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedAppString("Therapy Type"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TherapyFilterChip(
                                title: "All",
                                isSelected: selectedCategoryIDs.isEmpty,
                                tint: AppTheme.accent
                            ) {
                                selectedCategoryIDs.removeAll()
                            }

                            ForEach(TherapyCategory.all) { category in
                                TherapyFilterChip(
                                    title: category.title,
                                    isSelected: selectedCategoryIDs.contains(category.id),
                                    tint: category.tint
                                ) {
                                    toggleCategory(category.id)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .authPanel()

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedAppString("Time Frame"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    VStack(spacing: 10) {
                        DatePicker(
                            localizedAppString("Start Date"),
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        .font(.subheadline.weight(.semibold))

                        DatePicker(
                            localizedAppString("End Date"),
                            selection: $endDate,
                            displayedComponents: .date
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(12)
                    .background(AppTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .authPanel()

                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString("Milestones"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.text)

                    if filteredMilestones.isEmpty {
                        Text(localizedAppString("No milestones found."))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ForEach(filteredMilestones) { milestone in
                            TherapyMilestoneRow(milestone: milestone)
                        }
                    }
                }
                .authPanel()
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(localizedAppString("History"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleCategory(_ id: String) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }
}

