<div align="center">

<img src="assets/icons/AppIcon.png" alt="Gestura Logo" width="120" height="120" />

# Gestura

### *Break Silence, Build Bridges*

A production-grade mobile application for learning and translating Malaysian Sign Language (BIM), built with Flutter, Firebase, and a custom cloud-hosted sign recognition API.

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-4CAF50?style=for-the-badge&logo=android&logoColor=white)](https://flutter.dev)
[![ML Kit](https://img.shields.io/badge/ML_Kit-Pose_Detection-FF6F00?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)

</div>

---

## What Is Gestura?

Gestura is a **full-stack, production-ready mobile application** that bridges the communication gap between the hearing and Deaf communities in Malaysia. It combines **structured sign language education**, **real-time AI-powered sign recognition**, and a **gamified social learning experience** in a single, cohesive product.

The application is backed by a **cloud-hosted Sign Recognition API** (FastAPI on Railway) that performs Dynamic Time Warping (DTW) matching of body pose landmark sequences captured live by the device camera against a library of 2,000+ signs — sourced from the WLASL dataset and the MFD BIM Sign Bank.

> Sign language assets and content in this application are used with direct permission from the **Malaysian Federation of the Deaf (MFD)** from their official BIM Sign Bank. We are deeply grateful for their collaboration and support.

---

## Why This Project Stands Out

| Dimension | What Was Built |
|---|---|
| **Full-stack scope** | Flutter mobile app + FastAPI ML backend + Firebase cloud infrastructure |
| **Real ML pipeline** | On-device ML Kit pose detection → frame buffering → cloud DTW matching with on-device fallback |
| **Production architecture** | Provider pattern, paginated Firestore queries, role-based access control, offline-first Hive sync |
| **Gamification system** | XP, streaks, streak freezes, dynamic badges, daily/weekly/personalised challenges |
| **Admin CMS** | Full content management for lessons, quizzes, badges, challenges, users, and sign library |
| **Social layer** | Friends, leaderboards, activity feeds, QR-code friend connections |
| **Offline support** | Hive-based lesson caching with automatic background sync on reconnect |
| **Multilingual** | English and Bahasa Malaysia, user-switchable at runtime |

---

## Feature Breakdown

### Learning System
- **Structured Lessons** — Category-based BIM sign lessons with Cloudinary-hosted video demonstrations
- **Learning Paths** — Curated Beginner → Intermediate → Advanced progression with auto-generated PDF completion certificates
- **Onboarding Preferences** — Learning goal and experience level collected at first launch; personalises the recommended path banner and daily goal targets
- **Five Quiz Modes** — Sign-to-Text, Text-to-Sign, Timed Challenge, Spelling, and Fill-in-the-Blank
- **Lesson Detail** — Video player with playback controls, XP award, badge/challenge hooks on completion

### Gamification
- **XP & Levelling** — Earn experience for every lesson and quiz; levels computed from cumulative XP
- **Daily Streaks** — Consecutive-day tracking with configurable auto-use streak-freeze protection
- **Streak Freezes** — Purchasable with XP; auto-applies or manually triggered
- **Dynamic Badges** — Badge pool seeded to Firestore; criteria evaluated against live user stats on each unlock check
- **Challenges** — Daily, weekly, special, and ✨ personalised challenges auto-generated from the user's weakest sign categories

### Sign Translation
- **Sign-to-Text** — Live front-camera feed processed by ML Kit Pose Detection at ~15 fps; 30-frame rolling buffer; user taps Capture Sign to send landmark sequences to the recognition API; detected words build a sentence chip-by-chip
- **Text-to-Sign** — Typed or spoken input converted to BIM sign animations via a skeleton-based `SignPlayer` widget; speech input via `speech_to_text`
- **Offline fallback** — If the remote API is unreachable, on-device DTW matching kicks in automatically with no user-visible error

### Analytics & Progress
- **Activity Timeline** — Filterable (All / Lessons / Quizzes), grouped by Today / Yesterday / This week / This month / Earlier; real Firestore data
- **4-Week XP Velocity** — `fl_chart` bar chart showing XP earned per week over the last 28 days
- **Per-Category Accuracy** — Breakdown from lesson completion history
- **Signs to Practice** — Auto-identified weak signs (below 70% accuracy), sorted ascending

### Social & Community
- **Friends System** — Send/accept friend requests; view friend profiles and stats
- **Leaderboard** — Global and friends-only rankings by XP, Streak, or Lessons Completed
- **Activity Feed** — Friends' recent completions and achievements
- **QR Codes** — Generate and scan QR codes for instant friend connections

### Infrastructure & Quality
- **Offline-first** — Hive boxes cache lessons, progress, and user data; pending sync queue automatically flushes when connectivity is restored
- **Push Notifications** — Firebase Cloud Messaging with per-type opt-in settings
- **Role-Based Admin Panel** — `isAdmin` flag gated at both navigation and screen level; full CMS for all data types
- **Paginated Search** — Firestore cursor-based pagination (50 lessons/page) with infinite scroll; no full-collection dumps
- **Dark / Light / System Theme** — Persisted via SharedPreferences; switches at runtime
- **Bilingual UI** — All strings abstracted into `AppLocalizations`; English and Malay

---

## Tech Stack

### Mobile Application

| Layer | Technology | Purpose |
|---|---|---|
| Framework | Flutter 3.x (Dart) | Cross-platform UI |
| State Management | Provider + ChangeNotifier | App-wide reactive state |
| Database | Cloud Firestore | Real-time NoSQL backend |
| Authentication | Firebase Auth | Email/password auth |
| File Storage | Firebase Storage + Cloudinary | Video & image hosting |
| Local Storage | Hive + SharedPreferences | Offline cache + settings |
| Push Notifications | Firebase Cloud Messaging | Streak reminders, achievements |
| Camera | Flutter CameraX (`camera`) | Live pose capture |
| Pose Detection | Google ML Kit (on-device) | 33-landmark body keypoints |
| Media Playback | `video_player` + `chewie` + `flutter_cache_manager` | Lesson videos |
| Charts | `fl_chart` | XP velocity & accuracy charts |
| PDF | `pdf` + `printing` | Completion certificates |
| QR Code | `qr_flutter` + `mobile_scanner` | Friend connections |
| Speech | `speech_to_text` + `flutter_tts` | Voice input & TTS output |
| Animations | `flutter_animate` + `shimmer` | Micro-interactions & loading |
| Fonts | `google_fonts` | Bricolage Grotesque + Nunito |

### Sign Recognition API

| Layer | Technology | Purpose |
|---|---|---|
| Framework | FastAPI (Python) | REST API |
| Hosting | Railway | Zero-config cloud deployment |
| Matching | Dynamic Time Warping (DTW) | Temporal sequence comparison |
| Band | Sakoe-Chiba | Constrained DTW warping path |
| Features | 12-dim pose vectors (shoulders, elbows, wrists) | Compact sign representation |
| Library | Firebase Firestore (RAM-cached on startup) | 2,000+ sign sequences |
| Dataset | WLASL 2000 + MFD BIM Sign Bank | Ground-truth sign data |

---

## Architecture

### Project Structure

```
lib/
├── config/
│   ├── theme.dart           # Light/dark themes, color tokens, typography
│   ├── design_system.dart   # Reusable decorations, TapScale, SectionHeader
│   └── constants.dart       # Collection names, XP values, quiz settings
│
├── models/                  # Typed Firestore models with fromFirestore / toMap
│   ├── user_model.dart      # XP, streaks, badges, preferences
│   ├── lesson_model.dart
│   ├── quiz_model.dart
│   ├── badge_model.dart     # Dynamic badge pool (no hardcoded badges)
│   ├── challenge_model.dart
│   ├── progress_model.dart  # LearningProgressModel, UserStatsModel
│   └── notification_model.dart
│
├── providers/               # ChangeNotifier state containers
│   ├── auth_provider.dart
│   ├── lesson_provider.dart
│   ├── quiz_provider.dart
│   ├── progress_provider.dart
│   ├── badge_provider.dart
│   ├── challenge_provider.dart
│   ├── notification_provider.dart   # Unread count, mark-as-read, clear-all
│   ├── translate_provider.dart      # Sentence words, sign segments (tab-persistent)
│   ├── connectivity_provider.dart   # Online/offline + auto-sync on reconnect
│   ├── theme_provider.dart
│   └── locale_provider.dart
│
├── services/
│   ├── firestore_service.dart       # Core CRUD, paginated queries, seeding
│   ├── offline_service.dart         # Hive caching + pending sync queue
│   ├── remote_sign_service.dart     # DTW API client with on-device fallback
│   ├── dtw_service.dart             # On-device DTW matching
│   ├── badge_service.dart           # Dynamic badge unlock evaluation
│   ├── challenge_service.dart       # Challenge assignment & completion
│   ├── notification_service.dart    # FCM initialisation & routing
│   ├── navigation_service.dart      # Global navigator key + FCM deep links
│   ├── cloudinary_service.dart      # Optimised image/video URLs
│   ├── friend_service.dart          # Social graph operations
│   ├── learning_path_service.dart   # Path progress tracking
│   ├── certificate_service.dart     # PDF certificate generation
│   ├── time_tracking_service.dart   # Session duration tracking
│   └── haptic_service.dart          # Platform haptics
│
├── screens/
│   ├── auth/                # Login · Register · Forgot Password
│   ├── onboarding/          # Intro slides + preference selection
│   ├── dashboard/           # Home: XP, streaks, challenges, quick actions
│   ├── learn/               # Categories · Lesson Detail · Learning Paths
│   ├── quiz/                # Quiz Home · Session · Results (5 modes)
│   ├── translate/           # Sign-to-Text · Text-to-Sign
│   ├── progress/            # Activity timeline with date grouping & filters
│   ├── badges/              # Badge gallery (All / Unlocked tabs)
│   ├── challenges/          # Daily · Weekly · Special · Personalised
│   ├── leaderboard/         # Global and friends rankings
│   ├── social/              # Friends · Requests · Profiles · Activity Feed
│   ├── notifications/       # Notification list (provider-driven)
│   ├── search/              # Paginated sign library search
│   ├── settings/            # Theme · Language · Offline · Admin access
│   ├── profile/             # User profile · Certificates · Stats
│   └── admin/               # CMS: Lessons · Quizzes · Badges · Challenges · Users
│
└── widgets/
    ├── common/              # BottomNavBar · shimmer · skeleton · emoji picker
    ├── badges/              # BadgeCard · BadgeUnlockDialog
    ├── cards/               # StatCard · WelcomeCard · QuickActionCard
    ├── gamification/        # StreakFreezeCard · XpChartWidget
    ├── learning/            # LearningPathCard · PathEntryCard
    ├── offline/             # OfflineBanner · DownloadWidget · SyncStatus
    ├── share/               # ShareProgressCard
    ├── social/              # ActivityFeedWidget
    └── video/               # CachedVideoPlayer · SignPlayer · VideoPlayerWidget
```

### State Management Pattern

Every feature area owns a `ChangeNotifier` provider. Screens consume state via `Consumer<T>` or `context.read<T>()` — never calling Firestore directly from widget code. This keeps screens thin and testable.

```
AuthProvider ─────────────── all auth-dependent screens
LessonProvider ────────────── Learn screens
QuizProvider ──────────────── Quiz screens
ProgressProvider ──────────── Progress, Dashboard, Lesson Detail
BadgeProvider ─────────────── Badges, Dashboard, Lesson Detail
ChallengeProvider ─────────── Challenges, Dashboard, Lesson Detail
NotificationProvider ──────── Notifications screen + Dashboard bell badge
TranslateProvider ─────────── Translate screen (persists across tab switches)
ConnectivityProvider ──────── Offline banner + auto-sync trigger on reconnect
ThemeProvider ─────────────── Theme-aware widgets
LocaleProvider ────────────── Language selector
```

### Sign Recognition Pipeline

```
Camera frame (CameraX, ~15 fps)
       │
       ▼
ML Kit Pose Detection  ◄── on-device, no network required
(33 landmarks, x/y normalised to frame dimensions)
       │
       ▼
Frame Buffer  (rolling 30-frame window, minimum 12 frames required)
       │
       ▼  ← user taps "Capture Sign"
POST /match ──────────────► Sign Recognition API (FastAPI / Railway)
                                    │
                                    ▼
                           Feature Extraction
                           (pose landmarks 11–16:
                            shoulders, elbows, wrists → 12-dim vector)
                                    │
                                    ▼
                           Sequence Normalisation
                           (translate by shoulder midpoint,
                            scale by shoulder width)
                                    │
                                    ▼
                           DTW Matching
                           (Sakoe-Chiba band,
                            path-length normalised distance)
                                    │
                                    ▼
                           Top-K matches + confidence scores
                                    │
       ◄────────────────────────────┘
       │
  On-device fallback ◄── if server unreachable (DtwService)
       │
Detected word appended to sentence as a chip
```

### Offline Architecture

```
User completes lesson (offline)
       │
       ▼
OfflineService.saveProgressLocally()
  ├── writes to Hive _progressBox
  └── enqueues item in Hive _pendingSyncBox

Device regains connectivity
       │
       ▼
ConnectivityProvider._updateConnectionStatus()
  └── detects offline→online transition
       └── calls OfflineService.syncPendingItems()
              ├── reads all items from _pendingSyncBox
              ├── fires Firestore writes (progress, lessonComplete, quizComplete)
              ├── removes synced items from queue
              └── retries failed items up to 5 times before dropping
```

---

## Screens Overview

| Screen | Highlights |
|---|---|
| **Onboarding** | 4-page intro with learning goal + experience level; drives personalisation |
| **Dashboard** | Live XP, streak, daily goal progress, challenge cards, quick actions |
| **Learn** | Category grid, lesson list, learning path entry card, progress calendar |
| **Lesson Detail** | Video player, completion tracking, XP + badge + challenge hooks |
| **Quiz** | 5 modes; timed; per-question feedback; wrong-answer review on results screen |
| **Challenges** | Daily / Weekly / Special tabs + ✨ AI-personalised from weak categories |
| **Translate** | Sign-to-Text (live camera + DTW) and Text-to-Sign (skeleton animation player) |
| **Progress** | Date-grouped activity timeline; All / Lessons / Quizzes filter chips |
| **Analytics** | 4-week XP velocity chart, per-category accuracy, weak-sign list |
| **Badges** | All badges (with locked state) + Unlocked tab; category filter chips |
| **Leaderboard** | Global and friends-only; XP / Streak / Lessons tabs |
| **Social** | Friends list, incoming requests, friend profiles, activity feed |
| **Notifications** | Provider-driven; dismissible cards; mark-as-read; clear all |
| **Search** | Paginated (50/page) + infinite scroll; highlighted match text; recent history |
| **Settings** | Theme, language, sign language, streak freeze, offline cache, logout |
| **Admin** | Role-guarded CMS — lessons, quizzes, badges, challenges, users, sign library |

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.0` / Dart `^3.5.0`
- Android Studio or VS Code with Flutter extension
- Firebase project with **Firestore, Auth, Storage, Analytics, and FCM** enabled
- *(Optional)* Railway account for the Sign Recognition API

### Mobile App Setup

```bash
# 1. Clone
git clone https://github.com/hakimi-as/GesturaApp.git
cd GesturaApp

# 2. Install dependencies
flutter pub get

# 3. Add Firebase config
#    Android → android/app/google-services.json
#    iOS     → ios/Runner/GoogleService-Info.plist

# 4. Run
flutter run

# 5. (Optional) Pass API credentials at build time
flutter run \
  --dart-define=SIGN_SERVER_URL=https://your-api.up.railway.app \
  --dart-define=SIGN_API_KEY=your_secret_key
```

> **Note:** If no API credentials are supplied, the app falls back to on-device DTW matching automatically. No configuration is required to run the app in this mode.

### Sign Recognition API Setup

```bash
cd sign_api

# 1. Install Python dependencies
pip install -r requirements.txt

# 2. Add Firebase service account key
#    Place serviceAccount.json in sign_api/

# 3. Configure environment
export API_KEY=your_secret_key            # optional
export FIREBASE_CREDENTIALS=serviceAccount.json

# 4. Run locally
uvicorn main:app --reload --port 8000
```

**Deploy to Railway:** push `sign_api/` to a Railway project, set `API_KEY` and `FIREBASE_CREDENTIALS` in the Railway dashboard, and Railway auto-detects the `Procfile`.

#### API Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Liveness check + library size |
| `GET` | `/words?limit=50` | Sample of available sign words |
| `POST` | `/match` | Match landmark frames → top-K signs |

**POST /match payload:**
```json
{
  "frames": [
    {
      "pose":       [{"x": 0.52, "y": 0.31}, "...33 landmarks"],
      "left_hand":  null,
      "right_hand": [{"x": 0.48, "y": 0.67}, "...21 landmarks"]
    }
  ],
  "top_k": 3
}
```

**Response:**
```json
{
  "matches": [
    {"word": "hello",  "confidence": 0.87, "distance": 0.13},
    {"word": "wave",   "confidence": 0.71, "distance": 0.29},
    {"word": "greet",  "confidence": 0.54, "distance": 0.46}
  ],
  "latency_ms": 42,
  "library_size": 2048
}
```

### Sign Data Pipeline

The WLASL landmark extraction pipeline lives in `sign_processing/`:

```bash
cd sign_processing

# End-to-end: download WLASL videos → extract landmarks → upload to Firestore
run_pipeline.bat

# Or run steps individually
python download_wlasl.py   # Download WLASL 2000 dataset videos
python extract_wlasl.py    # Extract MediaPipe holistic landmarks
python upload_wlasl.py     # Upload processed data to Firestore
```

---

## Engineering Notes

### Key Design Decisions

**Provider-per-feature, not a monolithic store.** Each domain (auth, progress, badges, challenges, notifications, translate, connectivity) owns its own `ChangeNotifier`. Screens are thin consumers. This makes it trivial to test a provider in isolation and swap its implementation without touching UI.

**Paginated Firestore queries everywhere.** The search screen, lesson lists, and notification feeds all use `limit()` + `startAfterDocument()` cursors. No screen dumps an entire collection into memory.

**Single connectivity singleton, auto-sync on reconnect.** `ConnectivityProvider` is a singleton registered in the Provider tree. When it detects an offline→online transition it fires `OfflineService.syncPendingItems()` automatically — no polling loop, no user action required.

**API key injection via `--dart-define`.** `RemoteSignService.serverUrl` and `.apiKey` are populated from build-time environment variables. Nothing sensitive is hardcoded or committed.

**Role-based admin access — double-gated.** The admin navigation entry is hidden from non-admins in `SettingsScreen`. `AdminDashboardScreen.build()` independently checks `isAdmin` and renders an access-denied screen — so deep-linked or notification-routed navigations are also blocked.

**Dynamic badge and challenge pools.** No badge or challenge is hardcoded in the app binary. They are seeded to Firestore collections (`badgePool`, `challengePool`) and evaluated at runtime against live user stats. Adding a new badge requires only a Firestore document — no app update needed.

---

## Acknowledgements

A special thanks to the **Malaysian Federation of the Deaf (MFD)** for granting permission to use their official **Bahasa Isyarat Malaysia (BIM) Sign Bank** as the foundation of all sign language content in this application. This project would not be possible without their support and dedication to the Deaf community in Malaysia.

---

<div align="center">

Built with Flutter &nbsp;·&nbsp; Powered by Firebase &nbsp;·&nbsp; Sign recognition via DTW on Railway

*Made for the BIM community*

</div>
