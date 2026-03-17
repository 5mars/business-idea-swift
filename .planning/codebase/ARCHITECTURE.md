# Architecture

**Analysis Date:** 2026-03-17

## Pattern Overview

**Overall:** MVVM + Service Layer with Backend Integration

**Key Characteristics:**
- SwiftUI view layer with state-driven UI updates
- ViewModels as single source of truth for view state
- Service layer abstracts external APIs and local operations
- Async/await throughout for non-blocking operations
- Data flows unidirectionally: Services → ViewModels → Views

## Layers

**Presentation (Views):**
- Purpose: Render UI, handle user interactions, delegate logic to ViewModels
- Location: `Abimo/Views/`, `Abimo/ContentView.swift`, `Abimo/AbimoApp.swift`
- Contains: SwiftUI views organized by feature (Auth, Recording, Notes, ActionPlan, Analysis)
- Depends on: ViewModels (injected via @StateObject/@EnvironmentObject), Models (display data)
- Used by: SwiftUI framework, root app

**Presentation State (ViewModels):**
- Purpose: Manage feature-specific state, coordinate business logic, update views reactively
- Location: `Abimo/ViewModels/`
- Contains: @MainActor classes conforming to ObservableObject with @Published properties
- Depends on: Services (SupabaseService, AIAnalysisService, AudioRecordingService, TranscriptionService)
- Used by: Views for state and action handling

**Models:**
- Purpose: Data structures mirroring database schema and API contracts
- Location: `Abimo/Models/`
- Contains: Codable structs with CodingKeys for snake_case database columns
- Depends on: Foundation (Date, UUID, Codable)
- Used by: Services (store/retrieve), ViewModels (pass to Services, display), Views (render)

**Business Logic & Integration (Services):**
- Purpose: Handle external API calls, file I/O, authentication, transcription, analysis, database ops
- Location: `Abimo/Services/`
- Contains: Singleton/static instances (SupabaseService.shared), async functions
- Depends on: Supabase SDK, AVFoundation, Speech Recognition, Foundation
- Used by: ViewModels exclusively

**Utilities:**
- Purpose: Reusable helpers for file operations and system permissions
- Location: `Abimo/Utilities/`
- Contains: `AudioFileManager` (file I/O), `PermissionsManager` (mic/speech permissions)
- Depends on: Foundation, AVFoundation, Speech frameworks
- Used by: ViewModels and Services

## Data Flow

**Recording & Persistence:**

1. RecordingView calls `RecordingViewModel.startRecording()`
2. ViewModel uses AudioRecordingService to capture audio locally
3. User saves recording → ViewModel calls `RecordingViewModel.saveRecording(title:)`
4. ViewModel uploads file to Supabase Storage, creates VoiceNote in database
5. SupabaseService handles upload and database insert
6. VoiceNote returned to ViewModel, file cleaned up locally

**Transcription & Analysis:**

1. NotesListView displays cached notes, selects one for detail
2. NoteDetailView shows transcription if exists, else "Generate" button
3. On tap, triggers TranscriptionService to transcribe audio file
4. Audio file downloaded from storage, processed locally via SFSpeechRecognizer
5. Transcription saved to database via SupabaseService
6. User taps "Analyze" → AnalysisViewModel calls AIAnalysisService
7. AIAnalysisService invokes Supabase Edge Function (analyze-swot)
8. Returns SWOTAnalysisResponse, service persists SWOTAnalysis to database
9. Analysis displayed in SWOTAnalysisView

**Action Plan Generation & Execution:**

1. SWOTAnalysisView shows analysis, has "Create Plan" button
2. Taps button → ActionPlanViewModel.generateActionPlan()
3. ViewModel invokes AIAnalysisService which calls Edge Function (generate-action-plan)
4. Edge Function returns ActionPlanResponse (plan metadata + micro-actions)
5. Service creates ActionPlan record and MicroAction array, persists both
6. ViewModel displays plan with commitment picker
7. User commits to action → ActionPlanViewModel.commitToAction()
8. Creates Commitment record, sets active commitment
9. User marks actions complete → toggleMicroAction() updates isCompleted, calls Service
10. Service computes nudges locally (inactivity, commitment due, milestones)

**State Management:**

- AuthViewModel holds authentication state, persisted by Supabase session
- RecordingViewModel manages recording UI state during capture
- AnalysisViewModel holds SWOT analysis for current transcription
- ActionPlanViewModel holds plan, micro-actions, active commitment, nudges
- ActionsTabViewModel aggregates all plans/actions across user's history
- No shared mutable state; ViewModels are unidirectional data sources

## Key Abstractions

**SupabaseService:**
- Purpose: Centralized database and storage client
- Examples: `Abimo/Services/SupabaseService.swift`
- Pattern: Singleton (SupabaseService.shared), async methods wrapping Supabase SDK calls
- Responsibilities: Auth, CRUD operations on all tables, file upload/download/signed URLs

**AudioRecordingService:**
- Purpose: Encapsulate AVAudioRecorder mechanics
- Examples: `Abimo/Services/AudioRecordingService.swift`
- Pattern: @MainActor ObservableObject with @Published duration/audioLevel
- Responsibilities: Start/stop/cancel recording, metering, timer management

**TranscriptionService:**
- Purpose: Wrap SFSpeechRecognizer and Whisper Edge Function
- Examples: `Abimo/Services/TranscriptionService.swift`
- Pattern: @MainActor ObservableObject, async transcription methods
- Responsibilities: Local speech recognition, progress reporting

**AIAnalysisService:**
- Purpose: Invoke Supabase Edge Functions for SWOT and Action Plan generation
- Examples: `Abimo/Services/AIAnalysisService.swift`
- Pattern: @MainActor ObservableObject, methods that generate and save models
- Responsibilities: Call Edge Functions, construct model objects, persist to database

**AuthViewModel:**
- Purpose: Gate access to app based on authentication state
- Examples: `Abimo/ViewModels/AuthViewModel.swift`
- Pattern: @MainActor ObservableObject, listens to Supabase auth changes
- Responsibilities: Sign up/in/out, session management, user state

**ActionPlanViewModel:**
- Purpose: Coordinate action plan lifecycle and nudge computation
- Examples: `Abimo/ViewModels/ActionPlanViewModel.swift`
- Pattern: @MainActor ObservableObject, exposes plan/actions/nudges
- Responsibilities: Load/generate plans, toggle actions, manage commitments, compute nudges locally

## Entry Points

**App Launch:**
- Location: `Abimo/AbimoApp.swift`
- Triggers: SwiftUI app lifecycle
- Responsibilities: Instantiate RootView, configure auth URL handling for deep links

**Root Navigation:**
- Location: `Abimo/Views/RootView.swift`
- Triggers: App launch
- Responsibilities: Show LoadingView (auth check), LoginView (not authenticated), MainTabView (authenticated)

**Main Tab Navigation:**
- Location: `Abimo/Views/RootView.swift` (MainTabView struct)
- Triggers: Authentication success
- Responsibilities: Host 4-tab interface (Notes, Record, Actions, Profile)

**Feature Entry Points:**
- Recording: `Abimo/Views/Recording/RecordingView.swift` - Tab entry
- Notes: `Abimo/Views/Notes/NotesListView.swift` - Tab entry, navigates to detail
- Actions: `Abimo/Views/ActionPlan/ActionsTabView.swift` - Tab entry, aggregates all plans
- Analysis: `Abimo/Views/Analysis/SWOTAnalysisView.swift` - Pushed from note detail

## Error Handling

**Strategy:** Try-catch in async methods, display to user via ViewModel.errorMessage

**Patterns:**
- ViewModels wrap Service calls in try-catch, set errorMessage on failure
- UI displays errorMessage in red text
- Some failures degrade gracefully (e.g., nudge computation silent failures)
- Auth errors trigger state transition back to LoginView via AuthViewModel

**Example:**
```swift
func generateAnalysis(transcription: Transcription) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
        analysis = try await aiService.generateAndSaveSWOTAnalysis(...)
    } catch {
        errorMessage = "Failed to generate analysis: \(error.localizedDescription)"
    }
}
```

## Cross-Cutting Concerns

**Logging:** Minimal; print() used in catch blocks for debugging (not persisted)

**Validation:**
- VoiceNote title defaults to "Untitled Recording" if empty
- Recording duration must be determinable before save
- Action plan generation requires valid transcription text and viability score

**Authentication:**
- All database operations require current user ID from SupabaseService.getCurrentUser()
- Auth state persisted by Supabase; app checks on launch
- Deep link handling for OAuth/email confirmation in AbimoApp

**Permissions:**
- Microphone and speech recognition requested via PermissionsManager before recording
- Checked each time recording starts (cached after first request)

---

*Architecture analysis: 2026-03-17*
