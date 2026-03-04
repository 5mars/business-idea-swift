# Quick Start Guide - Add Files to Xcode

## Step 1: Add Swift Package Dependencies

1. Open `note-ai-app-test.xcodeproj` in Xcode
2. File > Add Package Dependencies
3. Enter URL: `https://github.com/supabase/supabase-swift`
4. Click "Add Package"
5. Select all Supabase products and click "Add Package"

## Step 2: Add New Files to Xcode Project

All Swift files have been created on disk but need to be added to Xcode:

### Method 1: Drag and Drop (Easiest)
1. In Finder, navigate to `/Users/mi/Desktop/Swift/note-ai-app-test/note-ai-app-test/`
2. Drag these folders into Xcode's Project Navigator:
   - Models folder
   - ViewModels folder
   - Views folder
   - Services folder
   - Utilities folder
3. In the dialog:
   - **UNCHECK** "Copy items if needed"
   - **CHECK** "Create groups"
   - **CHECK** target "note-ai-app-test"
   - Click "Finish"

### Method 2: Add Files Menu
1. In Xcode, right-click on `note-ai-app-test` folder
2. Select "Add Files to 'note-ai-app-test'..."
3. Navigate to and select the folders:
   - Models
   - ViewModels
   - Views
   - Services
   - Utilities
4. **UNCHECK** "Copy items if needed"
5. **CHECK** "Create groups"
6. **CHECK** target "note-ai-app-test"
7. Click "Add"

## Step 3: Configure Permissions

1. In Xcode, select the project in the navigator
2. Select the `note-ai-app-test` target
3. Go to "Info" tab
4. Click "+" to add new keys:

**Add these two keys:**

| Key | Type | Value |
|-----|------|-------|
| Privacy - Microphone Usage Description | String | We need microphone access to record your voice notes |
| Privacy - Speech Recognition Usage Description | String | We need speech recognition to transcribe your recordings |

## Step 4: Configure Supabase

1. Create account at https://supabase.com
2. Create a new project
3. Copy your Project URL and Anon Key from Settings > API
4. Open `Services/SupabaseService.swift` in Xcode
5. Replace:
   ```swift
   let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
   let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
   ```
   With your actual values

6. In Supabase Dashboard, go to SQL Editor and run the database schema from SETUP.md

## Step 5: Build and Run

1. Select a simulator or device (iOS 17+)
2. Press ⌘R to build and run
3. Test the login/signup flow

## Troubleshooting

### Build Errors
- **"No such module 'Supabase'"** → Make sure Swift package was added
- **"Cannot find type 'RootView'"** → Files not added to Xcode project
- **Duplicate symbols errors** → Remove ContentView.swift or don't import it

### Runtime Errors
- **Supabase connection errors** → Check URL and key in SupabaseService.swift
- **Permission denied** → Add Info.plist keys for microphone and speech recognition
- **Auth errors** → Enable Email provider in Supabase Dashboard > Authentication

## Files Created

✅ 4 Models
✅ 4 ViewModels
✅ 7 Views
✅ 4 Services
✅ 2 Utilities
✅ Updated app entry point

Total: **21 Swift files** ready to use!

## Next Steps

See `SETUP.md` for complete setup instructions including:
- Database schema
- Storage bucket configuration
- Edge function deployment
- OpenAI integration

---

**Need help?** Check the console output in Xcode for error messages.
