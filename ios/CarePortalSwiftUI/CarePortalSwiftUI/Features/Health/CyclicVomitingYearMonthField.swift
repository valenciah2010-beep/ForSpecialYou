import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct CyclicVomitingYearMonthField: View {
    @Binding var year: String
    @Binding var month: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizedAppString("Onset Time of Recurrent Vomiting"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)

            HStack(spacing: 10) {
                CyclicVomitingCompactTextField(
                    placeholder: "Year",
                    text: $year
                )

                CyclicVomitingCompactTextField(
                    placeholder: "Month",
                    text: $month
                )
            }
        }
    }
}

