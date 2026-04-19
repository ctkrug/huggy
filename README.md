# Huggy - iOS App Setup Checklist

## 1. Create Xcode Project
1. Open Xcode → File → New → Project → iOS → App
2. Product Name: **Huggy**
3. Bundle Identifier: **com.charliekrug.huggy**
4. Interface: **SwiftUI**, Language: **Swift**
5. Minimum deployment: **iOS 16.0**
6. Delete the auto-generated ContentView.swift and HuggyApp.swift
7. Drag all files from `Huggy/` folder into the Xcode project navigator

## 2. Add Swift Package Dependencies
Go to File → Add Package Dependencies and add:

1. **Firebase iOS SDK**
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Add these products: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseMessaging`

2. **Lottie** (included in spec but not used in MVP — skip for now)
   - URL: `https://github.com/airbnb/lottie-spm`

## 3. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Open your project (App ID: `1:181399427000:ios:0034cbd88cb79b9271614d`)
3. Download `GoogleService-Info.plist`
4. Drag it into the Xcode project root (make sure "Copy items if needed" is checked)

## 4. Firebase Authentication
1. In Firebase Console → Authentication → Sign-in method
2. Enable **Email/Password**
3. Enable **Apple** (requires Apple Developer account setup — see below)

## 5. Apple Sign In Setup
1. In Apple Developer → Certificates, Identifiers & Profiles → Identifiers
2. Select your App ID → enable "Sign In with Apple"
3. In Xcode → Signing & Capabilities → + Capability → "Sign in with Apple"

## 6. Firebase Dynamic Links (for Pairing)
1. In Firebase Console → Dynamic Links
2. Set up domain: **huggy.page.link**
3. In Xcode → Signing & Capabilities → + Capability → "Associated Domains"
4. Add: `applinks:huggy.page.link`

## 7. Push Notifications
1. In Apple Developer → Keys → Create a new key with "Apple Push Notifications service (APNs)"
2. Download the .p8 key file
3. In Firebase Console → Project Settings → Cloud Messaging
4. Upload the APNs auth key (.p8 file)
5. In Xcode → Signing & Capabilities → + Capability → "Push Notifications"
6. Also add "Background Modes" capability and check "Remote notifications"

## 8. Firestore Setup
1. In Firebase Console → Firestore Database → Create database
2. Start in **test mode** for development
3. Create these Firestore indexes (or let them auto-create on first query):
   - Collection `hugs`: composite index on `coupleId` (ASC) + `sentAt` (DESC)

## 9. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

## 10. Info.plist
The provided Info.plist includes all required keys:
- `CFBundleURLTypes` with `huggy` scheme
- `LSApplicationQueriesSchemes` with `huggy`
- `FirebaseMessagingAutoInitEnabled`
- `UIBackgroundModes` with `remote-notification`

## 11. Build & Run
1. Select your iPhone or simulator
2. Build (Cmd+B) to verify no compile errors
3. Run (Cmd+R)

## File Structure
```
Huggy/
├── HuggyApp.swift           # App entry point + deep link handling
├── ContentView.swift         # Root navigation logic
├── Info.plist               # App configuration
├── Views/
│   ├── OnboardingView.swift
│   ├── AuthView.swift
│   ├── PairingView.swift
│   ├── HomeView.swift
│   ├── SendHugView.swift
│   ├── ReceiveHugView.swift
│   ├── HugHistoryView.swift
│   └── SettingsView.swift
├── Components/
│   ├── HugCharacterView.swift  # Animated SwiftUI character
│   ├── HugTypeCard.swift
│   ├── StreakBadge.swift
│   └── ConfettiView.swift
├── Models/
│   ├── UserModel.swift
│   ├── CoupleModel.swift
│   └── HugModel.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   └── HugViewModel.swift
└── Services/
    ├── FirebaseService.swift
    └── NotificationService.swift

functions/
├── index.js                 # Cloud Functions (onHugCreated, onHugRequested)
└── package.json
```
