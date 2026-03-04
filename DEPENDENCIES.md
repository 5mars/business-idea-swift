# Project Dependencies

## Swift Package Manager

This project uses Swift Package Manager for dependency management.

### Required Packages

#### Supabase Swift SDK
- **Repository**: https://github.com/supabase/supabase-swift
- **Version**: 2.x (latest)
- **Purpose**: Backend services (Auth, Database, Storage, Functions)

**Includes:**
- `Supabase` - Main client library
- `Auth` - Authentication
- `PostgREST` - Database operations
- `Storage` - File storage
- `Functions` - Edge Functions
- `Realtime` - Real-time subscriptions (not used yet)

### Installation

#### Via Xcode (Recommended)
1. Open `note-ai-app-test.xcodeproj`
2. Go to File > Add Package Dependencies...
3. Enter URL: `https://github.com/supabase/supabase-swift`
4. Select "Up to Next Major Version" with version 2.0.0
5. Click "Add Package"
6. Select all Supabase products
7. Click "Add Package"

#### Via Package.swift (if using SPM directly)
```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
],
targets: [
    .target(
        name: "note-ai-app-test",
        dependencies: [
            .product(name: "Supabase", package: "supabase-swift")
        ]
    )
]
```

### Platform Requirements

- **iOS**: 17.0+
- **macOS**: 10.15+ (if building for Mac)
- **Swift**: 6.0+

### What Each Package Does

#### Supabase
The main client that ties everything together. Used in `SupabaseService.swift`:
```swift
let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
```

#### Auth
Handles authentication. Used for:
- Sign up with email/password
- Sign in
- Sign out
- Session management
- Token refresh

#### PostgREST
Database operations. Used for:
- Insert (creating records)
- Select (fetching records)
- Update (modifying records)
- Delete (removing records)
- Row Level Security

#### Storage
File storage. Used for:
- Uploading audio files
- Getting public URLs
- Deleting files
- Managing private buckets

#### Functions
Edge Functions. Used for:
- Calling `analyze-swot` function
- Passing data to OpenAI API securely
- Receiving SWOT analysis results

---

## No Other Dependencies Required!

Unlike many iOS projects, this app keeps dependencies minimal:
- ✅ **Only 1 external dependency** (Supabase)
- ✅ Uses native frameworks (AVFoundation, Speech, SwiftUI)
- ✅ No CocoaPods required
- ✅ No Carthage required
- ✅ Clean Swift Package Manager setup

---

## Native iOS Frameworks Used

These are built into iOS (no installation needed):

### AVFoundation
- Audio recording (`AVAudioRecorder`)
- Audio session management (`AVAudioSession`)
- Audio file properties (`AVURLAsset`)

### Speech
- Speech recognition (`SFSpeechRecognizer`)
- Speech analysis (`SpeechAnalyzer` on iOS 26+)
- Transcription (`TranscriberModule`)

### SwiftUI
- Declarative UI framework
- All views use SwiftUI
- Native iOS design language

### Foundation
- Core data types (String, Date, UUID, etc.)
- File management (`FileManager`)
- Networking (`URLSession` - used by Supabase internally)

### Combine
- Reactive programming
- `@Published` properties in ViewModels
- Data binding between ViewModels and Views

---

## Version Compatibility

### Minimum Versions
| Requirement | Version |
|-------------|---------|
| iOS | 17.0+ |
| Xcode | 16.0+ |
| Swift | 6.0 |
| Supabase Swift | 2.0.0+ |

### Recommended Versions
| Requirement | Version | Reason |
|-------------|---------|---------|
| iOS | 26.0+ | Best transcription (SpeechAnalyzer) |
| Xcode | Latest | Latest Swift features |
| Supabase Swift | Latest 2.x | Bug fixes & improvements |

---

## Dependency Graph

```
note-ai-app-test
└── Supabase (2.x)
    ├── Auth
    ├── PostgREST
    ├── Storage
    ├── Functions
    └── Realtime (not used)
```

---

## Future Dependencies (Potential)

If extending the app, you might add:

### Audio Playback Visualization
- `AVAudioPlayer` (built-in)
- Or custom waveform library

### PDF Export
- `PDFKit` (built-in)
- Or third-party PDF generation

### Local Database (Offline Support)
- Core Data (built-in)
- SwiftData (built-in, iOS 17+)
- Or Realm Swift

### Enhanced Analytics
- Firebase Analytics
- Mixpanel
- Amplitude

---

## Troubleshooting

### "No such module 'Supabase'"
**Solution**: Add Supabase package via Xcode > File > Add Package Dependencies

### Package resolution takes too long
**Solution**:
- Check internet connection
- Clear package cache: File > Packages > Reset Package Caches
- Try again

### Build errors after adding package
**Solution**:
- Clean build folder: Product > Clean Build Folder (⇧⌘K)
- Restart Xcode
- Rebuild

### Package conflicts
**Solution**:
- Remove and re-add the package
- Make sure you're using version 2.x of Supabase Swift

---

## Keeping Dependencies Updated

### Check for Updates
1. In Xcode, go to File > Packages > Update to Latest Package Versions
2. Review changes in package versions
3. Test thoroughly after updating

### Version Pinning
For production apps, consider pinning to specific versions:
- File > Packages > Resolve Package Versions
- Commit `Package.resolved` to version control

---

## License Information

### Supabase Swift
- **License**: MIT
- **Repository**: https://github.com/supabase/supabase-swift
- **Maintainer**: Supabase (official)

### Your App
You own all the code in this project and can license it however you want!

---

## Support & Documentation

### Supabase Swift Docs
- Official docs: https://supabase.com/docs/reference/swift
- GitHub: https://github.com/supabase/supabase-swift
- Issues: https://github.com/supabase/supabase-swift/issues

### Swift Package Manager
- Official docs: https://swift.org/package-manager/
- Apple docs: https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app

---

## Summary

✅ **Minimal dependencies** (just 1 package)
✅ **Official Supabase SDK** (well-maintained)
✅ **Native iOS frameworks** (battle-tested)
✅ **Swift Package Manager** (modern, clean)
✅ **No complex setup** (just add the package)

You're ready to go! 🚀
