# Still R12 — Guided Courses & Community

## Theme
Expand from single sessions to structured learning paths and social features.

---

## Features

### 1. Guided Courses
- Multi-day courses (7, 14, 21, 30 days) with progressive structure
- Course types:
  - "Sleep Better" — 14-day program
  - "Morning Ritual" — 7-day program
  - "Anxiety Relief" — 21-day program
  - "Deep Focus" — 10-day program
- Each day: unique session + daily challenge/reflection prompt
- Progress tracking within course (day X of 14)
- Course completion certificates

### 2. Teacher Profiles
- Expanded instructor bios, photos, meditation style
- "More from this teacher" section
- Teacher's own recommended sequences
- Links to teacher social/website

### 3. Community Meditations
- "Meditate with others" — listen to same session simultaneously
- Leaderboards (optional, opt-in):
  - Weekly streak champions
  - Most sessions completed
  - "Top improver" (biggest increase)
- Share milestones (non-public, friends only)

### 4. Session Ratings & Reviews
- Rate sessions 1-5 stars + optional text note
- "Your rating helped 12 people find this session"
- Community average rating visible

---

## Technical Approach
- **CloudKit** for community sync (opt-in)
- **UserDefaults** for course progress
- **Core Data or SQLite** for ratings
- No complex social graph — keep it minimal

---

## UI Changes
- New "Courses" tab alongside Library
- Teacher profile sheets
- Community tab (hidden by default, opt-in)
- Course progress ring on home screen

---

## Scope
- High complexity
- Requires CloudKit setup
- 3-4 weeks development
