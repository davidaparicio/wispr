//
//  FillerWordCleanerTests.swift
//  wispr
//
//  Unit tests for FillerWordCleaner utility.
//

import Testing
import Foundation
@testable import wispr

@Suite("FillerWordCleaner Tests")
struct FillerWordCleanerTests {

    // MARK: - Basic Filler Removal

    @Test("Removes 'um' from text")
    func testRemovesUm() {
        #expect(FillerWordCleaner.clean("I um think so") == "I think so")
    }

    @Test("Removes 'uh' from text")
    func testRemovesUh() {
        #expect(FillerWordCleaner.clean("uh I think so") == "I think so")
    }

    @Test("Removes 'ah' from text")
    func testRemovesAh() {
        #expect(FillerWordCleaner.clean("ah that's right") == "that's right")
    }

    @Test("Removes 'er' from text")
    func testRemovesEr() {
        #expect(FillerWordCleaner.clean("I er need help") == "I need help")
    }

    @Test("Removes 'erm' from text")
    func testRemovesErm() {
        #expect(FillerWordCleaner.clean("erm let me think") == "let me think")
    }

    @Test("Removes 'hmm' from text")
    func testRemovesHmm() {
        #expect(FillerWordCleaner.clean("hmm interesting") == "interesting")
    }

    @Test("Removes 'hm' from text")
    func testRemovesHm() {
        #expect(FillerWordCleaner.clean("hm okay") == "okay")
    }

    @Test("Removes 'mhm' from text")
    func testRemovesMhm() {
        #expect(FillerWordCleaner.clean("mhm I agree") == "I agree")
    }

    @Test("Removes 'uh-huh' from text")
    func testRemovesUhHuh() {
        #expect(FillerWordCleaner.clean("uh-huh that works") == "that works")
    }

    // MARK: - French Filler Removal

    @Test("Removes 'euh' from text")
    func testRemovesEuh() {
        #expect(FillerWordCleaner.clean("je euh pense que oui") == "je pense que oui")
    }

    @Test("Removes 'heu' from text")
    func testRemovesHeu() {
        #expect(FillerWordCleaner.clean("heu attends") == "attends")
    }

    @Test("Removes 'hein' from text")
    func testRemovesHein() {
        #expect(FillerWordCleaner.clean("c'est bien hein") == "c'est bien")
    }

    @Test("Removes 'bah' from text")
    func testRemovesBah() {
        #expect(FillerWordCleaner.clean("bah oui c'est ça") == "oui c'est ça")
    }

    @Test("Removes 'ben' from text")
    func testRemovesBen() {
        #expect(FillerWordCleaner.clean("ben je sais pas") == "je sais pas")
    }

    @Test("Removes 'beh' from text")
    func testRemovesBeh() {
        #expect(FillerWordCleaner.clean("beh voilà") == "voilà")
    }

    @Test("Removes 'pfff' and variants from text")
    func testRemovesPfff() {
        #expect(FillerWordCleaner.clean("pfff c'est compliqué") == "c'est compliqué")
        #expect(FillerWordCleaner.clean("pfffff vraiment") == "vraiment")
    }

    @Test("Removes 'mouais' from text")
    func testRemovesMouais() {
        #expect(FillerWordCleaner.clean("mouais peut-être") == "peut-être")
    }

    @Test("Removes 'oh' from text")
    func testRemovesOh() {
        #expect(FillerWordCleaner.clean("oh je vois") == "je vois")
    }

    @Test("Removes 'eh' from text")
    func testRemovesEh() {
        #expect(FillerWordCleaner.clean("eh bien sûr") == "bien sûr")
    }

    @Test("Removes multiple French fillers in one sentence")
    func testMultipleFrenchFillers() {
        #expect(FillerWordCleaner.clean("euh je heu pense que bah oui") == "je pense que oui")
    }

    @Test("Removes mixed English and French fillers")
    func testMixedEnglishFrenchFillers() {
        #expect(FillerWordCleaner.clean("um euh I think heu so") == "I think so")
    }

    @Test("Does not remove French filler patterns inside real words")
    func testFrenchWordBoundaries() {
        #expect(FillerWordCleaner.clean("benne") == "benne")
        #expect(FillerWordCleaner.clean("bahut") == "bahut")
        #expect(FillerWordCleaner.clean("heure") == "heure")
    }

    @Test("Returns empty string when input is only French fillers")
    func testOnlyFrenchFillers() {
        #expect(FillerWordCleaner.clean("euh heu bah") == "")
    }

    // MARK: - Case Insensitivity

    @Test("Removes filler words regardless of case")
    func testCaseInsensitive() {
        #expect(FillerWordCleaner.clean("UM I think UH so") == "I think so")
        #expect(FillerWordCleaner.clean("Um yeah Uh-Huh") == "yeah")
    }

    // MARK: - Multiple Fillers

    @Test("Removes multiple filler words in one sentence")
    func testMultipleFillers() {
        #expect(FillerWordCleaner.clean("um I uh think er it works") == "I think it works")
    }

    // MARK: - Word Boundary Respect

    @Test("Does not remove filler patterns inside real words")
    func testWordBoundaries() {
        #expect(FillerWordCleaner.clean("umbrella") == "umbrella")
        #expect(FillerWordCleaner.clean("hummer") == "hummer")
        #expect(FillerWordCleaner.clean("errand") == "errand")
        #expect(FillerWordCleaner.clean("thermal") == "thermal")
    }

    // MARK: - Whitespace Handling

    @Test("Collapses extra spaces left after removal")
    func testCollapsesSpaces() {
        let result = FillerWordCleaner.clean("I  um  think  uh  so")
        #expect(result == "I think so")
    }

    @Test("Trims leading and trailing whitespace")
    func testTrimsWhitespace() {
        #expect(FillerWordCleaner.clean("um hello") == "hello")
        #expect(FillerWordCleaner.clean("hello um") == "hello")
    }

    // MARK: - Edge Cases

    @Test("Returns empty string when input is only filler words")
    func testOnlyFillers() {
        #expect(FillerWordCleaner.clean("um uh er") == "")
    }

    @Test("Returns empty string for empty input")
    func testEmptyInput() {
        #expect(FillerWordCleaner.clean("") == "")
    }

    @Test("Returns text unchanged when no fillers present")
    func testNoFillers() {
        #expect(FillerWordCleaner.clean("Hello world") == "Hello world")
    }

    @Test("Cleans up filler between commas: 'Well, um, I think so'")
    func testFillerBetweenCommas() {
        #expect(FillerWordCleaner.clean("Well, um, I think so") == "Well, I think so")
    }

    @Test("Cleans up filler with trailing comma: 'um, I think so'")
    func testFillerWithTrailingComma() {
        #expect(FillerWordCleaner.clean("um, I think so") == "I think so")
    }

    @Test("Cleans up filler between semicolons")
    func testFillerBetweenSemicolons() {
        #expect(FillerWordCleaner.clean("first; uh; second") == "first; second")
    }

    @Test("Cleans up French filler between commas")
    func testFrenchFillerBetweenCommas() {
        #expect(FillerWordCleaner.clean("Bon, euh, je pense") == "Bon, je pense")
    }

    @Test("Preserves non-English text")
    func testNonEnglishText() {
        #expect(FillerWordCleaner.clean("こんにちは um 世界") == "こんにちは 世界")
    }

    @Test("Handles emoji in text")
    func testEmojiText() {
        #expect(FillerWordCleaner.clean("🎤 um hello 🌍") == "🎤 hello 🌍")
    }
}
