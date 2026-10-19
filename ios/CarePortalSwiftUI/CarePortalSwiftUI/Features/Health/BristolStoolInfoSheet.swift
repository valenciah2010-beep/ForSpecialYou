import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct BristolStoolInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    let tint: Color

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(1...7, id: \.self) { type in
                        HStack(alignment: .top, spacing: 12) {
                            BristolStoolIcon(type: type)
                                .frame(width: 76, height: 48)
                                .padding(8)
                                .background(tint.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(localizedAppString("Type")) \(type)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text)

                                Text(localizedAppString(BristolStoolGuide.group(for: type)))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(tint)

                                Text(localizedAppString(BristolStoolGuide.description(for: type)))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Bristol Stool Chart"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedAppString("Done")) {
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

