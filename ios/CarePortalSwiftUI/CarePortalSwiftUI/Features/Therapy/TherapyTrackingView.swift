import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TherapyTrackingView: View {
    let user: CarePortalUser

    @AppStorage private var milestoneData: Data
    @State private var activeCategory: TherapyCategory?

    init(user: CarePortalUser) {
        self.user = user
        self._milestoneData = AppStorage(wrappedValue: Data(), "therapy.\(user.id).milestoneData")
    }

    private var milestones: [TherapyMilestone] {
        guard !milestoneData.isEmpty else { return [] }
        return (try? JSONDecoder().decode([TherapyMilestone].self, from: milestoneData)) ?? []
    }

    private var recentMilestones: [TherapyMilestone] {
        milestones.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(
                        icon: "figure.mind.and.body",
                        title: "Therapy Tracking",
                        subtitle: "Log milestones and therapy wins to see your child's progress over time."
                    )

                    Button {
                        activeCategory = .therapySession
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: TherapyCategory.therapySession.icon)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(TherapyCategory.therapySession.tint)
                                .frame(width: 40, height: 40)
                                .background(TherapyCategory.therapySession.tint.opacity(0.14))
                                .clipShape(Circle())

                            Text(localizedAppString("Therapy Session"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()

                            Image(systemName: "plus")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(TherapyCategory.therapySession.tint.opacity(0.18), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(TherapyCategory.all) { category in
                            TherapyCategoryCard(
                                category: category,
                                count: milestones.filter { $0.categoryID == category.id }.count
                            ) {
                                activeCategory = category
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(localizedAppString("Recent Milestones"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()

                            NavigationLink {
                                TherapyMilestoneHistoryView(milestones: milestones)
                            } label: {
                                Label(localizedAppString("History"), systemImage: "clock.arrow.circlepath")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.accent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        if recentMilestones.isEmpty {
                            Text(localizedAppString("No milestones logged yet."))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(AppTheme.panel)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            ForEach(recentMilestones.prefix(5)) { milestone in
                                TherapyMilestoneRow(milestone: milestone)
                            }
                        }
                    }
                    .authPanel()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Therapy"))
            .sheet(item: $activeCategory) { category in
                TherapyMilestoneSheet(category: category) { milestone in
                    saveMilestone(milestone)
                }
            }
        }
    }

    private func saveMilestone(_ milestone: TherapyMilestone) {
        var updatedMilestones = milestones
        updatedMilestones.append(milestone)
        updatedMilestones.sort { $0.date < $1.date }

        if let data = try? JSONEncoder().encode(updatedMilestones) {
            milestoneData = data
        }
    }
}

