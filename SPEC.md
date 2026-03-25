# Still — Product Specification

## 1. Concept & Vision

**Still** is an evening wind-down ritual — a moment of intentional stillness before sleep. Each night, the app asks one gentle question, invites a short reflection, and quietly stores it. Not journaling. Not gratitude. Something deeper: naming the day on your own terms, in your own voice, before the world dissolves.

The experience should feel like a candlelit room, not a screen. Slow. Warm. Safe. The kind of dark that feels chosen, not empty.

---

## 2. Design Language

### Aesthetic Direction
**Dark sanctuary** — the UI recedes so the content breathes. Inspired by candlelight, old books, and the quiet hour before sleep. Not "night mode" productivity — this is a ritual space.

### Color Palette
| Role | Color | Hex |
|---|---|---|
| Background | Near-black warm | `#0D0B09` |
| Surface | Slightly lifted | `#1A1714` |
| Orb (primary) | Warm amber | `#E8A46A` |
| Orb (glow) | Soft amber glow | `#F4C594` |
| Text (primary) | Warm off-white | `#F5F0E8` |
| Text (secondary) | Muted warm gray | `#9B9385` |
| Accent | Deep amber | `#C47D3E` |
| Separator | Subtle warm | `#2A2520` |

### Typography
- **Display / Question text:** New York (Apple serif) — 24pt, medium weight, 1.4 line height
- **Body / Reflection input:** New York — 18pt, regular
- **Caption / Meta:** SF Pro Text — 13pt, regular
- **Button labels:** SF Pro Text — 15pt, medium
- Fallback: Georgia, serif

### Spatial System
- Base unit: 8pt grid
- Screen padding: 32pt horizontal, 48pt top (safe area + breathing room)
- Section spacing: 40pt
- Element spacing: 16pt
- Corner radius: 16pt (cards), 24pt (buttons), full (orb)

### Motion Philosophy
- **Breathing orb:** Scale 1.0 → 1.08 → 1.0, 4-second inhale / 4-second exhale cycle, infinite
- **Transitions:** 600ms ease-in-out for screen changes (nothing snaps)
- **Fade-ins:** Opacity 0→1, 800ms ease-out, staggered 150ms between elements
- **Haptics:** Soft pulse on orb inhale peak (CHHapticPattern), single tap on reflection submit
- **No bouncy physics** — everything is slow, deliberate, calm

### Visual Assets
- **Orb:** Radial gradient from `#F4C594` (center) → `#E8A46A` → transparent, with soft outer glow
- **Background:** Solid `#0D0B09`, no gradients on full background (the orb is the light)
- **Icons:** SF Symbols only — `moon.stars`, `calendar`, `magnifyingglass`, `chevron.left`
- **No images** — everything is built from code (gradients, shapes, typography)

---

## 3. Layout & Structure

### App Architecture
```
TabView (hidden — single-screen feel, but manages state)
├── RitualView (main / tonight's reflection)
├── ArchiveView (past reflections)
└── WeekReviewView (Sunday night only, else shows countdown)
```

### Screen Flow
1. **App opens → RitualView** — if evening (after 9pm), show orb + question. Otherwise show "Still will be here tonight"
2. **Tap orb → ReflectionFlow** — question fades in, text field appears
3. **Submit → Confirmation** — reflection saved, orb pulses warmly, back to waiting state
4. **Archive tab → ArchiveView** — scrollable list of past reflections, grouped by week
5. **Sunday → WeekReviewView** — replace ritual with week summary

### Navigation
- No UINavigationController visible — single screen with state transitions
- Tab bar is minimal, dark, with subtle icons (hidden during ritual flow)
- Swipe back disabled during active reflection (avoid accidental dismissal)

---

## 4. Features & Interactions

### 4.1 Evening Ritual (RitualView)
- **Trigger:** Opens automatically when app launches between 9pm–6am; shows orb + question
- **Orb:** Centered, slowly breathing, emitting warm amber light. Tappable.
- **Question:** Fades in below orb when ready. One question per night from curated pool.
- **States:**
  - `waiting` — orb breathing, "Still will be here tonight" text
  - `ready` — question visible, orb pulses gently to invite tap
  - `reflecting` — reflection input visible, orb is focused
  - `completed` — "Good night, [name]" + subtle confirmation, orb dims to steady glow
  - `skipped` — morning after a missed night: gentle nudge "Still is here when you're ready"

### 4.2 Reflection Flow
- Tap orb → question animates in, text field appears (auto-focus)
- Placeholder: "Take your time..."
- Character limit: 500 (soft — no hard stop, just visual cue at 400+)
- Submit button: "Release to the night" — amber, rounded, subtle glow on hover
- On submit:
  - Haptic: single soft pulse
  - Orb: brightens momentarily, then settles
  - Transition: fade to completion state (1.2s)
  - Data: saved to SQLite with timestamp

### 4.3 Week Review (Sunday night, 9pm+)
- Shows automatically Sunday night instead of RitualView
- Sections:
  - **"What mattered this week"** — reflections tagged as significant (inferred from length / word choice)
  - **"What faded"** — shorter, lighter entries
  - **"What mattered that you didn't notice"** — AI pattern detection (theme extraction)
- Each section: 2–3 cards with date + excerpt
- Tap card → full reflection in modal
- If not Sunday: show countdown "X days until your week in review"

### 4.4 Archive (ArchiveView)
- List of all reflections, newest first
- Grouped by week (ISO week number)
- Each row: date (formatted beautifully: "Tuesday, March 17"), question, and first line of reflection
- Search bar: searches reflection text and questions
- Tap row → full reflection in sheet
- Empty state: "Your reflections will live here"

### 4.5 Gentle Nudges
- If reflection missed previous night:
  - Morning notification (optional, user-enabled): "A reflection waited for you last night"
  - When opening app: soft banner "Still held last night's question for you"
- No push notifications by default — respect the calm
- User can enable/disable in Settings

### 4.6 Question Bank
Questions rotate on a cycle of ~60 curated questions, no repeat within 8 weeks:
- "What exhausted you today?"
- "What surprised you?"
- "What did you almost say?"
- "What did you learn about yourself?"
- "What are you carrying that isn't yours?"
- "What felt most true?"
- "What did you avoid?"
- "What are you pretending is fine?"
- "What made you laugh today?"
- "What do you need to let go of?"
- ... (50+ more)

---

## 5. Component Inventory

### BreathingOrb
- States: `idle` (slow breath), `attentive` (question visible, breath slightly faster), `recording` (brighter, steady), `complete` (dim, steady glow)
- Size: 160pt diameter
- Glow: 80pt soft shadow, amber at 30% opacity
- Animation: `.scale3d` with 8s total cycle, `easeInOut`

### ReflectionCard
- Background: `#1A1714`
- Corner radius: 16pt
- Padding: 20pt
- Contains: date (caption), question (display, smaller), reflection text (body)
- States: default, highlighted (subtle amber border on tap)

### QuestionLabel
- Font: New York, 22pt, medium
- Color: `#F5F0E8`
- Alignment: center
- Animation: fade in after orb is tapped, 800ms

### ReflectionInput
- Background: transparent
- Placeholder: "Take your time..." in `#9B9385`
- Text: New York, 18pt, `#F5F0E8`
- No border, no background — just text
- Min height: 80pt, expands with content
- Max characters: 500

### SubmitButton
- Label: "Release to the night"
- Background: `#C47D3E` with subtle amber glow
- Corner radius: 24pt
- Height: 52pt
- Font: SF Pro Text, 15pt, medium, `#0D0B09`
- States: default, pressed (scale 0.97), disabled (opacity 0.4)

### WeekReviewCard
- Background: `#1A1714`
- Corner radius: 16pt
- Section label at top (e.g., "What mattered")
- Reflection excerpt below

### ArchiveRow
- Date: SF Pro Text, 13pt, `#9B9385`
- Question: New York, 15pt, medium, `#F5F0E8`
- Preview: New York, 14pt, `#9B9385`, 1 line
- Separator: 1pt `#2A2520`

### SearchBar
- Background: `#1A1714`
- Corner radius: 12pt
- Icon: `magnifyingglass` in `#9B9385`
- Text: New York, 16pt, `#F5F0E8`
- Placeholder: "Search reflections..."

### NudgeBanner
- Background: `#1A1714` with amber left border (4pt)
- Corner radius: 12pt
- Text: SF Pro Text, 14pt, `#9B9385`
- Animation: slides down from top, 400ms

---

## 6. Technical Approach

### Framework & Architecture
- **SwiftUI** (iOS 26+)
- **MVVM** — Views observe ViewModels, ViewModels hold business logic
- **Combine** for reactive data flow

### Data Layer
- **SQLite.swift** for local persistence
  - Table: `reflections` (id, date, question, text, created_at)
  - Table: `questions` (id, text, last_asked)
  - Table: `settings` (key, value)
- **CloudKit** (optional sync) — CKContainer, private database, record type `Reflection`
  - Sync is opt-in, triggered manually or on significant changes
  - Conflict resolution: latest timestamp wins

### Haptics
- **CoreHaptics** via `HapticManager`
  - Breathing pulse: `CHHapticEvent` with intensity 0.4, sharpness 0.2, duration 0.3s
  - Submit tap: intensity 0.6, sharpness 0.3, duration 0.15s
  - Fallback: `UIImpactFeedbackGenerator` if CoreHaptics unavailable

### Apple Intelligence
- Use `MLContext` + local model for theme extraction in Week Review
- Generate reflection prompts via `ASLanguageModel` (on-device)
- Fallback: curated question bank if Apple Intelligence unavailable

### Dependencies (Swift Package Manager)
| Package | Version | Purpose |
|---|---|---|
| SQLite.swift | 0.15.3 | Local database |

### Project Structure
```
Still/
├── App/
│   └── StillApp.swift
├── Models/
│   ├── Reflection.swift
│   └── Question.swift
├── ViewModels/
│   ├── RitualViewModel.swift
│   ├── ArchiveViewModel.swift
│   └── WeekReviewViewModel.swift
├── Views/
│   ├── RitualView.swift
│   ├── ArchiveView.swift
│   ├── WeekReviewView.swift
│   └── Components/
│       ├── BreathingOrb.swift
│       ├── ReflectionCard.swift
│       ├── ReflectionInput.swift
│       ├── SubmitButton.swift
│       ├── WeekReviewCard.swift
│       ├── ArchiveRow.swift
│       ├── SearchBar.swift
│       └── NudgeBanner.swift
├── Services/
│   ├── DatabaseService.swift
│   ├── HapticManager.swift
│   ├── QuestionBank.swift
│   └── CloudKitService.swift
├── Utilities/
│   ├── Colors.swift
│   └── Typography.swift
└── Resources/
    └── Assets.xcassets
```

### Build Configuration
- Deployment target: iOS 26.0
- Swift version: 6.0
- XcodeGen project.yml with SPM dependencies
