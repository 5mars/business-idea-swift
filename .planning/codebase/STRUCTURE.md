# Codebase Structure

**Analysis Date:** 2026-03-17

## Directory Layout

```
Abimo/
├── AbimoApp.swift           # App entry point, auth URL handling
├── ContentView.swift        # Design system: colors, gradients, components
├── RootView.swift           # Root navigation: auth state routing, MainTabView
├── Views/
│   ├── LoadingView.swift    # Splash/auth check screen
│   ├── Recording/
│   │   └── RecordingView.swift          # Mic recording UI, waveform visualization
│   ├── Notes/
│   │   ├── NotesListView.swift          # List of voice notes
│   │   └── NoteDetailView.swift         # Single note, transcription, analysis nav
│   ├── Auth/
│   │   ├── LoginView.swift              # Email/password sign in
│   │   └── SignUpView.swift             # Email/password registration
│   ├── Analysis/
│   │   └── SWOTAnalysisView.swift       # SWOT matrix display, plan generation
│   └── ActionPlan/
│       ├── ActionsTabView.swift         # Tab content: all plans + nudges
│       ├── ActionPlanDetailView.swift   # Single plan with micro-actions
│       ├── MicroActionRow.swift         # Checkbox + action text row
│       ├── CommitmentSheet.swift        # Modal to pick action & schedule
│       ├── CompletionReflectionSheet.swift # Modal for completion reflection
│       ├── MomentumDashboard.swift      # Streak + weekly activity display
│       └── NudgeBanner.swift            # Nudge message display
├── ViewModels/
│   ├── AuthViewModel.swift              # Auth state, sign up/in/out
│   ├── RecordingViewModel.swift         # Recording capture state, save logic
│   ├── NotesViewModel.swift             # Notes list state (not yet implemented)
│   ├── AnalysisViewModel.swift          # SWOT analysis state, generation
│   └── ActionPlanViewModel.swift        # Plan state, actions, nudges, commitments
│                                        # + ActionsTabViewModel (aggregates)
├── Models/
│   ├── User.swift                       # Auth user identity
│   ├── VoiceNote.swift                  # Recording metadata
│   ├── Transcription.swift              # Text + audio reference
│   ├── SWOTAnalysis.swift               # Analysis + rich metadata
│   ├── ActionPlan.swift                 # Plan metadata
│   │                                    # + MicroAction, Commitment, DeepLinkData
│   └── Nudge.swift                      # Nudge type enum + message struct
├── Services/
│   ├── SupabaseService.swift            # Database + storage client (singleton)
│   ├── AudioRecordingService.swift      # AVAudioRecorder wrapper
│   ├── AudioPlayerService.swift         # Audio playback (stubs only)
│   ├── TranscriptionService.swift       # SFSpeechRecognizer wrapper
│   └── AIAnalysisService.swift          # Edge Function calls + model creation
├── Utilities/
│   ├── AudioFileManager.swift           # File I/O: duration, deletion
│   └── PermissionsManager.swift         # Mic + speech recognition permissions
└── Assets.xcassets
    ├── AppIcon.appiconset/
    ├── AccentColor.colorset/
    ├── LaunchBg.colorset/
    └── MascotNeutral.imageset/
```

## Directory Purposes

**Abimo/ (Root):**
- Purpose: Main app target source files
- Contains: Entry point, root view, design system definitions
- Key files: `AbimoApp.swift`, `RootView.swift`, `ContentView.swift`

**Views/:**
- Purpose: SwiftUI UI components organized by feature
- Contains: 5 feature folders (Recording, Notes, Auth, Analysis, ActionPlan) + shared (LoadingView)
- Key files: Entry points for each tab/screen

**ViewModels/:**
- Purpose: State management and business logic coordination
- Contains: One @MainActor ObservableObject per feature, plus ActionsTabViewModel
- Key files: AuthViewModel (gates all authenticated content), ActionPlanViewModel (most complex)

**Models/:**
- Purpose: Data structures matching database schema
- Contains: 6 model files, each defining 1-3 Codable structs
- Key files: ActionPlan.swift (defines 4 related models)

**Services/:**
- Purpose: External integration and abstraction
- Contains: 5 service files, mostly singletons wrapping SDKs
- Key files: SupabaseService.swift (database/storage), AIAnalysisService.swift (Edge Functions)

**Utilities/:**
- Purpose: Reusable helper logic
- Contains: 2 utility files for file operations and permissions
- Key files: PermissionsManager.swift (required before recording)

**Assets.xcassets/:**
- Purpose: Images, colors, app icon
- Contains: Subdirectories for app icon, accent colors, launch background, mascot image

## Key File Locations

**Entry Points:**
- `Abimo/AbimoApp.swift`: App initialization, URL handling for OAuth
- `Abimo/Views/RootView.swift`: Auth state routing (LoadingView → LoginView → MainTabView)
- `Abimo/Views/Recording/RecordingView.swift`: Recording tab
- `Abimo/Views/Notes/NotesListView.swift`: Notes tab
- `Abimo/Views/ActionPlan/ActionsTabView.swift`: Actions tab
- `Abimo/Views/Auth/LoginView.swift`: Sign in/up form

**Configuration:**
- `Abimo/ContentView.swift`: Brand colors, gradients, reusable components (GradientButton, AppTextField, PulseRing, WaveformBarsView)
- `Abimo/Services/SupabaseService.swift`: Supabase URL and API key (hardcoded in init)

**Core Logic:**
- `Abimo/ViewModels/AuthViewModel.swift`: Authentication state, session listeners
- `Abimo/ViewModels/ActionPlanViewModel.swift`: Plan/action/commitment management, nudge computation
- `Abimo/Services/AIAnalysisService.swift`: SWOT analysis and action plan generation
- `Abimo/Services/SupabaseService.swift`: All database CRUD and file operations

**Feature State:**
- `Abimo/ViewModels/RecordingViewModel.swift`: Recording capture, file save
- `Abimo/ViewModels/AnalysisViewModel.swift`: SWOT analysis loading and generation
- `Abimo/Models/ActionPlan.swift`: Action plan, micro-action, commitment data structures

## Naming Conventions

**Files:**
- Format: PascalCase + .swift (e.g., `AuthViewModel.swift`, `RecordingView.swift`)
- Views: [Feature]View.swift (e.g., `RecordingView.swift`, `SWOTAnalysisView.swift`)
- ViewModels: [Feature]ViewModel.swift (e.g., `AuthViewModel.swift`, `ActionPlanViewModel.swift`)
- Models: [Entity].swift (e.g., `ActionPlan.swift` contains ActionPlan + MicroAction + Commitment)
- Services: [Domain]Service.swift (e.g., `SupabaseService.swift`, `AudioRecordingService.swift`)

**Directories:**
- Feature folders: lowercase plural (e.g., `Views`, `Services`, `Utilities`)
- Feature subfolders: lowercase plural (e.g., `Views/Auth`, `Views/Notes`, `Views/ActionPlan`)

**Code Identifiers:**
- Classes/Structs/Enums: PascalCase (e.g., `AuthViewModel`, `VoiceNote`, `NudgeType`)
- Properties/Methods: camelCase (e.g., `isAuthenticated`, `saveRecording()`)
- Private/internal properties: leading underscore for clarity (minimal use observed)
- Constants: SCREAMING_SNAKE_CASE or inline (minimal constants observed)

**Types:**
- View Models: `@MainActor class X: ObservableObject`
- Data Models: `struct X: Identifiable, Codable` (with CodingKeys for snake_case mapping)
- Services: `class X { static let shared = X() }`

## Where to Add New Code

**New Feature:**
- Views: `Abimo/Views/[FeatureName]/[Feature]View.swift`
- ViewModel: `Abimo/ViewModels/[Feature]ViewModel.swift`
- Models: Add structs to `Abimo/Models/` (create new file if entity is substantial, otherwise extend existing)
- Service: `Abimo/Services/[Domain]Service.swift` if new external integration, otherwise extend existing service

**New Screen/View:**
- Location: `Abimo/Views/[Feature]/[FeatureName]View.swift`
- Pattern: SwiftUI struct extending View, with @StateObject for local ViewModel
- Include: Preview at bottom with #Preview

**New Component:**
- Reusable UI elements: Add to `Abimo/ContentView.swift` as extensions/structs
- Feature-specific components: Keep in feature folder (e.g., `Views/ActionPlan/MicroActionRow.swift`)
- Pattern: Struct extending View, @ViewBuilder for composition

**New Service Method:**
- Existing integration: Add async method to corresponding service (e.g., new database operation → `SupabaseService`)
- New integration: Create `Abimo/Services/[New]Service.swift` with singleton pattern

**New Utility:**
- File operations: Extend `Abimo/Utilities/AudioFileManager.swift`
- Permissions: Extend `Abimo/Utilities/PermissionsManager.swift`
- Other: Create new file in `Abimo/Utilities/`

**New Model:**
- Small entity: Add to existing file (e.g., Commitment added to `ActionPlan.swift`)
- Substantial entity: Create `Abimo/Models/[Entity].swift`
- Pattern: Codable struct with CodingKeys for snake_case column mapping

## Special Directories

**Assets.xcassets/**
- Purpose: Xcode asset catalog for images, colors, icons
- Generated: Yes (by Xcode)
- Committed: Yes

**.claude/ & .gsd/ & .planning/**
- Purpose: GSD framework and planning documentation
- Generated: Yes (by GSD commands)
- Committed: Yes (checked into repo)

## Design System Definitions

**Colors:**
- Primary brand: `Color.brand` (#FF6B6B, coral red)
- Surfaces: `Color.appBg` (warm cream), `Color.cardSurface` (white)
- Status: `Color.brandGreen` (success), `Color.brandRed` (error), `Color.brandAmber` (warning)
- SWOT tinted cards: `Color.cardDarkBlue`, `.cardDarkTeal`, `.cardDarkPurple`, `.cardDarkOrange`, `.cardDarkRed`
- All defined as Color extensions in `Abimo/ContentView.swift` (lines 27-55)

**Component Library:**
- `GradientButton`: Primary action button with loading state
- `AppTextField`: Text input with focus states
- `PulseRing`: Animation for recording indicator
- `WaveformBarsView`: Audio level visualization
- All in `ContentView.swift` with reusable modifiers (.cardStyle, .tintedCard, .heroCard)

---

*Structure analysis: 2026-03-17*
