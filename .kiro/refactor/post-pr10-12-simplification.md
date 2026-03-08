# Post-PR #10-#12 Simplification Refactor Plan

Cleanup and consolidation work identified after merging PRs #10 (storage location), #11 (model management refactor), and #12 (default Parakeet download).

---

## Dependency Graph

```
WI-1 (SFSymbols)          --- No deps --- parallel batch 1
WI-2 (KnownID aliases)    --- No deps --- parallel batch 1
WI-4 (onCancel cleanup)   --- No deps --- parallel batch 1
WI-5 (preview indices)    --- No deps --- parallel batch 1

WI-3 (ModelPaths)         --- depends on WI-2 --- sequential
WI-6 (download unify)     --- depends on WI-3 + WI-4 --- sequential
```

**Parallel batch 1:** WI-1, WI-2, WI-4, WI-5 (all independent)
**Sequential after batch 1:** WI-3 (after WI-2)
**Sequential after WI-3 + WI-4:** WI-6

---

## WI-1: Complete SFSymbols Centralization

**Goal:** Move the last two inline SF Symbol strings (`"waveform"` for Whisper provider, `"bird"` for Parakeet provider) into `SFSymbols.swift`.

**Dependencies:** None

**Files to modify:**
- `wispr/Utilities/SFSymbols.swift`
- `wispr/UI/ModelManagementView.swift`

**Steps:**

- [ ] In `SFSymbols.swift`, add a new `// MARK: - Provider Icons` section after the Model Status Icons block (after line 128):
  ```swift
  static let providerWhisper = "waveform"
  static let providerParakeet = "bird"
  ```
- [ ] In `ModelManagementView.swift`, update `ModelProvider.icon` (lines 15-19) to return `SFSymbols.providerWhisper` / `SFSymbols.providerParakeet` instead of inline strings
- [ ] Grep for any other inline uses of `"bird"` as an SF Symbol string and replace
- [ ] Leave `SFSymbols.menuBarProcessing` ("waveform") and `SFSymbols.onboardingTestDictation` ("waveform") alone -- different semantic purpose
- [ ] Also fix the inline `"checkmark"` on `OnboardingModelSelectionStep.swift` line 87 -- should use `SFSymbols.checkmarkPlain`

---

## WI-2: Remove Redundant Local ID Aliases in ParakeetService

**Goal:** Eliminate `modelId` and `eouModelId` private constants that duplicate `ModelInfo.KnownID` values.

**Dependencies:** None

**Files to modify:**
- `wispr/Services/ParakeetService.swift`

**Steps:**

- [ ] Remove `private static let modelId` and `private static let eouModelId` declarations
- [ ] Replace all `Self.modelId` with `ModelInfo.KnownID.parakeetV3` throughout ParakeetService
- [ ] Replace all `Self.eouModelId` with `ModelInfo.KnownID.parakeetEou` throughout ParakeetService
- [ ] Verify `downloadedKey` and `eouDownloadedKey` UserDefaults keys are plain strings and need no change
- [ ] Grep for `ParakeetService.modelId` / `ParakeetService.eouModelId` -- confirm zero external references (they were `private static`)
- [ ] Build to verify

---

## WI-3: Consolidate Model Paths into ModelPaths

**Goal:** Make `ModelPaths` the single source of truth for all on-disk model directories.

**Dependencies:** WI-2 (changes ParakeetService references this also touches)

**Files to modify:**
- `wispr/Utilities/ModelPaths.swift`
- `wispr/Services/ParakeetService.swift`
- `wispr/Services/WhisperService.swift`

**Steps:**

- [ ] Add to `ModelPaths`:
  - `static var models: URL` -- `base/"models"`
  - `static var whisperModels: URL` -- `models/"argmaxinc"/"whisperkit-coreml"`
  - `static func parakeetV3(sdkLeafName: String) -> URL` -- `models/<sdkLeafName>` (caller passes `AsrModels.defaultCacheDirectory(for: .v3).lastPathComponent` to avoid coupling to FluidAudio)
  - `static var parakeetEou: URL` -- `models/"parakeet-eou-streaming"/"160ms"`
  - `static var parakeetEouParent: URL` -- `models`
- [ ] Update `WhisperService.getModelPath()` to use `ModelPaths.whisperModels` instead of inline path construction
- [ ] Remove from `ParakeetService`: `modelDownloadBase`, `v3CacheDirectory()`, `eouCacheDirectory()`, `eouModelsParentDirectory()`
- [ ] Replace all removed method calls with `ModelPaths` equivalents
- [ ] Build and verify paths resolve identically

---

## WI-4: Clean Up ModelDownloadProgressView.onCancel

**Goal:** Formalize the `onCancel` parameter (it IS used by ModelManagementView, so keep it but remove the default nil).

**Dependencies:** None

**Files to modify:**
- `wispr/UI/ModelDownloadProgressView.swift`

**Steps:**

- [ ] Remove the `= nil` default value from `onCancel` parameter in `ModelDownloadProgressView.init`
- [ ] Verify `OnboardingModelSelectionStep` already passes `nil` explicitly
- [ ] Verify `ModelManagementView` already passes a closure
- [ ] Verify preview-only initializer is unaffected (it hardcodes `self.onCancel = nil`)
- [ ] Build to verify

---

## WI-5: Fix Hardcoded Preview Indices

**Goal:** Replace fragile `sampleModels[2]` with named lookups.

**Dependencies:** None

**Files to modify:**
- `wispr/UI/ModelDownloadProgressView.swift`

**Steps:**

- [ ] In `ModelDownloadProgressView.swift` line 390, replace `PreviewMocks.sampleModels[2]` with `PreviewMocks.sampleModels.first { $0.id == ModelInfo.KnownID.small }!`
- [ ] Grep for `sampleModels\[` to find any other hardcoded index access and fix
- [ ] Build and verify previews render

---

## WI-6: Unify Download Coordination Between Onboarding and ModelManagement

**Goal:** Reduce duplicated download orchestration logic.

**Dependencies:** WI-3, WI-4

**Files to modify:**
- `wispr/UI/Onboarding/OnboardingModelSelectionStep.swift`
- `wispr/UI/ModelManagementView.swift`
- `wispr/UI/ModelDownloadProgressView.swift`

**Steps:**

- [ ] Remove duplicate `completionView` from `OnboardingModelSelectionStep` (lines 85-98) -- let `ModelDownloadProgressView`'s built-in completion view handle success state
- [ ] Keep onboarding-specific context text ("Downloading Model" title/description)
- [ ] If `completionView` is kept for branding, at minimum replace `"checkmark"` with `SFSymbols.checkmarkPlain` (covered by WI-1)
- [ ] Add doc comment to `ModelDownloadProgressView` clarifying responsibility split:
  - It owns: download initiation, progress tracking, error display, retry, completion display
  - Parent owns: which model to download, app-level side effects on complete/cancel
- [ ] Test both flows end-to-end

---

## Summary

| Work Item | Parallel? | Complexity | Files |
|-----------|-----------|------------|-------|
| WI-1: SFSymbols | Yes | Low | 2-3 |
| WI-2: KnownID aliases | Yes | Low | 1 |
| WI-3: ModelPaths | After WI-2 | Medium | 3 |
| WI-4: onCancel cleanup | Yes | Low | 1 |
| WI-5: Preview indices | Yes | Low | 1 |
| WI-6: Download unification | After WI-3+WI-4 | Medium | 3 |
