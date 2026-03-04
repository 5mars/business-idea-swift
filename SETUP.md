# Voice Recording & AI SWOT Analysis App - Setup Guide

## Project Structure Created ✅

The following files have been created:

### Models
- ✅ `Models/VoiceNote.swift` - Core data model for voice recordings
- ✅ `Models/Transcription.swift` - Transcription data model
- ✅ `Models/SWOTAnalysis.swift` - SWOT analysis data model
- ✅ `Models/User.swift` - User data model

### ViewModels
- ✅ `ViewModels/AuthViewModel.swift` - Authentication state management
- ✅ `ViewModels/RecordingViewModel.swift` - Recording orchestration
- ✅ `ViewModels/NotesViewModel.swift` - Notes list management
- ✅ `ViewModels/AnalysisViewModel.swift` - SWOT analysis management

### Views
- ✅ `Views/RootView.swift` - Main app entry point with auth routing
- ✅ `Views/Auth/LoginView.swift` - Login interface
- ✅ `Views/Auth/SignUpView.swift` - Sign up interface
- ✅ `Views/Recording/RecordingView.swift` - Recording interface
- ✅ `Views/Notes/NotesListView.swift` - List of recordings
- ✅ `Views/Notes/NoteDetailView.swift` - Individual note detail
- ✅ `Views/Analysis/SWOTAnalysisView.swift` - SWOT analysis display

### Services
- ✅ `Services/SupabaseService.swift` - Backend client singleton
- ✅ `Services/AudioRecordingService.swift` - Audio recording logic
- ✅ `Services/TranscriptionService.swift` - Speech-to-text service
- ✅ `Services/AIAnalysisService.swift` - AI analysis service

### Utilities
- ✅ `Utilities/PermissionsManager.swift` - Permission handling
- ✅ `Utilities/AudioFileManager.swift` - File handling utilities

---

## Next Steps - Manual Configuration Required

### 1. Add Swift Package Dependencies

Open Xcode and add these packages:

1. **Supabase Swift**
   - File > Add Package Dependencies
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Latest (2.x)
   - Add to target: `note-ai-app-test`

### 2. Configure Info.plist Permissions

In Xcode:
1. Select the project in the navigator
2. Select the `note-ai-app-test` target
3. Go to the "Info" tab
4. Add these Custom iOS Target Properties:

| Key | Type | Value |
|-----|------|-------|
| `NSMicrophoneUsageDescription` | String | `We need microphone access to record your voice notes` |
| `NSSpeechRecognitionUsageDescription` | String | `We need speech recognition to transcribe your recordings` |

**Alternative method:** Right-click on `Info.plist` (or project settings) and select "Open As > Source Code", then add:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your voice notes</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need speech recognition to transcribe your recordings</string>
```

### 3. Set Up Supabase Backend

#### A. Create Supabase Project
1. Go to https://supabase.com
2. Create a new project
3. Note your project URL and anon key

#### B. Run Database Schema
In Supabase SQL Editor, run this SQL:

```sql
-- Voice notes table
CREATE TABLE voice_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    audio_file_url TEXT NOT NULL,
    duration NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Transcriptions table
CREATE TABLE transcriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id UUID REFERENCES voice_notes(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    confidence NUMERIC,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- SWOT analyses table
CREATE TABLE swot_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transcription_id UUID REFERENCES transcriptions(id) ON DELETE CASCADE,
    strengths JSONB NOT NULL DEFAULT '[]',
    weaknesses JSONB NOT NULL DEFAULT '[]',
    opportunities JSONB NOT NULL DEFAULT '[]',
    threats JSONB NOT NULL DEFAULT '[]',
    summary TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE voice_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE transcriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE swot_analyses ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage own notes" ON voice_notes
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view related transcriptions" ON transcriptions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM voice_notes
            WHERE voice_notes.id = transcriptions.note_id
            AND voice_notes.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert transcriptions" ON transcriptions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM voice_notes
            WHERE voice_notes.id = transcriptions.note_id
            AND voice_notes.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view related analyses" ON swot_analyses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM transcriptions t
            JOIN voice_notes vn ON vn.id = t.note_id
            WHERE t.id = swot_analyses.transcription_id
            AND vn.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert analyses" ON swot_analyses
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM transcriptions t
            JOIN voice_notes vn ON vn.id = t.note_id
            WHERE t.id = swot_analyses.transcription_id
            AND vn.user_id = auth.uid()
        )
    );

-- Indexes
CREATE INDEX idx_voice_notes_user_id ON voice_notes(user_id);
CREATE INDEX idx_voice_notes_created_at ON voice_notes(created_at DESC);
CREATE INDEX idx_transcriptions_note_id ON transcriptions(note_id);
CREATE INDEX idx_swot_analyses_transcription_id ON swot_analyses(transcription_id);
```

#### C. Configure Storage Bucket
1. Go to Supabase Dashboard > Storage
2. Create new bucket: `voice-recordings`
3. Set to **Private**
4. In SQL Editor, add storage policies:

```sql
-- Users can upload to their own folder
CREATE POLICY "Users can upload own recordings" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'voice-recordings'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Users can view own recordings
CREATE POLICY "Users can view own recordings" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'voice-recordings'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Users can delete own recordings
CREATE POLICY "Users can delete own recordings" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'voice-recordings'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
```

#### D. Enable Email Authentication
1. Go to Authentication > Providers
2. Enable **Email** provider
3. (Optional) Configure email templates

### 4. Configure Supabase Edge Function

#### Create Edge Function for AI Analysis
1. In Supabase Dashboard > Edge Functions
2. Create new function: `analyze-swot`
3. Add this code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { transcription } = await req.json()

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'system',
            content: 'You are a business analyst expert. Analyze the given business idea and provide a SWOT analysis. Return a JSON object with four arrays: strengths, weaknesses, opportunities, threats (each containing 3-5 bullet points), and a summary string.'
          },
          {
            role: 'user',
            content: `Analyze this business idea:\n\n${transcription}\n\nProvide a structured SWOT analysis.`
          }
        ],
        response_format: { type: "json_object" },
        temperature: 0.7
      })
    })

    const data = await openaiResponse.json()
    const analysis = JSON.parse(data.choices[0].message.content)

    return new Response(
      JSON.stringify(analysis),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
```

4. Add environment variable:
   - Go to Edge Functions > Settings
   - Add secret: `OPENAI_API_KEY` = `your-openai-api-key`

### 5. Update Supabase Credentials in Code

Open `Services/SupabaseService.swift` and replace:

```swift
let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
```

With your actual credentials from Supabase Dashboard > Settings > API.

### 6. Add Files to Xcode Project

All the Swift files have been created in the file system, but need to be added to Xcode:

1. In Xcode, right-click on the `note-ai-app-test` folder in the navigator
2. Select "Add Files to 'note-ai-app-test'..."
3. Navigate to each folder (Models, ViewModels, Views, Services, Utilities)
4. Select all the new `.swift` files
5. Make sure "Copy items if needed" is UNCHECKED
6. Make sure target `note-ai-app-test` is CHECKED
7. Click "Add"

---

## Building and Running

### Minimum Requirements
- iOS 17.0+ (for basic features)
- iOS 26.0+ (for SpeechAnalyzer - optimal transcription)
- Xcode 16+
- Swift 6.0+

### Build Steps
1. Open `note-ai-app-test.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Choose a simulator or physical device (iOS 17+)
4. Build and run (⌘R)

### Testing Checklist
- [ ] App launches without crashes
- [ ] Login/signup flows work
- [ ] Microphone permission is requested
- [ ] Speech recognition permission is requested
- [ ] Can record audio with visual feedback
- [ ] Recording saves successfully
- [ ] Notes list displays saved recordings
- [ ] Can view note details
- [ ] Transcription works (iOS 26+ devices)
- [ ] SWOT analysis generates (requires OpenAI API key)

---

## Troubleshooting

### Supabase Connection Issues
- Verify URL and anon key in `SupabaseService.swift`
- Check Supabase project is not paused (free tier limitation)
- Verify database tables exist in Supabase dashboard

### Recording Issues
- Ensure Info.plist has microphone permission description
- Test on physical device (simulator may have limitations)
- Check device microphone is not being used by another app

### Transcription Issues
- iOS 26+ required for SpeechAnalyzer
- Falls back to SFSpeechRecognizer on older iOS versions
- Requires internet connection for cloud-based recognition
- Check speech recognition permission is granted

### SWOT Analysis Issues
- Verify OpenAI API key is added to Edge Function secrets
- Check Edge Function is deployed and running
- Verify transcription exists before attempting analysis
- Check OpenAI API account has credits

---

## What's Implemented

✅ Complete MVVM architecture
✅ Supabase authentication (email/password)
✅ Audio recording with AVFoundation
✅ Real-time audio level visualization
✅ File upload to Supabase Storage
✅ Voice notes CRUD operations
✅ Transcription service (SpeechAnalyzer + fallback)
✅ AI SWOT analysis via Edge Functions
✅ Permission management
✅ Error handling throughout
✅ Loading states and UI feedback
✅ Pull-to-refresh on notes list
✅ Swipe-to-delete notes

## What Needs Additional Work

⚠️ **Audio playback** - Not implemented yet
⚠️ **Audio download from storage** - Transcription requires downloading audio first
⚠️ **Apple Sign In** - Framework added but not implemented in UI
⚠️ **Offline sync** - Currently requires internet connection
⚠️ **Note editing** - Can't edit titles after creation
⚠️ **Export functionality** - Can't export analyses as PDF/text

---

## File Structure

```
note-ai-app-test/
├── SETUP.md (this file)
├── note-ai-app-test/
│   ├── Models/
│   │   ├── VoiceNote.swift
│   │   ├── Transcription.swift
│   │   ├── SWOTAnalysis.swift
│   │   └── User.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── RecordingViewModel.swift
│   │   ├── NotesViewModel.swift
│   │   └── AnalysisViewModel.swift
│   ├── Views/
│   │   ├── RootView.swift
│   │   ├── Auth/
│   │   │   ├── LoginView.swift
│   │   │   └── SignUpView.swift
│   │   ├── Recording/
│   │   │   └── RecordingView.swift
│   │   ├── Notes/
│   │   │   ├── NotesListView.swift
│   │   │   └── NoteDetailView.swift
│   │   └── Analysis/
│   │       └── SWOTAnalysisView.swift
│   ├── Services/
│   │   ├── SupabaseService.swift
│   │   ├── AudioRecordingService.swift
│   │   ├── TranscriptionService.swift
│   │   └── AIAnalysisService.swift
│   ├── Utilities/
│   │   ├── PermissionsManager.swift
│   │   └── AudioFileManager.swift
│   ├── note_ai_app_testApp.swift
│   └── ContentView.swift (can be deleted)
```

---

## Getting Help

If you encounter issues:

1. Check Xcode console for error messages
2. Verify all Supabase tables and policies are created
3. Ensure Swift packages are properly installed
4. Check device/simulator iOS version meets requirements
5. Review this setup guide for missed steps

---

## Ready to Go! 🚀

Once you complete the manual configuration steps above, your app will be ready to:
- Record voice notes about business ideas
- Automatically transcribe recordings
- Generate AI-powered SWOT analyses
- Store everything securely in Supabase

Happy coding!
