import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingMeasurementField: View {
    let title: String
    let units: [String]
    @Binding var text: String
    @Binding var selectedUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizedAppString(title))
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("", text: decimalText)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)

                Menu {
                    ForEach(units, id: \.self) { unit in
                        Button(unit) {
                            selectedUnit = unit
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(selectedUnit)
                            .font(.caption.weight(.bold))

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.black))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .onAppear {
            text = Self.sanitizedDecimal(text, fractionalDigits: 1)
            if !units.contains(selectedUnit), let firstUnit = units.first {
                selectedUnit = firstUnit
            }
        }
        .onChange(of: text) { _, newValue in
            let cleaned = Self.sanitizedDecimal(newValue, fractionalDigits: 1)
            if cleaned != newValue {
                text = cleaned
            }
        }
        .onChange(of: selectedUnit) { _, newValue in
            if !units.contains(newValue), let firstUnit = units.first {
                selectedUnit = firstUnit
            }
        }
    }

    private var decimalText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                text = Self.sanitizedDecimal(newValue, fractionalDigits: 1)
            }
        )
    }

    private static func sanitizedDecimal(_ value: String, fractionalDigits: Int) -> String {
        var result = ""
        var hasDecimal = false
        var digitsAfterDecimal = 0

        for character in value.replacingOccurrences(of: ",", with: ".") {
            if character.isNumber {
                if hasDecimal {
                    guard digitsAfterDecimal < fractionalDigits else { continue }
                    digitsAfterDecimal += 1
                }

                result.append(character)
            } else if character == ".", !hasDecimal {
                hasDecimal = true
                result.append(result.isEmpty ? "0." : ".")
            }
        }

        return result
    }
}

