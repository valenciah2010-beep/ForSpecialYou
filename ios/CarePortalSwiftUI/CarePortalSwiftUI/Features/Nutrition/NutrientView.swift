import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct NutrientView: View {
    let user: CarePortalUser

    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @AppStorage private var mealPhotoData: Data
    @AppStorage private var mealEstimateData: Data
    @AppStorage private var savedMealHistoryData: Data
    @AppStorage private var dailyUsageData: Data
    @AppStorage private var dailyEstimateLimit: Int
    @AppStorage private var nutritionGoalsData: Data
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var isMealPhotoSourcePresented = false
    @State private var isCameraPickerPresented = false
    @State private var isEstimating = false
    @State private var estimateError = ""
    @State private var saveMessage = ""
    @State private var hasSavedCurrentMeal = false
    @State private var isEstimateEditorPresented = false
    @State private var isManualMealEntryPresented = false
    @State private var activeMealPDF: MealPDFShareItem?
    @State private var nutritionGoals = NutritionGoals()

    init(user: CarePortalUser) {
        self.user = user
        self._mealPhotoData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).mealPhotoData")
        self._mealEstimateData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).mealEstimateData")
        self._savedMealHistoryData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).savedMealHistoryData")
        self._dailyUsageData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).dailyUsageData")
        self._dailyEstimateLimit = AppStorage(wrappedValue: 3, "nutrient.\(user.id).dailyEstimateLimit")
        self._nutritionGoalsData = AppStorage(wrappedValue: Data(), "nutrient.\(user.id).nutritionGoalsData")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 12) {
                        PageHeader(
                            icon: "leaf",
                            title: "Nutrient",
                            subtitle: "Estimate meals, hydration, safe foods, and feeding patterns."
                        )

                        NavigationLink {
                            MealHistoryView(savedMeals: savedMealHistory)
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.accent.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(localizedAppString("Meal history"))
                        .padding(.top, 2)
                    }

                    Button {
                        isManualMealEntryPresented = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.pencil")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(AppTheme.accent)
                                .clipShape(Circle())

                            Text(localizedAppString("Add Meal Manually"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.text.opacity(0.65))
                        }
                        .padding(16)
                        .background(AppTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 16) {
                        NutrientDailyLimitSummary(
                            estimateCount: dailyUsage.estimateCount,
                            limit: dailyEstimateLimit
                        )

                        NavigationLink {
                            NutritionGoalsPage(goals: $nutritionGoals) {
                                saveNutritionGoals()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(localizedAppString(nutritionGoals.isEmpty ? "Set Nutrition Goals" : "View Nutrition Goals"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.text.opacity(0.75))
                            }
                            .padding(16)
                            .background(AppTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            openMealPhotoSource()
                        } label: {
                            MealPhotoUploadPanel(imageData: mealPhotoData)
                                .opacity(canUploadMealPhoto ? 1 : 0.55)
                        }
                        .buttonStyle(.plain)

                        Button {
                            estimateMeal()
                        } label: {
                            HStack {
                                if isEstimating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                }

                                Text(localizedAppString(isEstimating ? "Estimating..." : "Estimate Nutrients"))
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(mealPhotoData.isEmpty || !canEstimateMeal ? Color.gray.opacity(0.45) : AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(mealPhotoData.isEmpty || isEstimating)

                        if !estimateError.isEmpty {
                            Text(estimateError)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !saveMessage.isEmpty {
                            Text(saveMessage)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let estimate = mealEstimate {
                            Button {
                                saveCurrentMeal(estimate)
                            } label: {
                                Label(localizedAppString(hasSavedCurrentMeal ? "Saved" : "Save Meal"), systemImage: hasSavedCurrentMeal ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(hasSavedCurrentMeal ? Color.gray.opacity(0.55) : AppTheme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(mealPhotoData.isEmpty || hasSavedCurrentMeal)

                            Button {
                                exportCurrentMealPDF(estimate)
                            } label: {
                                Label(localizedAppString("Export as PDF"), systemImage: "doc.richtext.fill")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(mealPhotoData.isEmpty)

                            MealNutritionEstimateView(estimate: estimate)
                                .onTapGesture {
                                    isEstimateEditorPresented = true
                                }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                HealthMetricRow(icon: "fork.knife", title: "Meals", value: localizedAppString("0 analyzed"))
                                HealthMetricRow(icon: "flame.fill", title: "Calories", value: "--")
                                HealthMetricRow(icon: "chart.pie.fill", title: "Macros", value: "--")
                            }
                        }
                    }
                    .authPanel()
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(localizedAppString("Nutrient"))
            .onAppear {
                resetCurrentMealForNextImage()
                loadStoredNutritionGoals()
                syncSavedMealHistoryIfNeeded()
                syncNutrientDailyUsage(dailyUsage)
            }
            .task {
                await refreshNutrientSettings()
            }
            .task(id: selectedMealPhoto) {
                await loadSelectedMealPhoto()
            }
            .sheet(isPresented: $isMealPhotoSourcePresented) {
                MealPhotoSourceSheet(
                    selectedMealPhoto: $selectedMealPhoto,
                    cameraAvailable: UIImagePickerController.isSourceTypeAvailable(.camera),
                    takePhoto: openMealCamera,
                    cameraUnavailable: {
                        saveMessage = localizedAppString("Camera unavailable on this device.")
                    }
                )
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $isCameraPickerPresented) {
                CameraMealPhotoPicker { data in
                    applyMealPhotoData(data)
                }
                .ignoresSafeArea()
            }
            .sheet(item: $activeMealPDF) { item in
                PDFShareSheet(url: item.url)
            }
            .sheet(isPresented: $isEstimateEditorPresented) {
                if let estimate = mealEstimate {
                    MealEstimateEditorSheet(
                        title: "Edit Nutrient Estimate",
                        estimate: estimate,
                        requiresPhoto: false
                    ) { updatedEstimate in
                        updateCurrentEstimate(updatedEstimate)
                    }
                }
            }
            .sheet(isPresented: $isManualMealEntryPresented) {
                ManualMealEntrySheet { imageData, estimate in
                    saveManualMeal(imageData: imageData, estimate: estimate)
                }
            }
        }
    }

    private func resetCurrentMealForNextImage() {
        mealPhotoData = Data()
        mealEstimateData = Data()
        selectedMealPhoto = nil
        estimateError = ""
        saveMessage = ""
        hasSavedCurrentMeal = false
        isEstimating = false
    }

    private func syncSavedMealHistoryIfNeeded() {
        let meals = savedMealHistory
        guard !meals.isEmpty else { return }
        syncSavedMeals(meals, showFailure: true)
    }

    private var mealEstimate: MealNutritionEstimate? {
        guard !mealEstimateData.isEmpty else { return nil }
        return try? JSONDecoder().decode(MealNutritionEstimate.self, from: mealEstimateData)
    }

    private var savedMealHistory: [SavedMealEstimate] {
        guard !savedMealHistoryData.isEmpty,
              let savedMeals = try? JSONDecoder().decode([SavedMealEstimate].self, from: savedMealHistoryData) else {
            return []
        }

        return savedMeals.sorted { $0.savedAt > $1.savedAt }
    }

    private var dailyUsage: NutrientDailyUsage {
        guard !dailyUsageData.isEmpty,
              let usage = try? JSONDecoder().decode(NutrientDailyUsage.self, from: dailyUsageData),
              usage.dateKey == String(ISO8601DateFormatter().string(from: Date()).prefix(10)) else {
            return NutrientDailyUsage.today()
        }

        return usage
    }

    private var canUploadMealPhoto: Bool {
        canEstimateMeal
    }

    private var canEstimateMeal: Bool {
        dailyUsage.estimateCount < dailyEstimateLimit
    }

    private func openMealPhotoSource() {
        guard canUploadMealPhoto else {
            saveMessage = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        isMealPhotoSourcePresented = true
    }

    private func loadSelectedMealPhoto() async {
        guard let selectedMealPhoto else { return }

        do {
            if let data = try await selectedMealPhoto.loadTransferable(type: Data.self) {
                await MainActor.run {
                    applyMealPhotoData(data)
                }
            }
        } catch {
            // Photo selection is user-driven; keeping the existing photo avoids data loss.
        }
    }

    private func openMealCamera() {
        guard canUploadMealPhoto else {
            saveMessage = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isCameraPickerPresented = true
        }
    }

    private func applyMealPhotoData(_ data: Data) {
        guard canUploadMealPhoto else {
            selectedMealPhoto = nil
            saveMessage = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        mealPhotoData = data
        mealEstimateData = Data()
        selectedMealPhoto = nil
        estimateError = ""
        saveMessage = ""
        hasSavedCurrentMeal = false
    }

    private func estimateMeal() {
        guard !mealPhotoData.isEmpty else { return }
        guard canEstimateMeal else {
            estimateError = String(
                format: localizedAppString("Daily nutrient estimate limit reached with limit %@."),
                "\(dailyEstimateLimit)"
            )
            return
        }

        isEstimating = true
        estimateError = ""
        saveMessage = ""
        hasSavedCurrentMeal = false

        Task {
            do {
                let estimate = try await NutritionAPI().analyzeMeal(
                    imageData: mealImageDataURL(),
                    language: AppLanguage(code: languageCode).apiName
                )
                await MainActor.run {
                    if let data = try? JSONEncoder().encode(estimate) {
                        mealEstimateData = data
                    }
                    applyMealEstimateToNutritionGoals(estimate)
                    isEstimating = false
                }
                await refreshNutrientSettings()
            } catch {
                await MainActor.run {
                    estimateError = error.localizedDescription
                    isEstimating = false
                }
                await refreshNutrientSettings()
            }
        }
    }

    private func incrementDailyUsage(upload: Int = 0, estimate: Int = 0) {
        var usage = dailyUsage
        usage.uploadCount += upload
        usage.estimateCount += estimate

        if let data = try? JSONEncoder().encode(usage) {
            dailyUsageData = data
        }

        syncNutrientDailyUsage(usage)
    }

    private func refreshNutrientSettings() async {
        do {
            let settings = try await AuthAPI().appSettings(userId: user.id)
            await MainActor.run {
                dailyEstimateLimit = max(0, settings.nutrientDailyLimit)
                if let usage = settings.nutrientDailyUsage, let data = try? JSONEncoder().encode(usage) {
                    dailyUsageData = data
                }
            }
        } catch {
            // The local limit remains usable if the backend is offline.
        }
    }

    private func syncNutrientDailyUsage(_ usage: NutrientDailyUsage) {
        Task {
            do {
                try await AuthAPI().syncAppData(
                    userId: user.id,
                    childProfile: nil,
                    healthLogs: nil,
                    savedMeals: nil,
                    nutrientDailyUsage: usage
                )
            } catch {
                print("Nutrient usage sync failed for user \(user.id): \(error.localizedDescription)")
            }
        }
    }

    private func saveCurrentMeal(_ estimate: MealNutritionEstimate) {
        guard !mealPhotoData.isEmpty else { return }
        guard !hasSavedCurrentMeal else { return }

        var savedMeals = savedMealHistory
        let savedImageData = savedMealImageData()
        savedMeals.insert(
            SavedMealEstimate(
                savedAt: Date(),
                imageData: savedImageData,
                estimate: estimate
            ),
            at: 0
        )

        if let data = try? JSONEncoder().encode(savedMeals) {
            savedMealHistoryData = data
            saveMessage = localizedAppString("Meal saved to history.")
            hasSavedCurrentMeal = true
            syncSavedMeals(savedMeals, showFailure: true)
            mealPhotoData = Data()
            mealEstimateData = Data()
            selectedMealPhoto = nil
        } else {
            saveMessage = localizedAppString("Unable to save this meal.")
        }
    }

    private func updateCurrentEstimate(_ estimate: MealNutritionEstimate) {
        if let data = try? JSONEncoder().encode(estimate) {
            mealEstimateData = data
            hasSavedCurrentMeal = false
            saveMessage = localizedAppString("Estimate updated. Save meal to keep the corrected information in history.")
        } else {
            saveMessage = localizedAppString("Unable to update this estimate.")
        }
    }

    private func saveManualMeal(imageData: Data, estimate: MealNutritionEstimate) {
        guard !imageData.isEmpty else {
            saveMessage = localizedAppString("Add a meal photo before saving.")
            return
        }

        var savedMeals = savedMealHistory
        let compressedImageData = savedMealImageData(from: imageData)
        savedMeals.insert(
            SavedMealEstimate(
                savedAt: Date(),
                imageData: compressedImageData,
                estimate: estimate
            ),
            at: 0
        )

        if let data = try? JSONEncoder().encode(savedMeals) {
            savedMealHistoryData = data
            saveMessage = localizedAppString("Manual meal saved to history.")
            applyMealEstimateToNutritionGoals(estimate)
            syncSavedMeals(savedMeals, showFailure: true)
        } else {
            saveMessage = localizedAppString("Unable to save this meal.")
        }
    }

    private func exportCurrentMealPDF(_ estimate: MealNutritionEstimate) {
        guard !mealPhotoData.isEmpty,
              let url = MealPDFExporter.export(imageData: mealPhotoData, estimate: estimate, savedAt: Date()) else {
            saveMessage = localizedAppString("Unable to create PDF.")
            return
        }

        activeMealPDF = MealPDFShareItem(url: url)
    }

    private func syncSavedMeals(_ savedMeals: [SavedMealEstimate], showFailure: Bool = false) {
        guard !savedMeals.isEmpty else { return }

        let backendMeals = savedMeals.map { meal in
            SavedMealEstimate(
                id: meal.id,
                savedAt: meal.savedAt,
                imageData: Data(),
                estimate: meal.estimate
            )
        }

        Task {
            do {
                try await AuthAPI().syncAppData(
                    userId: user.id,
                    childProfile: nil,
                    healthLogs: nil,
                    savedMeals: backendMeals
                )
                print("Saved nutrient meals synced for user \(user.id). Meals: \(backendMeals.count)")
            } catch {
                if showFailure {
                    await MainActor.run {
                        saveMessage = localizedAppString("Meal saved on this phone, but backend sync failed. Make sure the configured server is reachable.")
                    }
                }
                print("Saved nutrient meals sync failed for user \(user.id): \(error.localizedDescription)")
            }
        }
    }

    private var storedNutritionGoals: NutritionGoals {
        guard !nutritionGoalsData.isEmpty,
              let savedGoals = try? JSONDecoder().decode(NutritionGoals.self, from: nutritionGoalsData) else {
            return NutritionGoals()
        }

        return savedGoals
    }

    private func loadStoredNutritionGoals() {
        nutritionGoals = storedNutritionGoals
        let previousDateKey = nutritionGoals.consumedDateKey
        nutritionGoals.resetDailyProgressIfNeeded()
        if previousDateKey != nutritionGoals.consumedDateKey {
            saveNutritionGoals(showMessage: false)
        }
    }

    private func saveNutritionGoals(showMessage: Bool = true) {
        nutritionGoals.lastUpdated = Date()
        if let data = try? JSONEncoder().encode(nutritionGoals) {
            nutritionGoalsData = data
            if showMessage {
                saveMessage = localizedAppString("Nutrition goals saved")
            }
        }
    }

    private func applyMealEstimateToNutritionGoals(_ estimate: MealNutritionEstimate) {
        nutritionGoals.applyMealEstimate(estimate)
        if nutritionGoals.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nutritionGoals.notes = localizedAppString("Auto-filled from latest AI meal estimate.")
        }
        saveNutritionGoals(showMessage: false)
    }

    private func savedMealImageData() -> Data {
        savedMealImageData(from: mealPhotoData)
    }

    private func savedMealImageData(from imageData: Data) -> Data {
        if let image = UIImage(data: imageData),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 900).jpegData(compressionQuality: 0.72) {
            return jpegData
        }

        return imageData
    }

    private func mealImageDataURL() -> String {
        if let image = UIImage(data: mealPhotoData),
           let jpegData = image.resizedForMealAnalysis(maxDimension: 1200).jpegData(compressionQuality: 0.74) {
            return "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
        }

        return "data:image/jpeg;base64,\(mealPhotoData.base64EncodedString())"
    }
}

