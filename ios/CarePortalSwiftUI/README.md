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
- `Info.plist`: local-development HTTP permission for the backend.

## Backend

The app is pointed at:

```text
http://127.0.0.1:3002
```

That matches this project's Express backend when it is running with:

```bash
npm run server
```

For a real iPhone device, replace the API base URL in `AuthAPI.swift` with the Mac's local network IP address, such as:

```swift
URL(string: "http://192.168.1.20:3002")
```

## Xcode

Open `CarePortalSwiftUI.xcodeproj` in Xcode, choose an iPhone simulator, then press Run.

Use the included `Info.plist` as the app target's Info file if Xcode blocks local HTTP requests.
