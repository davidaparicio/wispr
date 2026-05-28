# PR #63 — Meeting Transcriber: Review & Fixes Status

**PR:** https://github.com/sebsto/wispr/pull/63
**Contributor:** Gabriel Bruno (@gbrunoo)
**Reviewed on:** 2026-05-13
**Local branch:** `meeting-transcriber-fixes` (based on the PR's `meeting-transcriber` branch)

## Status

All review fixes were implemented locally AND communicated to the contributor to apply themselves.
**This local branch will likely NOT be needed** — the contributor was asked to make all changes.

---

## Fixes Applied on `meeting-transcriber-fixes`

All fixes compile (`BUILD SUCCEEDED`) and meeting-related tests pass.

### Fix 1 — UB: dangling pointer (CRITICAL)
**File:** `wispr/Services/MeetingAudioEngine.swift` — `SystemAudioOutputHandler.stream(_:didOutputSampleBuffer:of:)`

`withMemoryRebound` returned a pointer used outside its closure (undefined behavior). Fixed to create the Array inside the closure:
```swift
// Before (UB):
let samples = Array(UnsafeBufferPointer(
    start: data.withMemoryRebound(to: Float.self, capacity: floatCount) { $0 },
    count: floatCount))

// After:
let samples = data.withMemoryRebound(to: Float.self, capacity: floatCount) { ptr in
    Array(UnsafeBufferPointer(start: ptr, count: floatCount))
}
```

### Fix 2 — Unnecessary nil coalescing (compiler warning)
**File:** `wispr/Services/MeetingStateManager.swift` — `runTimer()`

`formattedDuration` returns `String` (non-optional). Removed `?? "0:00"`.

### Fix 3 — Unused @State property
**File:** `wispr/UI/Meeting/MeetingTranscriptView.swift`

Removed `@State private var scrollProxy: ScrollViewProxy?` (declared but never written to).

### Fix 4 — DateFormatter allocation in hot path
**Files:** `wispr/Models/MeetingTranscript.swift`, `wispr/UI/Meeting/MeetingTranscriptView.swift`

Replaced per-call `DateFormatter()` with `private static let timeFormatter` in both locations.

### Fix 5 — Useless `[weak self]` in tap closure
**File:** `wispr/Services/MeetingAudioEngine.swift` — `startMicCapture()`

Removed `[weak self]` + `guard self != nil` from mic tap closure. `self` was never used in the closure body — only `bridgeContinuation` is captured directly.

### Fix 6 — Dead code removal
**File:** `wispr/Services/PermissionManager.swift`

Removed `checkScreenRecordingPermission()` (added but never called anywhere) and the now-unused `import ScreenCaptureKit`.

### Fix 7 — SFSymbols centralization
**Files:** `wispr/Utilities/SFSymbols.swift`, `wispr/UI/Meeting/MeetingTranscriptView.swift`

Added `stopFill` and `waveform` to the central `SFSymbols` enum. Removed the private extension that duplicated existing constants (`clipboard` was same as `SFSymbols.copy`, `waveform` already existed as `providerWhisper`/`onboardingTestDictation`).

---

## Additional Feedback Given to Contributor (NOT implemented locally)

### NSSavePanel crash → Replace with SwiftUI `.fileExporter()`

`MeetingStateManager.exportTranscript()` uses `NSSavePanel` which crashes because:
1. No file-access entitlements in the app
2. Focus/activation issues in `.accessory` (menu-bar-only) apps

**Recommendation:** Replace with SwiftUI `.fileExporter()` view modifier on `MeetingTranscriptView`:

```swift
struct TranscriptDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.plainText]
    let text: String

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        text = String(decoding: data, as: UTF8.self)
    }

    init(text: String) { self.text = text }
}

// In MeetingTranscriptView:
@State private var isExporting = false

Button("Export") { isExporting = true }
.fileExporter(
    isPresented: $isExporting,
    document: TranscriptDocument(text: meetingState.transcript.asPlainText()),
    contentType: .plainText,
    defaultFilename: "meeting-transcript"
) { result in
    if case .failure(let error) = result {
        Log.stateManager.error("Export failed: \(error.localizedDescription)")
    }
}
```

This removes `exportTranscript()` from `MeetingStateManager` entirely. No entitlements needed.

---

## Merge Strategy (when PR is ready)

### Step 1 — Merge the PR with a merge commit (preserves contributor credit):
```bash
gh pr merge 63 --merge
```
`--merge` (NOT `--squash`) keeps all of Gabriel's commits with his authorship in git log and GitHub contribution graph.

### Step 2 — If any fixes remain unapplied after merge, apply on main:
```bash
git checkout main
git pull
# cherry-pick or re-apply remaining fixes
git push
```

Or open a small follow-up PR targeting main for audit trail.

### Key Point
Using `--merge` preserves each original commit's author field. Gabriel gets full credit.

---

## Pre-existing Test Failures (unrelated to this PR)

- `TextCorrectionTokenLeakTests/testMinimalStyleTokenLeak` — fails independently of meeting transcription changes
- `MeetingStateManagerTests` has 2-3 flaky tests due to `handleError` auto-dismissing after 5s racing with assertions — pre-existing in the PR, not caused by our fixes

---

## Cleanup (after PR is merged)

```bash
git checkout main
git branch -D meeting-transcriber-fixes
git branch -D meeting-transcriber
rm pr-review-status.md
```
