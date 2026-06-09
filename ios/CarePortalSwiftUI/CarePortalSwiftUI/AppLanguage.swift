import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    static let storageKey = "app.languageCode"

    var id: String { rawValue }

    init(code: String) {
        self = AppLanguage(rawValue: code) ?? .english
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }

    var apiName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "Simplified Chinese"
        }
    }
}

func localizedAppString(_ key: String, languageCode: String? = nil) -> String {
    let code = languageCode ?? UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.english.rawValue
    guard
        let path = Bundle.main.path(forResource: code, ofType: "lproj"),
        let bundle = Bundle(path: path)
    else {
        return NSLocalizedString(key, comment: "")
    }

    return NSLocalizedString(key, bundle: bundle, comment: "")
}

func localizedServerMessage(_ message: String) -> String {
    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)

    let blockedPrefix = "This account is blocked until "
    if trimmed.hasPrefix(blockedPrefix), trimmed.hasSuffix(".") {
        let dateText = String(trimmed.dropFirst(blockedPrefix.count).dropLast())
        return String(format: localizedAppString("This account is blocked until %@."), dateText)
    }

    return localizedAppString(trimmed)
}

func localizedDateString(
    _ date: Date,
    dateStyle: DateFormatter.Style = .medium,
    timeStyle: DateFormatter.Style = .short
) -> String {
    let code = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.english.rawValue
    let formatter = DateFormatter()
    formatter.locale = AppLanguage(code: code).locale
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter.string(from: date)
}

func localizedSavedAIText(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return trimmed }

    let translations = [
        "This meal offers a balanced mix of protein, fiber, and fresh fruit for a nutritious start.": "这份餐食含有蛋白质、膳食纤维和新鲜水果，整体搭配较均衡。",
        "Ensure hydration with water or milk.": "注意补充水分，可以选择水或牛奶。",
        "Check portion sizes for the bread and avocado based on child's age.": "根据孩子年龄确认面包和牛油果的份量。",
        "Cut fruit and toast into smaller pieces if needed for easier handling.": "如有需要，可将水果和吐司切成小块，方便拿取和进食。",
        "Monitor for any egg or dairy allergies.": "留意是否有鸡蛋或乳制品过敏。",
        "Estimations made with typical serving sizes: 2 scrambled eggs, 2 slices whole wheat toast, 1/4 avocado, about 1/4 cup each of strawberries and blueberries, plus 1/2 cup yogurt with honey and blueberries.": "估算使用常见份量：2 个炒蛋、2 片全麦吐司、1/4 个牛油果、草莓和蓝莓各约 1/4 杯，以及 1/2 杯加蜂蜜和蓝莓的酸奶。",
        "Nutrient values can vary by ingredient brand and preparation method.": "营养数值会因食材品牌和制作方式而有所不同。",
        "Sugar content includes natural fruit sugars and honey from yogurt.": "糖含量包括水果中的天然糖分，以及酸奶中的蜂蜜。"
    ]

    return localizedAppString(trimmed) == trimmed ? translations[trimmed] ?? trimmed : localizedAppString(trimmed)
}
