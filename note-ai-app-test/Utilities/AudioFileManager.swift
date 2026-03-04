//
//  AudioFileManager.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import Foundation
import AVFoundation

class AudioFileManager {
    static func getDuration(of url: URL) -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        return asset.duration.seconds
    }

    static func deleteFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    static func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    static func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }

    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
