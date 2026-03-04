//
//  TranscriptionService.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import Speech
import Combine
import Supabase

@MainActor
class TranscriptionService: ObservableObject {
    @Published var transcriptionText: String = ""
    @Published var isTranscribing = false
    @Published var progress: Double = 0.0

    private let supabase = SupabaseService.shared

    // For Whisper: pass the Supabase storage URL string directly
    func transcribeWithWhisper(storageURL: String) async throws -> String {
        isTranscribing = true
        transcriptionText = ""
        progress = 0.0
        defer { isTranscribing = false }

        print("📤 Calling Edge Function with URL: \(storageURL)")

        struct WhisperResponse: Codable {
            let text: String
        }

        struct WhisperRequest: Encodable {
            let audioUrl: String
        }

        let request = WhisperRequest(audioUrl: storageURL)
        print("📦 Request body: \(request)")

        let response: WhisperResponse = try await supabase.client.functions
            .invoke(
                "transcribe-audio",
                options: FunctionInvokeOptions(
                    body: request
                )
            )

        transcriptionText = response.text
        progress = 1.0
        return response.text
    }

    // For local Speech Recognition: pass a local file URL
    func transcribe(audioURL: URL, useWhisper: Bool = true) async throws -> String {
        isTranscribing = true
        transcriptionText = ""
        progress = 0.0
        defer { isTranscribing = false }

        return try await transcribeWithSpeechRecognizer(audioURL: audioURL)
    }

    private func transcribeWithSpeechRecognizer(audioURL: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw NSError(domain: "TranscriptionService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }

        guard recognizer.isAvailable else {
            throw NSError(domain: "TranscriptionService", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        return try await withCheckedThrowingContinuation { continuation in
            var finalTranscription: String?

            recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = result else { return }

                Task { @MainActor in
                    self?.transcriptionText = result.bestTranscription.formattedString
                    self?.progress = result.isFinal ? 1.0 : 0.5
                }

                if result.isFinal {
                    finalTranscription = result.bestTranscription.formattedString
                    continuation.resume(returning: finalTranscription!)
                }
            }
        }
    }
}
