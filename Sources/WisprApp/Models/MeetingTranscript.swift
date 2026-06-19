//
//  MeetingTranscript.swift
//  wispr
//
//  Data model for meeting transcription entries with speaker labels.
//

import Foundation

/// Identifies the audio source / speaker in a meeting transcript.
///
/// Speaker indices are stored **0-based** internally. The +1 transform to
/// "Speaker 1", "Speaker 2", etc. happens only inside `displayName`.
enum MeetingSpeaker: Sendable, Equatable, Hashable {
    case you
    /// Remote participant. `speakerIndex` is nil during Sortformer's cold-start
    /// window or when diarization is disabled — renders as plain "Others".
    case others(speakerIndex: Int?)

    /// User-visible label for transcript display and plain-text export.
    var displayName: String {
        switch self {
        case .you: return "You"
        case .others(.none): return "Others"
        case .others(.some(let index)): return "Speaker \(index + 1)"
        }
    }
}

/// A single timestamped entry in a meeting transcript.
struct MeetingTranscriptEntry: Identifiable, Sendable, Equatable {
    let id: UUID
    let speaker: MeetingSpeaker
    let text: String
    let timestamp: Date

    init(speaker: MeetingSpeaker, text: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
    }
}

/// The full transcript of a meeting session.
struct MeetingTranscript: Sendable, Equatable {
    var entries: [MeetingTranscriptEntry] = []
    let startTime: Date

    init(startTime: Date = Date()) {
        self.startTime = startTime
    }

    /// Shared time formatter for transcript display (HH:mm:ss).
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Formats a date as HH:mm:ss for transcript display.
    static func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Formats the entire transcript as plain text for export.
    func asPlainText() -> String {
        entries.map { entry in
            let time = Self.formatTime(entry.timestamp)
            return "[\(time)] \(entry.speaker.displayName): \(entry.text)"
        }.joined(separator: "\n")
    }

    /// Duration of the meeting so far.
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    /// Formatted duration string (e.g. "12:34").
    var formattedDuration: String {
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
