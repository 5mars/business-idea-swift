# Technology Stack

**Analysis Date:** 2026-03-17

## Languages

**Primary:**
- Swift 5.0 - iOS/macOS app implementation, all business logic and UI
- TypeScript - Supabase Edge Functions for AI analysis and action plan generation

**Secondary:**
- XML (Plist) - Configuration and permissions
- CSS/HTML - None used; pure native Swift approach

## Runtime

**Environment:**
- iOS 26.2+ (deployment target)
- macOS 26.2+ (secondary target via universal app configuration)
- Xcode 16+ (build environment)

**Package Manager:**
- Swift Package Manager (SPM) - Integrated with Xcode
- Lockfile: Not detected (Xcode manages resolved dependencies)

## Frameworks

**Core UI & Application:**
- SwiftUI 4.0 - Modern declarative UI framework for all views
- AVFoundation - Audio recording, session management, metering
- Speech Framework - On-device speech recognition/transcription

**State & Lifecycle:**
- Combine - Reactive data binding via @Published properties
- Async/await - Structured concurrency for network calls and async operations

**Testing:**
- Not detected - Manual testing checklist only (see README.md)

**Build/Dev:**
- Xcode 16 - IDE and build system
- Swift Package Manager - Dependency resolution

## Key Dependencies

**Critical:**
- Supabase Swift SDK 2.x (`import Supabase`) - Backend authentication, database operations, file storage, and Edge Function invocation
  - Location: `Abimo/Services/SupabaseService.swift`
  - Used for: Auth (email/password), data persistence (PostgreSQL), file uploads, signed URLs, function calls

**Infrastructure:**
- Deno 1.x (runtime for Supabase Edge Functions) - Server-side execution of AI analysis
- OpenAI GPT-4o API - Via Edge Functions for SWOT analysis and action plan generation

## Configuration

**Environment:**
- Supabase credentials hardcoded in `Abimo/Services/SupabaseService.swift` (lines 17-24)
  - `supabaseURL`: Hardcoded to `https://ymbfqlrarlnqtzatgfah.supabase.co`
  - `supabaseAnonKey`: Hardcoded publishable key
  - **Note:** Uses `TODO` comment - intended to be replaced with actual credentials

**Build:**
- `Abimo.xcodeproj/project.pbxproj` - Xcode project configuration
- `Abimo/Info.plist` - App permissions and URL schemes
  - Microphone permission required
  - Speech recognition permission required
  - Deep link scheme: `noteai://`

**Important Permissions (Info.plist):**
- `NSMicrophoneUsageDescription` - Required for voice recording
- `NSSpeechRecognitionUsageDescription` - Required for transcription

## Platform Requirements

**Development:**
- macOS 14+ (Sonoma) - Xcode host OS
- Xcode 16+
- Swift 6.0+ language version support
- Physical iOS device or simulator with iOS 26.2+
- Minimum 4GB RAM for Xcode compilation

**Production:**
- Deployment target: iOS 26.2+
- Supported devices: iPhone, iPad, Mac (universal app)
- Network: Active internet connection for Supabase and OpenAI API calls
- Microphone: Required hardware on device
- Storage: ~50MB app size + user audio files

## Framework Architecture

**Pattern:** MVVM (Model-View-ViewModel)

**Layers:**
1. **Views** (`Abimo/Views/`) - SwiftUI components using @State, @StateObject
2. **ViewModels** (`Abimo/ViewModels/`) - @MainActor classes with @Published properties
3. **Services** (`Abimo/Services/`) - Singleton services for external integrations
4. **Models** (`Abimo/Models/`) - Codable structs for data serialization
5. **Utilities** (`Abimo/Utilities/`) - Helper classes (permissions, file management)

**Concurrency Model:**
- Swift async/await throughout
- @MainActor for UI updates
- Structured concurrency with Task scopes

## Code Organization

**Entry Point:**
- `Abimo/AbimoApp.swift` - SwiftUI App protocol entry point
- `Abimo/ContentView.swift` - Root view composition

**Service Singletons:**
- `SupabaseService.shared` - Manages all backend operations
- `AIAnalysisService` - Wraps Supabase function calls for AI features
- `TranscriptionService` - Handles both local and Whisper transcription
- `AudioRecordingService` - AVFoundation wrapper for recording

---

*Stack analysis: 2026-03-17*
