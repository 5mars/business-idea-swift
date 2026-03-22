# Coding Conventions

**Analysis Date:** 2026-03-17

## Naming Patterns

**Files:**
- PascalCase with `.swift` extension
- View files: `[ViewName]View.swift` (e.g., `LoginView.swift`, `RootView.swift`, `SWOTAnalysisView.swift`)
- ViewModel files: `[Name]ViewModel.swift` (e.g., `AuthViewModel.swift`, `ActionPlanViewModel.swift`)
- Service files: `[Name]Service.swift` (e.g., `SupabaseService.swift`, `AIAnalysisService.swift`)
- Utility files: `[Name]Manager.swift` or `[Name].swift` (e.g., `PermissionsManager.swift`, `AudioFileManager.swift`)
- Model files: `[ModelName].swift` (e.g., `User.swift`, `ActionPlan.swift`, `VoiceNote.swift`)

**Types (Structs, Classes, Enums):**
- PascalCase (e.g., `ActionPlan`, `MicroAction`, `Commitment`, `DeepLinkData`)
- Protocol names are PascalCase (e.g., `Identifiable`, `Codable`, `Hashable`)

**Functions and Methods:**
- camelCase (e.g., `startRecording()`, `stopRecording()`, `fetchVoiceNotes()`)
- Async functions use `async` keyword (e.g., `func generateActionPlan(analysis: SWOTAnalysis, transcriptionText: String) async`)
- Methods that throw use `throws` keyword (e.g., `func startRecording() throws -> URL`)

**Variables and Properties:**
- camelCase (e.g., `isRecording`, `recordingDuration`, `currentUser`, `errorMessage`)
- Published properties in ViewModels: camelCase with `@Published` attribute (e.g., `@Published var isLoading = false`)
- Private properties: camelCase with underscore prefix optional (e.g., `private let supabase`, `private var timer`)
- State properties in Views: camelCase with `@State` attribute (e.g., `@State private var showSignOutAlert = false`)

**Constants:**
- PascalCase for types: `UUID()`, `Date()`
- camelCase for static constants in extensions: `static let brand = Color(hex: "FF6B6B")`

**Enums:**
- PascalCase for enum names (e.g., `CodingKeys`)
- camelCase for enum cases (e.g., `.recordPermission`, `.granted`, `.denied`)

## Code Style

**Formatting:**
- No explicit linter configuration file detected; follows Apple Swift style conventions
- Line length: Appears to be ~100 characters typical
- Indentation: 4 spaces (standard Swift)
- Braces: Opening brace on same line (e.g., `func body: some View {`)

**Structure:**
- Methods and properties organized using `// MARK: -` comments for clear section separation
- Mark sections often describe functionality or computed properties (e.g., `// MARK: - Authentication`, `// MARK: - Toggle Micro Action`)

**SwiftUI Specific:**
- View bodies use standard SwiftUI syntax with `some View` return type
- Property wrappers (`@State`, `@Binding`, `@Published`, `@StateObject`, `@EnvironmentObject`) placed directly above property declaration
- `@MainActor` annotation applied to ViewModels and Services requiring UI updates
- Modifiers chained directly on View expressions

## Import Organization

**Order:**
1. Foundation (if needed)
2. SwiftUI
3. Third-party frameworks (e.g., `import Supabase`, `import Combine`)
4. Native iOS frameworks (e.g., `import AVFoundation`, `import Speech`)

**Example from `AuthViewModel.swift`:**
```swift
import Foundation
import SwiftUI
import Combine
import Supabase
```

**Path Aliases:**
- No path aliases detected; imports use full module names

## Error Handling

**Patterns:**
- `do-try-catch` blocks for async operations
- `throws` keyword on functions that can fail (e.g., `func signUp(email: String, password: String) async throws -> User`)
- Error messages stored in `@Published var errorMessage: String?` properties in ViewModels
- Graceful nil returns on failures (e.g., `func getCurrentUser() async throws -> User?`)
- `defer` blocks used to ensure cleanup (e.g., `defer { isLoading = false }`)
- Silent error handling with `try?` for non-critical operations (e.g., `try? await SupabaseService.shared.client.auth.handle(url)`)

**Error Handling in ViewModels:**
```swift
func signIn(email: String, password: String) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
        currentUser = try await supabase.signIn(email: email, password: password)
        isAuthenticated = true
    } catch {
        errorMessage = "Sign in failed: \(error.localizedDescription)"
    }
}
```

## Logging

**Framework:** `print()` with string interpolation

**Patterns:**
- Minimal logging in production code
- `print()` used only for errors (e.g., `print("Auth check error: \(error.localizedDescription)")`)
- No structured logging framework (Logger, OSLog) currently in use
- Error descriptions logged inline in catch blocks

**Example from `AuthViewModel.swift`:**
```swift
} catch {
    print("Auth check error: \(error.localizedDescription)")
    isAuthenticated = false
}
```

## Comments

**When to Comment:**
- MARK comments for major section headers
- Inline comments for complex logic (e.g., normalization math in `AudioRecordingService`)
- Comments on data flow decisions (e.g., "Return the file path, not a URL (we'll generate signed URLs when needed)")

**JSDoc/TSDoc:**
- Not used; Swift documentation comments not prevalent in this codebase

## Function Design

**Size:** Functions vary from 5 to 100+ lines; most service methods under 30 lines

**Parameters:**
- Explicit parameter names required in calls (Swift enforces this)
- Multiple parameters grouped logically (e.g., `email: String, password: String`)
- Optional parameters with default values (e.g., `expiresIn: Int = 3600`)

**Return Values:**
- Async functions return typed values directly (not wrapped in completions)
- Functions return `Void` or specific types (e.g., `-> URL`, `-> [VoiceNote]`)
- Throwable functions explicitly marked with `throws`

## Module Design

**Exports:**
- All types (structs, classes, enums) are implicitly public at module level
- Private initializers used for singletons (e.g., `private init()` in `SupabaseService`)
- Services use static `shared` property for singleton pattern

**Service Pattern - SupabaseService Singleton:**
```swift
class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient

    private init() {
        // Configuration
    }
}
```

**ViewModel Pattern - ObservableObject with @MainActor:**
```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let supabase = SupabaseService.shared
}
```

**View Pattern - Compositional Views with Modular Components:**
```swift
struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        ZStack {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
```

**Model Pattern - Codable with CodingKeys for Snake-Case Conversion:**
```swift
struct ActionPlan: Identifiable, Codable {
    let id: UUID
    let analysisId: UUID
    let title: String

    enum CodingKeys: String, CodingKey {
        case id
        case analysisId = "analysis_id"
        case title
    }
}
```

## Async/Await Patterns

**Prevalent throughout codebase (100+ async calls detected)**

**Patterns:**
- `async` functions for network/database operations
- `await` calls on async operations
- `Task { }` blocks for launching async work from sync contexts
- `Task { @MainActor in }` for updating UI from background operations
- `@MainActor` annotation on ViewModels to ensure UI updates on main thread

**Example from `AudioRecordingService`:**
```swift
levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
    guard let self = self else { return }
    Task { @MainActor in
        self.audioLevel = normalized
    }
}
```

## Memory Management

**Patterns:**
- `[weak self]` used in closures to avoid retain cycles (e.g., `Timer.scheduledTimer`)
- `guard let self = self else { return }` safety pattern
- No manual reference counting needed (ARC handles automatically)
- Private properties reset to `nil` on cleanup (e.g., `currentFileURL = nil`)

## Accessibility

**File Locations:**
- `Assets.xcassets` contains color, image, and icon assets
- Design system colors defined in `ContentView.swift` as `Color` extensions

**Design System Colors (`ContentView.swift`):**
- `Color.brand` (Coral red)
- `Color.brandLight`, `Color.brandPink`, `Color.brandAmber`
- `Color.appBg` (Warm rose cream)
- `Color.textPri`, `Color.textSec` (Text colors)

---

*Convention analysis: 2026-03-17*
