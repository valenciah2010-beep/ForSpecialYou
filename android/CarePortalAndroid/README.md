# Care Portal Android

Native Android version of the existing `ios/CarePortalSwiftUI` app.

## Open in Android Studio

1. Open Android Studio.
2. Choose **Open**.
3. Select this folder:

   ```text
   android/CarePortalAndroid
   ```

4. Let Android Studio sync Gradle, then run the `app` configuration.

## Backend URL

The debug build uses:

```text
http://10.0.2.2:4223
```

`10.0.2.2` is the Android Emulator address for the Mac host machine. Start the existing Node backend from the project root before testing login, sign-up, meal analysis, or sync:

```bash
npm run server
```

For a physical Android device, change `API_BASE_URL` in `app/build.gradle` to a reachable LAN or HTTPS backend URL.

Release builds use:

```text
https://fsyadmin.top
```

## Ported Surface

- Auth home, language switching, login, sign-up, terms sheet, saved-session validation, and login captcha after repeated failed attempts.
- Parent app bottom tabs matching the iOS app: Diagnosis, Health, Therapy, Nutrient, Profile.
- Local storage keys are aligned with the iOS `@AppStorage` keys where practical.
- Parent profile, health logs, nutrient usage, saved meals, and backend sync use the same API routes as iOS.
- iOS visual assets copied into Android resources: logo, Bristol chart, and pain body image.
