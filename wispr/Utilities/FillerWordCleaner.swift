//
//  FillerWordCleaner.swift
//  wispr
//
//  Removes common filler words from transcribed text.
//  Supports English and French fillers.
//

import Foundation

enum FillerWordCleaner {

    /// Regex matching common filler words at word boundaries (case-insensitive).
    ///
    /// English: um, uh, ah, er, erm, hmm, hm, mhm, uh-huh
    /// French:  euh, heu, hein, bah, ben, beh, pfff, mouais, oh, eh
    private static let fillerPattern: Regex<Substring> = {
        try! Regex(
            #"\b(?:um|uh|ah|oh|eh|er|erm|hmm|hm|mhm|uh[\-\u2010\u2011\u2012\u2013\u2014]huh|euh|heu|hein|bah|ben|beh|pf{2,}|mouais)\b"#
        ).ignoresCase()
    }()

    /// Regex matching runs of two or more spaces.
    private static let multiSpacePattern: Regex<Substring> = {
        try! Regex(#" {2,}"#)
    }()

    /// Removes filler words from the given text and collapses leftover whitespace.
    ///
    /// - Parameter text: Raw transcription text.
    /// - Returns: Cleaned text with filler words removed.
    static func clean(_ text: String) -> String {
        let stripped = text.replacing(fillerPattern, with: "")
        let collapsed = stripped.replacing(multiSpacePattern, with: " ")
        return collapsed.trimmingCharacters(in: .whitespaces)
    }
}
