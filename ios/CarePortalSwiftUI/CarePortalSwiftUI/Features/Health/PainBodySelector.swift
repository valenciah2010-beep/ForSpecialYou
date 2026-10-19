import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct PainBodySelector: View {
    @Binding var painPoints: [PainPoint]
    let tint: Color

    @State private var selectedSide: PainBodySide = .front

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedAppString("Pain Location"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            VStack(spacing: 10) {
                Picker("Body side", selection: $selectedSide) {
                    ForEach(PainBodySide.allCases) { side in
                        Text(LocalizedStringKey(side.rawValue)).tag(side)
                    }
                }
                .pickerStyle(.segmented)

                TappablePainBodyMap(
                    side: selectedSide,
                    painPoints: $painPoints,
                    tint: tint
                )
                .frame(height: 430)

                if !painPoints.isEmpty {
                    Button {
                        painPoints.removeAll()
                    } label: {
                        Label(localizedAppString("Clear pain dots"), systemImage: "xmark.circle")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(painPoints.isEmpty ? localizedAppString("Tap directly on the body to mark pain. Maximum 5 dots.") : String(format: localizedAppString("%d/5 pain dot(s) marked"), painPoints.count))
                .font(.caption.weight(.bold))
                .foregroundStyle(painPoints.isEmpty ? .secondary : tint)
        }
    }
}

