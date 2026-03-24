//
//  FillerWordCleaner.swift
//  wispr
//
//  Removes common filler words from transcribed text.
//  Supports English and French fillers.
//

import Foundation

enum FillerWordCleaner {

    // The core filler alternation, shared by both patterns.
    // English: um, uh, ah, oh, eh, er, erm, hmm, hm, mhm, uh-huh
    // French:  euh, heu, hein, bah, ben, beh, pfff+, mouais
    private static let fillerAlternation =
        #"um|uh|ah|oh|eh|er|erm|hmm|hm|mhm|uh[\-\u2010\u2011\u2012\u2013\u2014]huh|euh|heu|hein|bah|ben|beh|pf{2,}|mouais"#

    /// Matches a filler word together with surrounding punctuation and whitespace.
    ///
    /// Three cases handled (in order):
    /// 1. Filler between punctuation: ", um," → removes filler + one separator  
    /// 2. Filler with trailing/leading punct+space: "um, " or " ,um"
    /// 3. Bare filler with surrounding spaces: " um " → single space
    private static let fillerWithContextPattern: Regex<AnyRegexOutput> = {
        try! Regex(
            #"[,;:]\s*\b(?:"# + fillerAlternation + #")\b\s*(?=[,;:])"#  // case 1: between punctuation
            + #"|"#
            + #"\s*\b(?:"# + fillerAlternation + #")\b[,;:]?\s*"#        // case 2 & 3: filler with optional trailing punct
        ).ignoresCase()
    }()

    /// Regex matching runs of two or more spaces.
    private static let multiSpacePattern: Regex<Substring> = {
        try! Regex(#" {2,}"#)
    }()

    /// Removes filler words from the given text and collapses leftover whitespace.
    ///
    /// Also cleans up surrounding punctuation so "Well, um, I think so"
    /// becomes "Well, I think so" rather than "Well, , I think so".
    ///
    /// - Parameter text: Raw transcription text.
    /// - Returns: Cleaned text with filler words removed.
    static func clean(_ text: String) -> String {
        let stripped = text.replacing(fillerWithContextPattern, with: " ")
        let collapsed = stripped.replacing(multiSpacePattern, with: " ")
        return collapsed.trimmingCharacters(in: .whitespaces)
    }
}
