import Foundation

enum APIConfig {
    #if DEBUG
    static let baseURL = URL(string: "http://127.0.0.1:3002")
    #else
    static let baseURL = URL(string: "https://fsyadmin.top")
    #endif
}
