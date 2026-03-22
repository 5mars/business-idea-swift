# Codebase Concerns

**Analysis Date:** 2026-03-17

## Tech Debt

**Hardcoded Supabase Credentials:**
- Issue: Supabase URL and publishable key are hardcoded in `SupabaseService.swift` (lines 18-19)
- Files: `Abimo/Services/SupabaseService.swift`
- Impact: Security vulnerability - credentials exposed in source code. Anyone with access to code can impersonate the app. Production deployment impossible without credential exposure.
- Fix approach: Move to Info.plist, environment variables, or configuration file. Load at runtime. Mark as TODO (currently noted on line 17 but not implemented).

**Unused/Incomplete Transcription Service:**
- Issue: `TranscriptionService.swift` has commented logic for Whisper API and Speech Recognition but the `transcribe()` method (lines 52-59) always uses Speech Recognizer regardless of `useWhisper` parameter
- Files: `Abimo/Services/TranscriptionService.swift`
- Impact: Whisper API capability is dead code; the parameter is misleading and ignored. Method signature suggests two code paths but only one works.
- Fix approach: Either implement actual Whisper support or remove the unused parameter and logic. Currently line 52's `useWhisper` parameter is never used - clean up.

**Silent Error Swallowing in Audio Operations:**
- Issue: File deletion and audio session teardown errors are silently caught with `try?` without logging
- Files: `Abimo/Services/AudioRecordingService.swift` (line 92), `Abimo/Utilities/AudioFileManager.swift` (lines 18, 19), `Abimo/ViewModels/RecordingViewModel.swift` (line 112)
- Impact: Disk space can accumulate from failed deletions; users don't know why cleanup failed. Debugging audio issues becomes harder.
- Fix approach: Log these failures with appropriate error messages before silently continuing.

**Timer Resource Leaks in Recording/Playback:**
- Issue: Multiple Timer instances created without guaranteed cleanup in edge cases
- Files: `Abimo/Services/AudioRecordingService.swift` (lines 57, 65), `Abimo/Services/AudioPlayerService.swift` (line 67)
- Impact: If view dismisses unexpectedly or task is cancelled mid-operation, timers continue running in background, draining battery. AudioPlayerService has deinit cleanup (line 88-92) but AudioRecordingService does not.
- Fix approach: Add deinit to AudioRecordingService to guarantee timer cleanup. Ensure weak self captures prevent retain cycles.

**Missing Input Validation:**
- Issue: User inputs (email, password, title, transcription text) are not validated before sending to backend
- Files: `Abimo/Views/Auth/LoginView.swift` (lines 69-80 accept empty strings), `Abimo/Views/Auth/SignUpView.swift`, `Abimo/Views/Notes/NotesListView.swift` (no title validation)
- Impact: Backend receives malformed data; OpenAI API calls with empty transcriptions fail ungracefully. Empty email/password combinations waste API calls.
- Fix approach: Add validation before async operations. Show user feedback for validation failures.

**Inconsistent Error Handling:**
- Issue: ViewModels set `errorMessage` in catch blocks but no consistent recovery flow. Some errors are fatal, some retryable.
- Files: All ViewModels (`AnalysisViewModel.swift`, `NotesViewModel.swift`, `RecordingViewModel.swift`, `ActionPlanViewModel.swift`)
- Impact: Users see errors but can't distinguish between temporary (network) and permanent (auth) failures. No retry mechanism.
- Fix approach: Create error enum with recovery suggestions. Distinguish transient vs. permanent failures.

---

## Known Bugs

**Speech Recognizer May Return Duplicated Results:**
- Symptoms: When speech recognition completes, partial results appear to fire continuation multiple times
- Files: `Abimo/Services/TranscriptionService.swift` (lines 79-96)
- Trigger: Occurs intermittently when recognitionTask completes, especially on slower devices
- Workaround: Currently `finalTranscription` is force-unwrapped (line 94) - this can crash if result is nil at final callback
- Root cause: The `withCheckedThrowingContinuation` pattern with the speech recognizer's async callback doesn't guarantee single invocation

**Audio Session Category Conflicts:**
- Symptoms: Playback fails or records silence after playback session
- Files: `Abimo/Services/AudioRecordingService.swift` (line 30), `Abimo/Services/AudioPlayerService.swift` (line 36)
- Trigger: Occurs if recording starts immediately after playback, or playback after recording
- Root cause: Different AVAudioSession categories (.playAndRecord vs .playback) don't automatically coordinate. No session deactivation between switches.
- Workaround: Restart app

**Transcription ID Mismatch:**
- Symptoms: Transcription cannot be fetched after creation; analysis fails to find transcription
- Files: `Abimo/Services/SupabaseService.swift` (lines 159-175), `Abimo/Models/Transcription.swift`
- Trigger: When VoiceNote record is created before Transcription is created, FK constraints may fail
- Root cause: Race condition - voice note creation may complete before transcription row is inserted

---

## Security Considerations

**API Keys Exposed in Client:**
- Risk: Supabase publishable key is embedded in app binary. While publishable keys have RLS protection, they're visible to anyone who decompiles app.
- Files: `Abimo/Services/SupabaseService.swift` (line 19)
- Current mitigation: Supabase Row Level Security on tables (mentioned in README but not verified in schema)
- Recommendations: Use Supabase JWT token refresh flow. Never trust client-side secrets. Verify RLS policies block unauthorized access. Consider proxy auth through backend for sensitive operations.

**OpenAI API Key in Edge Function Only:**
- Risk: Edge function has OPENAI_API_KEY as environment variable. If function logs are exposed or function source is compromised, key is revealed.
- Files: `supabase/functions/analyze-swot/index.ts` (line 3), `supabase/functions/generate-action-plan/index.ts` (line 3)
- Current mitigation: Key is server-side only, not in app binary
- Recommendations: Implement request signing to prevent unauthorized API calls. Add rate limiting. Monitor for unusual API usage. Rotate key regularly.

**No Request Signing on Edge Functions:**
- Risk: Anyone with the function URL can invoke it if auth check fails
- Files: Both edge functions check Authorization header (lines 170-176 in both files) but no cryptographic signature validation
- Current mitigation: Requires Authorization header (basic protection)
- Recommendations: Implement JWT validation beyond header presence. Add request signature validation. Log all function invocations.

**Plaintext Storage of Sensitive Data:**
- Risk: User sessions, audio files stored in Supabase without encryption at rest verification
- Files: All data operations in `Abimo/Services/SupabaseService.swift`
- Current mitigation: Private storage bucket mentioned in README
- Recommendations: Verify Supabase encryption at rest is enabled. Add client-side encryption for audio files if handling PII. Implement secure session timeout.

**No Certificate Pinning:**
- Risk: MITM attacks possible on Supabase and OpenAI API calls
- Files: All network operations use standard URLSession
- Current mitigation: HTTPS only
- Recommendations: Implement certificate pinning for Supabase and OpenAI endpoints in production.

---

## Performance Bottlenecks

**Large SWOT Analysis View Rendering:**
- Problem: `SWOTAnalysisView.swift` is 848 lines - displays 20+ text views with complex nested VStacks
- Files: `Abimo/Views/Analysis/SWOTAnalysisView.swift`
- Cause: No lazy loading or virtualization of SWOT items. All items rendered simultaneously.
- Impact: Scrolling jank on older devices (iPhone 11/12) when view loads
- Improvement path: Break into smaller components. Use LazyVStack for items. Implement pagination or collapsible sections.

**Full Audio File Download on Playback:**
- Problem: `AudioPlayerService.prepare()` downloads entire audio file to memory before playback
- Files: `Abimo/Services/SupabaseService.swift` (lines 137-148), `Abimo/Services/AudioPlayerService.swift` (lines 28-42)
- Cause: `downloadAudioFile()` writes full file to temp directory; AVAudioPlayer loads entire file
- Impact: High memory usage for long recordings (>10 minutes). Playback has 2-3 second latency.
- Improvement path: Use streaming playback if possible. Implement progressive download. Cache downloaded files.

**Synchronous Audio Duration Calculation:**
- Problem: `AudioFileManager.getDuration()` synchronously loads AVURLAsset which blocks UI
- Files: `Abimo/Utilities/AudioFileManager.swift` (lines 12-14), called from `Abimo/ViewModels/RecordingViewModel.swift` (line 77)
- Cause: No async/await wrapper; blocks MainActor thread
- Impact: Noticeable UI freeze (0.5-2 seconds) when saving recordings
- Improvement path: Async wrapper using async let or Task. Cache duration with file.

**No Pagination on Voice Notes List:**
- Problem: `fetchVoiceNotes()` retrieves all notes without limit
- Files: `Abimo/Services/SupabaseService.swift` (lines 83-92)
- Cause: No `.limit()` clause; full dataset transferred for users with 100+ notes
- Impact: Slow initial load. High bandwidth usage. Memory pressure.
- Improvement path: Implement pagination with `.limit(50)`. Add infinite scroll or lazy loading.

---

## Fragile Areas

**ViewModels with No Lifecycle Management:**
- Files: `Abimo/ViewModels/ActionPlanViewModel.swift`
- Why fragile: Creates fresh instances of AIAnalysisService and SupabaseService every initialization. No dependency injection. Services don't share state.
- Safe modification: Create a service locator or factory. Ensure view model is scoped correctly in SwiftUI. Add `.onDisappear` cleanup where needed.
- Test coverage: No unit tests exist - cannot verify behavior changes

**Complex State Transitions in ActionPlanViewModel:**
- Files: `Abimo/ViewModels/ActionPlanViewModel.swift` (410 lines)
- Why fragile: Manages commitment flow, reflection, completion tracking. Multiple @Published vars can get out of sync. No state machine.
- Safe modification: Add unit tests before refactoring. Create state enum instead of multiple booleans.
- Test coverage: Untested

**Audio Recording Edge Cases:**
- Files: `Abimo/Services/AudioRecordingService.swift`
- Why fragile: Timer management, audio session state, file URL cleanup. If `cancelRecording()` is called during upload, file may be deleted while in flight.
- Safe modification: Use semaphores or state machine to coordinate recording, stopping, and cleanup. Add integration tests.
- Test coverage: No tests

**Deep Link Data Serialization:**
- Files: `Abimo/Models/ActionPlan.swift` (lines 76-88)
- Why fragile: Custom CodingKeys for snake_case conversion. Optional fields with empty strings can cause encoding errors. No validation of URL schemes.
- Safe modification: Add unit tests for encoding/decoding. Validate DeepLinkData before using. Consider codable auto-generation.
- Test coverage: No tests

---

## Scaling Limits

**Single Supabase Service Instance:**
- Current capacity: One singleton handles all auth, database, and storage operations
- Limit: No connection pooling. Single authenticated session. If token expires mid-operation, all requests fail.
- Scaling path: Implement token refresh logic. Add connection retry with exponential backoff. Cache database queries client-side.

**No Caching Strategy:**
- Current capacity: Every view load triggers fresh database queries
- Limit: 100+ users simultaneously = 100+ `fetchVoiceNotes()` calls. Supabase free tier rate limits will trigger.
- Scaling path: Implement local cache with TTL. Add @Query cache layer. Invalidate on write operations.

**Audio Storage Without Lifecycle:**
- Current capacity: All audio files uploaded to `voice-recordings` bucket without retention policy
- Limit: 1000 users × 50 notes × 5MB avg = 250GB storage. Storage quota exceeded.
- Scaling path: Implement file retention policy. Delete old files after 30 days. Add archival to cold storage.

**OpenAI API Rate Limiting:**
- Current capacity: No rate limiting on SWOT/action plan generation
- Limit: GPT-4o API has rate limits. Users generating multiple analyses simultaneously will hit errors.
- Scaling path: Add client-side rate limiting. Implement request queue. Add credits/usage tracking.

---

## Dependencies at Risk

**Supabase Swift Client (latest unstable):**
- Risk: Supabase Swift 2.x is relatively new. Breaking changes may occur. Client library may have bugs not yet discovered.
- Impact: Authentication failures, data serialization issues, storage upload failures
- Migration plan: Pin to minor version (2.x.x). Monitor releases. Use feature flags for new functionality.

**Speech Recognition Framework (OS-dependent):**
- Risk: iOS 17+ only. Speech recognizer availability varies by region and OS version. Apple may change SFSpeechRecognizer in future iOS.
- Impact: Transcription may fail silently on some devices. Future iOS update could break transcription.
- Migration plan: Implement Whisper API as fallback. Add on-device transcription option.

**AVFoundation Audio Recording (OS-dependent):**
- Risk: Audio format (MPEG4 AAC) may not be supported on all devices. AVAudioRecorder behavior varies by device.
- Impact: Recording fails on edge case devices. Audio quality varies.
- Migration plan: Add multiple format support. Test on variety of devices.

---

## Missing Critical Features

**No Offline Sync:**
- Problem: If user records voice note offline, it's lost when app restarts
- Blocks: Offline workflow. Recording while commuting.
- Impact: Users lose work

**No Error Recovery UI:**
- Problem: Network errors show generic messages. No retry button.
- Blocks: Users can't recover from transient failures
- Impact: Frustration. Abandoned analyses.

**No Data Export:**
- Problem: Users cannot backup or export their analyses
- Blocks: Data portability. Migration to other tools.
- Impact: Lock-in to app

**No Undo for Micro Action Completion:**
- Problem: Once completed, micro action cannot be uncompleted
- Blocks: Accidental completion mistakes
- Impact: Users must contact support for corrections

---

## Test Coverage Gaps

**No Unit Tests:**
- What's not tested: Service layer (Supabase, AI, Audio), ViewModel business logic, model encoding/decoding
- Files: All `.swift` files in Services, ViewModels, Models directories
- Risk: Refactoring changes break functionality undetected. Performance regressions go unnoticed. Edge cases fail in production.
- Priority: High - Core business logic untested

**No Integration Tests:**
- What's not tested: End-to-end workflows (record → transcribe → analyze), Supabase operations, audio file lifecycle
- Files: All service interactions
- Risk: Bugs in service coordination discovered in production. API contract mismatches.
- Priority: High - User workflows untested

**No UI Tests:**
- What's not tested: View layouts, navigation flows, user interactions (recording, playback, form submission)
- Files: All Views
- Risk: UI regressions, navigation breaks, inaccessible UI
- Priority: Medium - Visual issues less critical than data loss

**No Performance Tests:**
- What's not tested: Memory usage, rendering performance, API call speed, file upload/download timing
- Files: All large views (SWOTAnalysisView, NoteDetailView)
- Risk: Performance degradation unnoticed until users complain
- Priority: Medium - Affects user experience

---

## Additional Observations

**View Complexity:**
- `SWOTAnalysisView.swift` (848 lines) and `NoteDetailView.swift` (748 lines) are monolithic
- Should be decomposed into smaller reusable components
- Makes testing and modification unsafe

**Credential Placeholder in Code:**
- Line 17 of `SupabaseService.swift` has TODO comment
- Implementation is incomplete - credentials are hardcoded but marked as needing replacement
- This is blocking production deployment

**Missing Documentation:**
- No inline comments explaining complex logic (audio recording timers, state transitions)
- No documentation of Supabase schema, RLS policies, or API contract
- Makes maintenance difficult

---

*Concerns audit: 2026-03-17*
