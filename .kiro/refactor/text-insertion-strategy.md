# Text Insertion Strategy — App Store Compliance

## Context

Apple rejected the app (Guideline 2.4.5) for using Accessibility APIs (AXUIElement) to insert transcribed text at the cursor position. Accessibility features must only be used for accessibility purposes.

## Current Implementation

`TextInsertionService.swift` uses two methods:
1. **Primary: AXUIElement** — reads focused text field, inserts text at cursor position
2. **Fallback: Clipboard + CGEvent ⌘V** — copies text to pasteboard, simulates ⌘V, restores clipboard after 2s

Both paths require the Accessibility permission in System Settings:
- AXUIElement APIs are gated behind Accessibility trust
- `CGEvent.post(tap: .cghidEventTap)` also requires Accessibility trust

Removing AXUIElement alone does NOT solve the rejection — simulated keystrokes have the same gate.

## Options

### Option A: Clipboard-only (user pastes manually)

Copy text to clipboard, show a brief "Copied — press ⌘V to paste" notification. No keystroke simulation.

**Pros:**
- No Accessibility permission needed at all
- No CGEvent, no AXUIElement
- Simpler onboarding (only microphone permission)
- 100% reliable in every app
- App Store compliant

**Cons:**
- Extra manual step (⌘V) every time
- Overwrites clipboard contents
- Less seamless — user flow becomes: hold hotkey → speak → release → ⌘V
- Competing dictation apps that use this approach get mediocre reviews specifically because of this friction

### Option B: Clipboard + simulated ⌘V (current fallback, minus AXUIElement)

**Pros:**
- Seamless — text appears at cursor automatically

**Cons:**
- Still requires Accessibility permission for CGEvent
- Apple will reject this for the same reason
- Overwrites clipboard temporarily

### Option C: Input Method Kit (IMKit)

Register as a macOS Input Source. This is how Apple's own dictation and professional tools insert text.

**Pros:**
- Designed exactly for this purpose
- No Accessibility permission
- Inserts at cursor natively
- App Store compliant
- Best UX — feels like native dictation

**Cons:**
- Fundamentally different architecture
- User must enable it in System Settings > Keyboard > Input Sources
- Significant implementation effort

### Option D: Two-track distribution

App Store version uses clipboard-only (Option A). Homebrew version keeps full Accessibility approach.

**Pros:**
- Best of both worlds
- App Store presence for discoverability
- Power users get the seamless Homebrew version

**Cons:**
- Two different UX paths to maintain
- App Store version feels inferior

## Recommendation

**Short term: Option D** — Ship the App Store version with clipboard-only (Option A) and keep the Homebrew version as-is. Minimal changes to get into the App Store.

**Long term: Option C (IMKit)** — The correct architecture for a dictation app. It's what Apple designed for this use case, requires no special permissions beyond microphone, and provides the most seamless experience. Eliminates the entire permission/rejection problem permanently.

## Implementation Notes (Option A)

- Remove `insertViaAccessibility` entirely
- Replace `insertViaClipboard` with a non-simulating clipboard copy
- Remove the Accessibility permission requirement from onboarding
- Show a brief overlay notification "Copied — ⌘V to paste" instead of auto-inserting
- Can be gated behind a compile-time flag (`#if APPSTORE`) to maintain both paths

## Implementation Notes (Option C — IMKit)

- Create an Input Method extension target
- Implement `IMKInputController` subclass
- Register input source in Info.plist
- User enables input source in System Settings > Keyboard > Input Sources
- Text insertion happens through `insertText(_:replacementRange:)` on `IMKTextInput`
- Research required: how to trigger dictation from a menu bar app while using IMKit for insertion
