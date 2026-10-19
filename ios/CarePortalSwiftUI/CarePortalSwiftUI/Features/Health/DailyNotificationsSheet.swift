import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DailyNotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let notifications: [DailyNotificationItem]
    let onClear: (DailyNotificationItem) -> Void
    let onMarkTaken: (DailyNotificationItem) -> Void

    var body: some View {
        NavigationStack {
            List {
                if notifications.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "bell.slash.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.accent)

                        Text(localizedAppString("No notifications received today."))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .background(AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(notifications) { notification in
                        DailyNotificationRow(notification: notification)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    onClear(notification)
                                } label: {
                                    Label(localizedAppString("Clear"), systemImage: "xmark.circle.fill")
                                }
                                .tint(.red)

                                if notification.canMarkTaken {
                                    Button {
                                        onMarkTaken(notification)
                                    } label: {
                                        Label(localizedAppString("Done"), systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(AppTheme.accent)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Notifications Today"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

