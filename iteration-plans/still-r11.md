# Still R11 — AI Meditation Guidance

## Theme
Personalized, intelligent meditation experiences powered by on-device AI.

---

## Features

### 1. AI Meditation Guide
- Use Apple Intelligence / on-device ML to generate contextual meditation guidance
- Analyze user's recent sessions, time of day, and stated intent
- Provide real-time "nudges" during sessions (subtle audio cues or text prompts)
- Generate personalized session recommendations based on patterns

### 2. Breath Detection (Camera)
- Use Vision framework for real-time breath detection via webcam
- Track chest/shoulder movement to pace breathing exercises
- Visual indicator showing inhale/exhale/hold phases
- No audio — purely visual feedback on screen

### 3. Personalized Session Recommendations
- Weekly "suggested path" based on patterns:
  - Stressed → anxiety relief sessions
  - Low streak → easier/shorter sessions
  - High engagement → longer/deeper sessions
- "Perfect for right now" quick suggestion on app open
- Learn from skip patterns to improve recommendations

---

## Technical Approach
- **Vision framework** for breath detection
- **CoreML** for pattern analysis
- **Speech framework** for optional AI voice guidance
- **Persistence** via UserDefaults for recommendation history

---

## UI Changes
- Add "AI Guide" toggle in session player
- Breath detection visual: subtle ring that expands/contracts with detected breath
- Recommendation card on home screen with reasoning ("You seem tense, try this")

---

## Scope
- Medium complexity
- Privacy-preserving (all on-device)
- 2-3 weeks development
