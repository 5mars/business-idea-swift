//
//  PermissionsManager.swift
//  Abimo
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
class PermissionsManager: ObservableObject {
    @Published var microphoneAuthorized = false
    @Published var speechRecognitionAuthorized = false

    init() {
        checkPermissions()
    }

    func checkPermissions() {
        // Check microphone
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphoneAuthorized = true
        case .denied, .undetermined:
            microphoneAuthorized = false
        @unknown default:
            microphoneAuthorized = false
        }

        // Check speech recognition
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionAuthorized = true
        case .denied, .restricted, .notDetermined:
            speechRecognitionAuthorized = false
        @unknown default:
            speechRecognitionAuthorized = false
        }
    }

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    self.microphoneAuthorized = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    let authorized = status == .authorized
                    self.speechRecognitionAuthorized = authorized
                    continuation.resume(returning: authorized)
                }
            }
        }
    }

    func requestAllPermissions() async -> Bool {
        let micGranted = await requestMicrophonePermission()
        let speechGranted = await requestSpeechRecognitionPermission()
        return micGranted && speechGranted
    }
}
