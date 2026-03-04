//
//  NoteDetailView.swift
//  note-ai-app-test
//

import SwiftUI
import AVFoundation

struct NoteDetailView: View {
    let note: VoiceNote

    @StateObject private var transcriptionService = TranscriptionService()
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var transcription: Transcription?
    @State private var isLoadingTranscription = false
    @State private var showingSWOTAnalysis = false
    @State private var errorMessage: String?
    @State private var editedTranscriptionText = ""
    @State private var isEditingTranscript = false
    @State private var hasUnsavedChanges = false
    @State private var swotAnalysis: SWOTAnalysis?
    @State private var isLoadingSWOT = false
    @State private var noteTitle: String
    @State private var editedTitle = ""
    @State private var isEditingTitle = false

    private let supabase = SupabaseService.shared

    init(note: VoiceNote) {
        self.note = note
        _noteTitle = State(initialValue: note.title)
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Note header card
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient.brand)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.brand.opacity(0.35), radius: 10, x: 0, y: 4)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        if isEditingTitle {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Idea name", text: $editedTitle)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.textPri)
                                    .tint(.brand)
                                    .submitLabel(.done)
                                    .onSubmit { Task { await saveTitleEdit() } }

                                HStack {
                                    Button("Cancel") {
                                        isEditingTitle = false
                                    }
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textSec)

                                    Spacer()

                                    Button {
                                        Task { await saveTitleEdit() }
                                    } label: {
                                        Text("Save")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.brand)
                                            .cornerRadius(10)
                                    }
                                    .disabled(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }
                            Spacer()
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(noteTitle)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.textPri)
                                    .lineLimit(2)

                                HStack(spacing: 12) {
                                    Label(formatDuration(note.duration), systemImage: "clock")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.brand.opacity(0.8))

                                    Text(note.createdAt, style: .date)
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSec)
                                }
                            }
                            Spacer()

                            Button {
                                editedTitle = noteTitle
                                isEditingTitle = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.brand)
                                    .padding(8)
                                    .background(Color.brand.opacity(0.08))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .cardStyle()

                    // Audio playback card
                    VStack(spacing: 16) {
                        HStack {
                            Text("Playback")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.textPri)
                            Spacer()
                        }

                        HStack(spacing: 16) {
                            Button {
                                Task { await togglePlayback() }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.brand)
                                        .frame(width: 52, height: 52)
                                        .shadow(color: Color.brand.opacity(0.35), radius: 8, x: 0, y: 4)

                                    if audioPlayer.isLoading {
                                        ProgressView().tint(.white).scaleEffect(0.8)
                                    } else {
                                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .offset(x: audioPlayer.isPlaying ? 0 : 2)
                                    }
                                }
                            }
                            .disabled(audioPlayer.isLoading)

                            VStack(spacing: 8) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.brand.opacity(0.1))
                                            .frame(height: 6)

                                        Capsule()
                                            .fill(LinearGradient.brand)
                                            .frame(
                                                width: max(6, geo.size.width * CGFloat(audioPlayer.progress)),
                                                height: 6
                                            )
                                    }
                                }
                                .frame(height: 6)

                                HStack {
                                    Text(formatDuration(audioPlayer.currentTime))
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.textSec)

                                    Spacer()

                                    Text(formatDuration(note.duration))
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.textSec)
                                }
                            }
                        }
                    }
                    .cardStyle()

                    // Transcription card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brand.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "text.bubble.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.brand)
                                }
                                Text("Transcription")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPri)
                            }

                            Spacer()

                            if transcription != nil && !isEditingTranscript {
                                Button {
                                    isEditingTranscript = true
                                    editedTranscriptionText = transcription?.text ?? ""
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.brand)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brand.opacity(0.08))
                                        .cornerRadius(20)
                                }
                            }
                        }

                        if isLoadingTranscription {
                            HStack(spacing: 10) {
                                ProgressView().tint(.brand).scaleEffect(0.9)
                                Text("Transcribing with Whisper AI...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSec)
                            }
                            .padding(.vertical, 8)
                        } else if let transcription = transcription {
                            if isEditingTranscript {
                                TextEditor(text: $editedTranscriptionText)
                                    .frame(minHeight: 150)
                                    .padding(12)
                                    .background(Color.brand.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brand.opacity(0.35), lineWidth: 1.5)
                                    )
                                    .font(.system(size: 15))
                                    .tint(.brand)
                                    .onChange(of: editedTranscriptionText) { oldValue, newValue in
                                        hasUnsavedChanges = newValue != transcription.text
                                    }

                                HStack {
                                    Button("Cancel") {
                                        isEditingTranscript = false
                                        hasUnsavedChanges = false
                                        editedTranscriptionText = transcription.text
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.textSec)

                                    Spacer()

                                    Button {
                                        Task { await saveTranscriptionEdit() }
                                    } label: {
                                        Text("Save Changes")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 9)
                                            .background(hasUnsavedChanges ? Color.brand : Color.gray.opacity(0.3))
                                            .cornerRadius(12)
                                    }
                                    .disabled(!hasUnsavedChanges)
                                }
                            } else {
                                Text(transcription.text)
                                    .font(.system(size: 15))
                                    .foregroundColor(.textPri)
                                    .lineSpacing(4)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.brand.opacity(0.04))
                                    .cornerRadius(12)

                                // SWOT section — auto-shows preview if already stored
                                if let analysis = swotAnalysis {
                                    SWOTPreviewCard(analysis: analysis)
                                        .onTapGesture { showingSWOTAnalysis = true }
                                } else if isLoadingSWOT {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(.brand).scaleEffect(0.8)
                                        Text("Loading analysis...")
                                            .font(.system(size: 13))
                                            .foregroundColor(.textSec)
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    GradientButton(
                                        title: "Generate SWOT Analysis",
                                        gradient: LinearGradient(
                                            colors: [.brand, .brandLight],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    ) {
                                        showingSWOTAnalysis = true
                                    }
                                }
                            }
                        } else {
                            VStack(spacing: 14) {
                                Text("No transcription yet")
                                    .font(.system(size: 15))
                                    .foregroundColor(.textSec)
                                    .italic()

                                GradientButton(title: "Transcribe Audio") {
                                    Task { await loadTranscription() }
                                }
                            }
                        }
                    }
                    .cardStyle()

                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                            Text(error)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.brandRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Recording Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .sheet(isPresented: $showingSWOTAnalysis) {
            if let transcription = transcription {
                SWOTAnalysisView(transcription: transcription, preloadedAnalysis: swotAnalysis)
            }
        }
        .task {
            await loadTranscription()
            if let t = transcription {
                Task { await loadSWOTAnalysis(transcriptionId: t.id) }
            }
        }
        .onDisappear { audioPlayer.stop() }
    }

    // MARK: - Private Methods

    private func togglePlayback() async {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            if audioPlayer.audioURL == nil {
                do {
                    let localURL = try await supabase.downloadAudioFile(filePath: note.audioFileURL)
                    try await audioPlayer.prepare(url: localURL)
                    audioPlayer.play()
                } catch {
                    errorMessage = "Failed to load audio: \(error.localizedDescription)"
                }
            } else {
                audioPlayer.play()
            }
        }
    }

    private func loadTranscription() async {
        isLoadingTranscription = true
        errorMessage = nil
        defer { isLoadingTranscription = false }

        do {
            if let existing = try await supabase.fetchTranscription(noteId: note.id) {
                transcription = existing
                editedTranscriptionText = existing.text
                return
            }

            let signedURL = try await supabase.getSignedAudioURL(filePath: note.audioFileURL, expiresIn: 3600)
            let transcriptionText = try await transcriptionService.transcribeWithWhisper(storageURL: signedURL)

            let newTranscription = Transcription(
                id: UUID(),
                noteId: note.id,
                text: transcriptionText,
                language: "en",
                confidence: nil,
                createdAt: Date()
            )

            try await supabase.createTranscription(newTranscription)
            transcription = newTranscription
            editedTranscriptionText = transcriptionText
        } catch {
            errorMessage = "Failed to transcribe: \(error.localizedDescription)"
        }
    }

    private func loadSWOTAnalysis(transcriptionId: UUID) async {
        isLoadingSWOT = true
        defer { isLoadingSWOT = false }
        swotAnalysis = try? await supabase.fetchSWOTAnalysis(transcriptionId: transcriptionId)
    }

    private func saveTitleEdit() async {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try await supabase.updateVoiceNoteTitle(id: note.id, title: trimmed)
            noteTitle = trimmed
            isEditingTitle = false
        } catch {
            errorMessage = "Failed to save title: \(error.localizedDescription)"
        }
    }

    private func saveTranscriptionEdit() async {
        guard let transcription = transcription else { return }

        do {
            let updatedTranscription = Transcription(
                id: transcription.id,
                noteId: transcription.noteId,
                text: editedTranscriptionText,
                language: transcription.language,
                confidence: transcription.confidence,
                createdAt: transcription.createdAt
            )
            try await supabase.updateTranscription(updatedTranscription)
            self.transcription = updatedTranscription
            isEditingTranscript = false
            hasUnsavedChanges = false
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - SWOT Preview Card

struct SWOTPreviewCard: View {
    let analysis: SWOTAnalysis

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.brand)
                        Text("SWOT Analysis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPri)
                    }
                    Text("Tap to view full analysis")
                        .font(.system(size: 12))
                        .foregroundColor(.textSec)
                }

                Spacer()

                if let score = analysis.viabilityScore {
                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(viabilityColor(score))
                        Text("Viability")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textSec)
                    }
                }
            }

            // S / W / O / T count row
            HStack(spacing: 0) {
                quadrantCount("S", count: analysis.resolvedStrengths.count, color: .brandGreen)
                quadrantCount("W", count: analysis.resolvedWeaknesses.count, color: .brandRed)
                quadrantCount("O", count: analysis.resolvedOpportunities.count, color: .brandBlue)
                quadrantCount("T", count: analysis.resolvedThreats.count, color: .brandOrange)
            }
            .padding(.vertical, 8)
            .background(Color.brand.opacity(0.04))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: Color.brand.opacity(0.10), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brand.opacity(0.12), lineWidth: 1)
        )
    }

    private func quadrantCount(_ letter: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(letter)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textSec)
        }
        .frame(maxWidth: .infinity)
    }

    private func viabilityColor(_ score: Int) -> Color {
        switch score {
        case 0..<40:  return .brandRed
        case 40..<60: return .brandOrange
        case 60..<80: return .brandAmber
        default:      return .brandGreen
        }
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(note: VoiceNote(
            id: UUID(),
            userId: UUID(),
            title: "Sample Recording",
            audioFileURL: "https://example.com/audio.m4a",
            duration: 125.5,
            createdAt: Date(),
            updatedAt: Date(),
            transcriptionId: nil,
            analysisId: nil
        ))
    }
}
