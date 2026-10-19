# CarePortalSwiftUI

Native SwiftUI care app with authentication, diagnosis, health tracking, therapy, nutrition, and parent profiles.

## Files

- `CarePortalSwiftUIApp.swift`: app entry point.
- `AuthRootView.swift`: switches between login, sign-up, and welcome screens.
- `LoginView.swift`: login form.
- `SignupView.swift`: sign-up form with account type picker.
- `WelcomeView.swift`: signed-in tab container; feature views live under `Features/`.
- `AuthViewModel.swift`: form state, validation, and actions.
- `AuthAPI.swift`: typed API models and endpoints.
- `APITransport.swift`: authenticated requests, AI consent, and resumable image uploads.
- `SessionStore.swift`: device-only Keychain session storage.
- `Models.swift`: request, response, user, and role models.
- `AuthComponents.swift`: shared fields, buttons, message banner, and colors.
- `APIConfig.swift`: backend API base URL.
- `Info.plist`: local-development HTTP permission for optional local backend testing.

## Backend

The app is pointed at:

```text
Debug: http://127.0.0.1:4223
Release: https://fsyadmin.top
```

Debug builds use the local Koa backend for development. Release builds use the deployed Koa backend.

For real-device local testing, change the Debug URL in `APIConfig.swift` to the Mac's LAN IP address, such as:

```swift
URL(string: "http://192.168.1.20:4223")
```

## Xcode

Open `CarePortalSwiftUI.xcodeproj` in Xcode, choose an iPhone simulator, then press Run.

Use the included `Info.plist` as the app target's Info file if Xcode blocks local HTTP requests.
