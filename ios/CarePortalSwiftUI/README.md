# CarePortalSwiftUI

Native SwiftUI login and sign-up screens for the Care Portal app.

## Files

- `CarePortalSwiftUIApp.swift`: app entry point.
- `AuthRootView.swift`: switches between login, sign-up, and welcome screens.
- `LoginView.swift`: login form.
- `SignupView.swift`: sign-up form with account type picker.
- `WelcomeView.swift`: signed-in confirmation screen.
- `AuthViewModel.swift`: form state, validation, and actions.
- `AuthAPI.swift`: `URLSession` client for the existing backend.
- `Models.swift`: request, response, user, and role models.
- `AuthComponents.swift`: shared fields, buttons, message banner, and colors.
- `APIConfig.swift`: backend API base URL.
- `Info.plist`: local-development HTTP permission for optional local backend testing.

## Backend

The app is pointed at:

```text
https://fsyadmin.top
```

That matches the deployed Koa backend for the admin/site API.

For local backend testing, temporarily change `APIConfig.swift` to your local or LAN backend URL, such as:

```swift
URL(string: "http://192.168.1.20:3002")
```

## Xcode

Open `CarePortalSwiftUI.xcodeproj` in Xcode, choose an iPhone simulator, then press Run.

Use the included `Info.plist` as the app target's Info file if Xcode blocks local HTTP requests.
