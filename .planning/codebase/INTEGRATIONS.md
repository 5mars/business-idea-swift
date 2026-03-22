# External Integrations

**Analysis Date:** 2026-03-17

## APIs & External Services

**Supabase Backend:**
- Supabase - Comprehensive backend platform serving multiple roles
  - SDK/Client: Supabase Swift SDK 2.x (`import Supabase`)
  - Primary Implementation: `Abimo/Services/SupabaseService.swift`
  - Auth: Uses Supabase JWT token system (managed internally by SDK)

**AI Services:**
- OpenAI GPT-4o - SWOT analysis and action plan generation
  - SDK/Client: OpenAI REST API (called from Supabase Edge Functions via HTTP)
  - Auth: `OPENAI_API_KEY` environment variable (set in Supabase project)
  - API Integration Point: Edge Functions invoke this via HTTPS
  - Functions:
    - `supabase/functions/analyze-swot/index.ts` - Structured SWOT analysis with JSON schema validation
    - `supabase/functions/generate-action-plan/index.ts` - Action plan generation from SWOT analysis

## Data Storage

**Databases:**
- PostgreSQL (Supabase-hosted) - Primary relational database
  - Connection: Managed by Supabase Swift SDK
  - Client Library: Supabase Swift SDK (wraps PostgREST API)
  - Tables Used:
    - `voice_notes` - User's recorded ideas
    - `transcriptions` - Speech-to-text results
    - `swot_analyses` - AI-generated SWOT analyses
    - `action_plans` - Action plans derived from analyses
    - `micro_actions` - Individual tasks within action plans
    - `commitments` - User commitments to actions
  - Row Level Security: Enabled (users can only access their own data)
  - Implementation: `SupabaseService.swift` methods for CRUD operations

**File Storage:**
- Supabase Storage (S3-compatible) - Audio file persistence
  - Bucket: `voice-recordings` (private bucket)
  - Usage: Stores M4A audio files organized by user ID
  - Access: Signed URLs generated via `getSignedAudioURL()` with expiration (default 1 hour)
  - Upload: `uploadAudioFile()` method stores files at path `{userId}/{UUID}.m4a`
  - Download: `downloadAudioFile()` retrieves files and saves to temp directory
  - Security: Private bucket - access controlled via signed URLs

**Caching:**
- None - Direct database queries without intermediate cache layer

## Authentication & Identity

**Auth Provider:**
- Supabase Auth (email/password)
  - Implementation: `SupabaseService.signUp()`, `signIn()`, `signOut()`
  - Token Management: Supabase Swift SDK manages JWT tokens automatically
  - Session: Checked via `getCurrentUser()` which reads `client.auth.session`
  - Auth Flow:
    1. User signs up with email/password via `signUp()`
    2. Supabase generates JWT token
    3. Token used for subsequent API calls (automatic in SDK)
    4. Row Level Security enforces user isolation
  - Custom Auth: None; no OAuth, Apple Sign In, or custom JWT implemented
  - Implementation: `Abimo/ViewModels/AuthViewModel.swift`

## Monitoring & Observability

**Error Tracking:**
- None - Console logging only

**Logs:**
- Local console logging for debugging
- Supabase Edge Functions log to Deno runtime output
- No external log aggregation (Sentry, Datadog, etc.)

## CI/CD & Deployment

**Hosting:**
- iOS App Store / App Store Connect (for distribution)
- Supabase Cloud (database, auth, storage, functions)

**CI Pipeline:**
- None - Manual build and test via Xcode
- No GitHub Actions, CircleCI, or automated testing

**Deployment:**
- Manual: Build and archive in Xcode, submit to App Store
- Supabase Edge Functions: Deployed via Supabase CLI from local machine
- No automated deployment pipeline

## Environment Configuration

**Required env vars (Swift app):**
- None hardcoded as environment variables in app
- Supabase credentials hardcoded in `SupabaseService.swift` (lines 17-24)
  - `SUPABASE_URL` = `https://ymbfqlrarlnqtzatgfah.supabase.co`
  - `SUPABASE_ANON_KEY` = `sb_publishable_HUIZRQ5EfaFU3EV-1IzqNQ_8uOBDJ39`

**Required env vars (Supabase Edge Functions):**
- `OPENAI_API_KEY` - Set in Supabase project settings
  - Used by: `analyze-swot` and `generate-action-plan` functions
  - Location: Environment variable in function runtime (Deno)

**Secrets location:**
- Supabase project settings - for `OPENAI_API_KEY`
- Xcode build settings - none used
- Swift hardcoded values - Supabase credentials (non-sensitive publishable key)

## Webhooks & Callbacks

**Incoming:**
- Deep link handler: `noteai://` URL scheme registered in Info.plist
  - Used for auth callbacks (redirect from Supabase auth flow)
  - Configured: `CFBundleURLTypes` in `Abimo/Info.plist` (lines 12-22)

**Outgoing:**
- None - No webhooks sent from app to external services

## API Endpoints

**Supabase APIs Called:**
- Auth: `POST /auth/v1/signup`, `POST /auth/v1/signin`, `POST /auth/v1/signout`
- Database: PostgREST queries via SDK (`/rest/v1/{table}`)
- Storage: File operations via Storage API (`/storage/v1/object/{bucket}`)
- Functions: Edge Function invocation via Functions API

**OpenAI API Called:**
- `POST https://api.openai.com/v1/chat/completions`
  - Called from Supabase Edge Functions only (not directly from Swift app)
  - Request format: JSON with `gpt-4o` model, structured output schema
  - Response: JSON with `analysis_id`, quadrant items, viability score

## Data Flow

**Recording to Analysis Pipeline:**
1. User records voice note → `AudioRecordingService.startRecording()`
2. Saves M4A file to local filesystem → `AudioRecordingService.stopRecording()`
3. File uploaded to Supabase Storage → `SupabaseService.uploadAudioFile()`
4. Voice note metadata saved to DB → `SupabaseService.createVoiceNote()`
5. Transcription via Speech Framework → `TranscriptionService.transcribeWithSpeechRecognizer()`
6. Transcription saved to DB → `SupabaseService.createTranscription()`
7. SWOT analysis via OpenAI → `AIAnalysisService.analyzeTranscription()`
   - Calls Supabase function `analyze-swot`
   - Function invokes OpenAI API with structured schema
8. Analysis saved to DB → `SupabaseService.createSWOTAnalysis()`
9. Action plan generated → `AIAnalysisService.generateAndSaveActionPlan()`
   - Calls Supabase function `generate-action-plan`
   - Function invokes OpenAI API with full SWOT context

## Security Considerations

**API Key Security:**
- Supabase Anon Key: Publishable (safe for client apps)
- OpenAI Key: Kept in Supabase environment variable (not exposed to client)
- No API keys hardcoded in Swift app except Supabase publishable key

**Data Security:**
- Row Level Security: Enabled on all tables - users can only query own data
- Private Storage Bucket: Audio files stored in private bucket, accessed via signed URLs
- Signed URLs: Generated with 1-hour expiration by default
- HTTPS: All API calls use HTTPS

**Authentication:**
- JWT tokens: Supabase manages token storage and refresh
- No direct credential storage in app
- Session validation on app launch via `getCurrentUser()`

---

*Integration audit: 2026-03-17*
