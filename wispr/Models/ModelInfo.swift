//
//  ModelInfo.swift
//  wispr
//
//  Created by Kiro
//

import Foundation
import SwiftUI

/// The ASR engine that provides a model.
enum ModelProvider: String, Sendable, Equatable, Hashable, CaseIterable {
    case whisper = "OpenAI Whisper"
    case nvidiaParakeet = "NVIDIA Parakeet"

    var icon: String {
        switch self {
        case .whisper: "waveform"
        case .nvidiaParakeet: "bird"
        }
    }

    var tintColor: Color {
        switch self {
        case .whisper: .blue
        case .nvidiaParakeet: .green
        }
    }
}

/// Information about a transcription model
struct ModelInfo: Identifiable, Sendable, Equatable {
    let id: String              // e.g. "tiny"
    let displayName: String     // e.g. "Tiny"
    let sizeDescription: String // e.g. "~75 MB"
    let qualityDescription: String // e.g. "Fastest, lower accuracy"
    let estimatedSize: Int64    // bytes, used for download progress
    var status: ModelStatus

    // MARK: - Known Model IDs

    enum KnownID {
        // Whisper
        nonisolated static let tiny = "tiny"
        nonisolated static let base = "base"
        nonisolated static let small = "small"
        nonisolated static let medium = "medium"
        nonisolated static let largeV3 = "large-v3"
        // Parakeet
        nonisolated static let parakeetV3 = "parakeet-v3"
        nonisolated static let parakeetEou = "parakeet-eou-160ms"
    }
}
