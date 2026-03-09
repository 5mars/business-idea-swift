# Abimo

> A SwiftUI iOS app that records voice notes about business ideas, transcribes them automatically, and generates AI-powered SWOT analyses.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## ✨ Features

- 🎤 **High-Quality Voice Recording** - Record business ideas with real-time audio visualization
- 📝 **Automatic Transcription** - On-device speech-to-text (iOS 26+) with cloud fallback
- 🤖 **AI SWOT Analysis** - GPT-4o powered business analysis
- 🔐 **Secure Authentication** - Email/password authentication
- ☁️ **Cloud Storage** - All data synced to Supabase
- 🎨 **Modern UI** - Clean SwiftUI interface following iOS design guidelines
- 📊 **Visual Analytics** - Color-coded SWOT quadrants with summaries

---

## 🚀 Quick Start

### Prerequisites
- Xcode 16+
- iOS 17+ device or simulator
- Supabase account (free tier works)
- OpenAI API key (for SWOT analysis)

### Installation

1. **Clone or download this project**
   ```bash
   cd /Users/mi/Desktop/Swift/Abimo
   ```

2. **Open in Xcode**
   ```bash
   open Abimo.xcodeproj
   ```

3. **Follow setup guides**
   - 📖 [QUICK_START.md](QUICK_START.md) - Fast setup (5 minutes)
   - 📖 [SETUP.md](SETUP.md) - Comprehensive guide (15 minutes)
   - ✅ [CHECKLIST.md](CHECKLIST.md) - Step-by-step checklist

---

## 📁 Project Structure

```
Abimo/
├── Models/              # Data models (VoiceNote, Transcription, SWOTAnalysis)
├── ViewModels/          # Business logic & state management
├── Views/               # SwiftUI views
│   ├── Auth/           # Login & signup
│   ├── Recording/      # Voice recording interface
│   ├── Notes/          # Notes list & detail
│   └── Analysis/       # SWOT analysis display
├── Services/            # Backend services (Supabase, Audio, AI)
└── Utilities/           # Helper utilities (Permissions, File management)
```

**Total**: 21 Swift files, ~2,500+ lines of code

---

## 🎯 Key Technologies

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Modern declarative UI framework |
| **AVFoundation** | High-quality audio recording |
| **Speech Framework** | On-device transcription (iOS 26+) |
| **Supabase** | Backend (auth, database, storage) |
| **OpenAI GPT-4o** | AI-powered SWOT analysis |
| **MVVM Pattern** | Clean architecture |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                     Views                        │
│            (SwiftUI Components)                  │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│                 ViewModels                       │
│         (Business Logic & State)                 │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│                  Services                        │
│    (Supabase, Audio, Transcription, AI)         │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│                   Models                         │
│              (Data Structures)                   │
└─────────────────────────────────────────────────┘
```

**MVVM Benefits:**
- ✅ Separation of concerns
- ✅ Testable business logic
- ✅ Reusable components
- ✅ Clear data flow

---

## 📸 Screenshots

> *Add screenshots here after building the app*

---

## 🔒 Security

- ✅ **Row Level Security** - Users can only access their own data
- ✅ **Private Storage** - Audio files secured in private bucket
- ✅ **API Key Security** - OpenAI key hidden in Edge Function
- ✅ **Token Management** - Supabase handles JWT tokens
- ✅ **Input Validation** - All user inputs validated

---

## 🧪 Testing

### Manual Testing Checklist
See [CHECKLIST.md](CHECKLIST.md) for complete testing checklist.

**Core Features:**
- [ ] Sign up / Sign in / Sign out
- [ ] Record voice note
- [ ] View notes list
- [ ] Transcribe recording
- [ ] Generate SWOT analysis

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICK_START.md](QUICK_START.md) | Get started in 5 minutes |
| [SETUP.md](SETUP.md) | Comprehensive setup guide |
| [CHECKLIST.md](CHECKLIST.md) | Step-by-step implementation checklist |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | What was built and how |
| [DEPENDENCIES.md](DEPENDENCIES.md) | Package dependencies explained |

---

## 🎓 What You'll Learn

Building this project teaches:
- SwiftUI best practices
- MVVM architecture in SwiftUI
- Audio recording with AVFoundation
- Speech recognition integration
- Supabase backend integration
- AI API integration
- Async/await patterns
- Permission handling
- Error handling strategies

---

## 🛠️ Development

### Requirements
- macOS 14+ (Sonoma)
- Xcode 16+
- Swift 6.0+
- iOS 17+ deployment target

### Dependencies
- [Supabase Swift](https://github.com/supabase/supabase-swift) (2.x)

### Build & Run
```bash
# Open project
open Abimo.xcodeproj

# In Xcode:
# 1. Select target device
# 2. Press ⌘R to build and run
```

---

## 🐛 Troubleshooting

### Common Issues

**"No such module 'Supabase'"**
- Add Supabase package via Xcode > Add Package Dependencies

**Permission Denied Errors**
- Add Info.plist permissions (see SETUP.md)

**Supabase Connection Errors**
- Verify URL and key in SupabaseService.swift
- Check Supabase project is not paused

**Recording Fails**
- Test on physical device (simulator limitations)
- Grant microphone permission

See [SETUP.md](SETUP.md) for detailed troubleshooting.

---

## 📈 Roadmap

### Current Version (v1.0)
- ✅ Voice recording
- ✅ Speech-to-text transcription
- ✅ AI SWOT analysis
- ✅ User authentication
- ✅ Cloud storage

### Planned Features
- [ ] Audio playback
- [ ] Apple Sign In UI
- [ ] Note editing
- [ ] Export as PDF
- [ ] Search functionality
- [ ] Folders/tags
- [ ] Offline mode
- [ ] iPad optimization
- [ ] Dark mode enhancements

---

## 🤝 Contributing

This is a learning project! Feel free to:
- Fork and experiment
- Submit issues
- Suggest improvements
- Share what you build

---

## 📄 License

MIT License - Feel free to use this project however you want!

---

## 🙏 Acknowledgments

- **Supabase** - Amazing backend-as-a-service
- **OpenAI** - Powerful AI analysis
- **Apple** - SwiftUI & Speech frameworks
- **Claude** - AI pair programmer that helped build this

---

## 💡 Use Cases

Perfect for:
- 📱 Entrepreneurs capturing business ideas on-the-go
- 🎓 Students analyzing business concepts
- 💼 Consultants quickly evaluating opportunities
- 🚀 Startup founders validating ideas
- 📊 Business analysts creating rapid assessments

---

## 🎯 Project Status

**Status**: ✅ Complete & Ready for Configuration

**What's Done**:
- ✅ All code written (21 files, ~2,500 lines)
- ✅ MVVM architecture implemented
- ✅ Full documentation provided
- ✅ Error handling throughout
- ✅ UI/UX polished

**What's Needed**:
- ⚙️ Supabase backend setup
- ⚙️ OpenAI API key configuration
- ⚙️ Xcode project configuration
- ⚙️ Info.plist permissions

**Time to Complete Setup**: 15-30 minutes

---

## 📞 Support

Need help?
1. Check [SETUP.md](SETUP.md) for detailed instructions
2. Review [CHECKLIST.md](CHECKLIST.md) for step-by-step guide
3. Look at Xcode console for error messages
4. Verify Supabase configuration in dashboard

---

## ⭐ Show Your Support

If this project helped you learn or build something cool:
- ⭐ Star the repository
- 🐦 Share on social media
- 📝 Write about your experience
- 🤝 Contribute improvements

---

## 🔗 Links

- [Supabase Documentation](https://supabase.com/docs)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Speech Framework](https://developer.apple.com/documentation/speech)
- [AVFoundation](https://developer.apple.com/av-foundation/)

---

**Built with ❤️ using SwiftUI and Claude Code**

*Ready to turn voice into insights!* 🚀
