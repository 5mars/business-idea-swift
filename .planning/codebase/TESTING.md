# Testing Patterns

**Analysis Date:** 2026-03-17

## Test Framework

**Status:** No test files detected in codebase

**Notes:**
- No `.xctest` bundle or test target found
- No test files (`*Tests.swift`, `*Test.swift`, `*.test.swift`) exist
- No testing framework configuration (XCTest, Quick, Nimble, etc.)
- Xcode project structure includes test-capable targets but none are populated

## Build System

**Tool:** Xcode / iOS App
- Build configuration: `/Users/mi/Desktop/Swift/abimo/Abimo.xcodeproj/project.pbxproj`
- Single active target: `Abimo` (iOS app)

## Test Infrastructure - Recommended Setup

**Recommended Testing Framework:**
- XCTest (Apple's native testing framework) - already included with Xcode
- Included in iOS project by default; no additional dependencies needed

**Testing Approach for Swift iOS:**
- Unit Tests: Test Models, ViewModels, Services in isolation
- Integration Tests: Test SupabaseService interactions
- UI Tests: Test View behavior with XCUITest

## Testable Areas

**Unit Testing Priority:**

**Services (`Abimo/Services/`):**
- `SupabaseService.swift`: Database operations, auth flows, file uploads
  - Methods: `signUp()`, `signIn()`, `fetchVoiceNotes()`, `uploadAudioFile()`, `toggleMicroAction()`
  - Currently: No mocking framework in place; direct Supabase client calls
  - Testing approach: Mock `SupabaseClient` for unit tests

- `AIAnalysisService.swift`: AI analysis and action plan generation
  - Methods: `analyzeTranscription()`, `generateAndSaveActionPlan()`
  - Testing approach: Mock edge function responses

- `AudioRecordingService.swift`: Audio recording and metrics
  - Methods: `startRecording()`, `stopRecording()`, `formatDuration()`
  - Testing approach: Mock AVAudioRecorder

**ViewModels (`Abimo/ViewModels/`):**
- `AuthViewModel.swift`: Authentication state management
  - Properties: `isAuthenticated`, `currentUser`, `errorMessage`
  - Methods: `signUp()`, `signIn()`, `signOut()`
  - Testing approach: Mock SupabaseService

- `ActionPlanViewModel.swift`: Action plan generation and micro-action tracking
  - Properties: `actionPlan`, `microActions`, `activeCommitment`, `nudges`
  - Methods: `generateActionPlan()`, `toggleMicroAction()`, `commitMicroAction()`
  - Testing approach: Mock AIAnalysisService and SupabaseService

**Models (`Abimo/Models/`):**
- All models are simple `Codable` structs
- Testing approach: Verify `Codable` conformance with JSON encoding/decoding

**Utilities (`Abimo/Utilities/`):**
- `PermissionsManager.swift`: Permission checking
  - Methods: `requestMicrophonePermission()`, `requestSpeechRecognitionPermission()`
  - Testing approach: Mock AVAudioSession and SFSpeechRecognizer

## Error Handling & Testing

**Current Error Patterns:**
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

**Test Cases for Error Handling:**
1. Successful authentication → `isAuthenticated = true`, `errorMessage = nil`
2. Failed authentication → `isAuthenticated = false`, `errorMessage` populated
3. Network error → Graceful error message display
4. Loading state → `isLoading` toggles correctly with `defer`

## Async Testing Pattern

**Current Pattern in Code:**
```swift
func generateActionPlan(analysis: SWOTAnalysis, transcriptionText: String) async {
    isGenerating = true
    errorMessage = nil
    defer { isGenerating = false }

    do {
        let (plan, actions) = try await aiService.generateAndSaveActionPlan(...)
        actionPlan = plan
        microActions = actions
    } catch {
        errorMessage = "Failed to generate action plan: \(error.localizedDescription)"
    }
}
```

**XCTest Async Testing Approach:**
```swift
func testGenerateActionPlan() async throws {
    let viewModel = ActionPlanViewModel()
    let mockAnalysis = SWOTAnalysis(...)

    await viewModel.generateActionPlan(analysis: mockAnalysis, transcriptionText: "test")

    XCTAssertNotNil(viewModel.actionPlan)
    XCTAssertFalse(viewModel.isGenerating)
}
```

## Mocking Strategy

**Current State:** No mocking framework imported; all services use real Supabase client

**Recommended Mocking:**

**Manual Protocol-Based Mocking:**
```swift
protocol SupabaseServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
    func getCurrentUser() async throws -> User?
}

class MockSupabaseService: SupabaseServiceProtocol {
    var shouldFail = false

    func signIn(email: String, password: String) async throws -> User {
        if shouldFail {
            throw NSError(domain: "Mock", code: 1)
        }
        return User(id: UUID(), email: email, createdAt: Date())
    }
}
```

**Recommended Mocking Frameworks (Optional):**
- `Mockito` or custom protocols for dependency injection
- Avoid heavyweight mocking in Swift; prefer protocol-based mocks

## Data Management in Tests

**Test Data Patterns Observed in Models:**

**User Model:**
```swift
struct User: Identifiable, Codable {
    let id: UUID
    let email: String?
    let createdAt: Date
}
```

**Test Fixture Example:**
```swift
extension User {
    static func mock(
        id: UUID = UUID(),
        email: String = "test@example.com",
        createdAt: Date = Date()
    ) -> User {
        User(id: id, email: email, createdAt: createdAt)
    }
}
```

**ActionPlan Model with CodingKeys Mapping:**
```swift
struct ActionPlan: Identifiable, Codable {
    let id: UUID
    let analysisId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case analysisId = "analysis_id"
    }
}
```

**Test Fixture with Codable Testing:**
```swift
func testActionPlanCodable() throws {
    let original = ActionPlan(id: UUID(), analysisId: UUID(), ...)
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(ActionPlan.self, from: encoded)
    XCTAssertEqual(original.id, decoded.id)
}
```

## MainActor and Concurrency Testing

**Concurrency Pattern in ViewModels:**
```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
}
```

**Testing Async MainActor Code:**
```swift
@MainActor
class TestAuthViewModel {
    func testAuthenticationUpdate() async {
        let viewModel = AuthViewModel()
        XCTAssertFalse(viewModel.isAuthenticated)

        await viewModel.signIn(email: "test@example.com", password: "password")
        // Runs on MainActor automatically
        XCTAssertTrue(viewModel.isAuthenticated)
    }
}
```

## Network Testing

**Services Making Network Calls:**
- `SupabaseService` → All database/auth/storage operations
- `AIAnalysisService` → Edge function calls

**Testing Approach:**
1. Mock SupabaseClient for unit tests
2. Use real Supabase test instance for integration tests
3. Mock edge function responses in AIAnalysisService tests

**Example Pattern:**
```swift
class MockSupabaseClient {
    var auth: MockAuth
    var storage: MockStorage
    var functions: MockFunctions
}

class AIAnalysisServiceTests: XCTestCase {
    let mockService = MockSupabaseService()
    let aiService = AIAnalysisService()

    func testAnalyzeTranscription() async throws {
        let response = try await aiService.analyzeTranscription("test text")
        XCTAssertNotNil(response)
    }
}
```

## Testing Permissions

**PermissionsManager (`Abimo/Utilities/PermissionsManager.swift`):**

**Methods to Test:**
- `checkPermissions()` - Verifies microphone and speech recognition status
- `requestMicrophonePermission()` - Returns Bool indicating grant
- `requestSpeechRecognitionPermission()` - Returns Bool indicating authorization
- `requestAllPermissions()` - Both permissions must be granted

**Mocking Approach:**
```swift
class MockAVAudioSession {
    var recordPermission: AVAudioSession.RecordPermission = .undetermined
}

class PermissionsManagerTests: XCTestCase {
    func testMicrophonePermissionCheck() async {
        let manager = PermissionsManager()
        let granted = await manager.requestMicrophonePermission()
        XCTAssertFalse(granted) // Or true based on mock state
    }
}
```

## UI Testing Considerations

**SwiftUI Views with ViewModels:**
- Views inject ViewModels via `@StateObject` or `@EnvironmentObject`
- UI tests should verify View renders correctly based on ViewModel state

**Preview Testing:**
- `#Preview` macro available in iOS 17+ for SwiftUI preview testing
- Current previews not explicitly defined in source files but can be added

**Example UI Test Structure:**
```swift
class AuthViewUITests: XCTestCase {
    let app = XCUIApplication()

    func testLoginViewPresentation() {
        app.launch()
        XCTAssertTrue(app.otherElements["login-view"].exists)
    }
}
```

## Coverage Recommendations

**Current Coverage:** 0% (no tests present)

**Priority Testing Areas (High → Low):**
1. **High:** AuthViewModel authentication flows
2. **High:** SupabaseService database operations
3. **Medium:** ActionPlanViewModel state management
4. **Medium:** AIAnalysisService integration
5. **Low:** AudioRecordingService (hardware-dependent)

**Target Coverage:** 70%+ for business logic (ViewModels/Services)

## Testing Setup Steps for Future

1. Create `AbimoTests` target in Xcode
2. Add `SupabaseTests` target (optional, for integration tests)
3. Implement protocol-based mocking for SupabaseService
4. Write unit tests for ViewModels
5. Add UI tests for navigation flows

---

*Testing analysis: 2026-03-17*
