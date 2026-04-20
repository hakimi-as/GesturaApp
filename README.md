<div align="center">

<img src="assets/icons/AppIcon.png" alt="Gestura Logo" width="120" height="120" />

# Gestura
### *Break Silence, Build Bridges*

**A full-featured Malaysian Sign Language (BIM) learning and translation mobile application**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge)](https://flutter.dev)

</div>

---

## About

**Gestura** is a mobile application designed to make Malaysian Sign Language (Bahasa Isyarat Malaysia / BIM) accessible to everyone. It bridges the communication gap between the hearing and deaf communities through structured lessons, gamified learning, real-time sign-to-text translation, and a social experience — all in one app.

The app is paired with a cloud-hosted **Sign Recognition API** (FastAPI on Railway) that performs Dynamic Time Warping (DTW) matching of body pose landmark sequences against a library of 2,000+ signs sourced from the WLASL dataset and the MFD Sign Bank.

> Sign language assets and content in this application are used with direct permission from the **Malaysian Federation of the Deaf (MFD)** from their official BIM Sign Bank. We are deeply grateful for their collaboration and support in making this project possible.

---

## Features

### Learning System
- **Structured Lessons** — Category-based BIM sign lessons with video demonstrations
- **Learning Paths** — Guided Beginner → Intermediate → Advanced progression
- **Onboarding Preferences** — Learning goal and experience level collected at onboarding; filters daily goals and surfaces a recommended learning path banner on the Learn screen
- **Quizzes** — Five quiz modes: Sign-to-Text, Text-to-Sign, Timed Challenge, Spelling, and **Fill in the Blank** (type the sign name from an image)
- **Certificates** — Auto-generated PDF completion certificates per category

### Gamification
- **XP & Levelling** — Earn experience points for completing lessons and quizzes
- **Streak System** — Daily learning streaks with freeze protection
- **Badges & Achievements** — Unlock badges for milestones reached
- **Challenges** — Daily, weekly, and special challenges — including **personalised daily challenges** auto-generated from the user's weakest categories (marked ✨ For You)

### Social & Community
- **Friends System** — Add friends, send/accept requests, view profiles
- **Leaderboard** — Global and friends-only XP rankings
- **Activity Feed** — See friends' progress and achievements

### Sign Translation
- **Sign-to-Text** — Live camera feed with on-device ML Kit pose detection. User signs a word, taps **Capture Sign**, and the app sends pose landmark frames to the recognition API for DTW matching. Detected words build a sentence word-by-word.
- **Text-to-Sign** — Convert typed or spoken text into BIM sign animations with a skeleton-based sign player.

### Analytics
- **Learning Velocity** — 4-week XP earned comparison chart
- **Accuracy by Category** — Per-category accuracy breakdown from lesson completion history
- **Signs to Practice** — Auto-identified weak signs (below 70% accuracy), sorted by lowest accuracy first

### Technical Highlights
- **Offline Support** — Full lesson caching with Hive; syncs when back online
- **Push Notifications** — FCM-powered reminders, streak alerts, and achievement notifications
- **Admin Dashboard** — Full CMS for managing lessons, quizzes, badges, and users
- **Dark / Light Mode** — Full theme support with persistence
- **QR Code** — Generate and scan QR codes for friend connections

---

## Tech Stack

### Mobile App

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart) |
| **State Management** | Provider + ChangeNotifier |
| **Backend & Database** | Firebase Firestore |
| **Authentication** | Firebase Auth |
| **File Storage** | Firebase Storage + Cloudinary |
| **Push Notifications** | Firebase Cloud Messaging + flutter_local_notifications |
| **Local Storage / Offline** | Hive + SharedPreferences |
| **Camera** | camera (Flutter CameraX) |
| **Pose Detection** | Google ML Kit Pose Detection (on-device) |
| **Media Playback** | video_player + chewie + flutter_cache_manager |
| **Charts** | fl_chart |
| **PDF Generation** | pdf + printing |
| **QR Code** | qr_flutter + mobile_scanner |
| **Speech** | speech_to_text + flutter_tts |
| **UI & Animations** | flutter_animate + shimmer + google_fonts |

### Sign Recognition API

| Layer | Technology |
|---|---|
| **Framework** | FastAPI (Python) |
| **Hosting** | Railway |
| **Sign Matching** | Dynamic Time Warping (DTW) with Sakoe-Chiba band |
| **Feature Extraction** | Pose-only 12-dim vectors (shoulders, elbows, wrists) |
| **Sign Library** | Firebase Firestore (RAM-cached on startup) |
| **Dataset** | WLASL 2000 + MFD BIM Sign Bank |

---

## Architecture

### Mobile App

```
lib/
├── config/          # Theme, design system constants
├── models/          # Firestore data models (User, Lesson, Quiz, Badge, ...)
├── providers/       # State management (Auth, Progress, Badge, Theme, ...)
├── screens/
│   ├── admin/       # CMS: lessons, quizzes, badges, users, sign library
│   ├── auth/        # Login, register, forgot password
│   ├── badges/      # Achievement gallery
│   ├── challenges/  # Daily / weekly / special challenges
│   ├── dashboard/   # Home screen with XP, streaks, quick actions
│   ├── learn/       # Categories, lessons, learning paths, lesson detail
│   ├── leaderboard/ # Global and friends XP rankings
│   ├── notifications/
│   ├── onboarding/  # Intro slides + preference selection
│   ├── profile/     # User profile and stats
│   ├── progress/    # XP history chart, streak stats, enhanced analytics
│   ├── quiz/        # Quiz home, list, session, results
│   ├── search/      # Sign library search
│   ├── settings/    # Theme, notifications, offline settings
│   ├── social/      # Friends, requests, friend profiles, activity feed
│   └── translate/   # Sign-to-text and text-to-sign translation
├── services/        # Business logic (Firestore, Auth, Notifications, Offline, DTW, Sign Recognition)
├── widgets/         # Reusable UI components
│   ├── badges/      # Badge cards and unlock dialogs
│   ├── cards/       # Stat, welcome, and action cards
│   ├── common/      # Shared UI (bottom nav, shimmer, skeleton, emoji picker)
│   ├── gamification/# Streak freeze and XP chart widgets
│   ├── learning/    # Learning path widgets and entry cards
│   ├── offline/     # Offline banners and download widgets
│   ├── share/       # Progress sharing card
│   ├── social/      # Activity feed widget
│   └── video/       # Cached video player and sign animation player
└── utils/           # Helper utilities
```

### Sign Recognition API

```
sign_api/
├── main.py          # FastAPI app, endpoints: GET /health, GET /words, POST /match
├── dtw_engine.py    # Feature extraction (96-dim or 12-dim) + DTW matching
├── sign_library.py  # Firestore loader, RAM cache, pose-only compression
├── Procfile         # Railway deployment: uvicorn main:app
└── requirements.txt # fastapi, uvicorn, firebase-admin, pydantic
```

### Sign Data Pipeline

```
sign_processing/
├── download_wlasl.py   # Download WLASL 2000 dataset videos
├── extract_wlasl.py    # Extract MediaPipe holistic landmarks from videos
├── extract_all.py      # Batch landmark extraction
├── upload_wlasl.py     # Upload processed landmark data to Firestore
└── run_pipeline.bat    # End-to-end: download → extract → upload
```

---

## Sign Recognition Pipeline

```
Camera frame (CameraX)
       │
       ▼
ML Kit Pose Detection (on-device, ~15fps)
       │  33 pose landmarks (x, y normalized)
       ▼
Frame Buffer (rolling 30-frame window)
       │
       ▼  user taps "Capture Sign"
POST /match  ──►  Sign Recognition API (Railway)
                       │
                       ▼
              Feature extraction
              (pose indices 11–16: shoulders, elbows, wrists → 12-dim)
                       │
                       ▼
              Normalise sequence
              (translate by shoulder midpoint, scale by shoulder width)
                       │
                       ▼
              DTW matching against sign library
              (Sakoe-Chiba band, path-length normalised)
                       │
                       ▼
              Top-K matches + confidence scores
                       │
       ◄───────────────┘
       │
Detected word appended to sentence
```

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`
- Android Studio / VS Code with Flutter extension
- Firebase project with Firestore, Auth, Storage, and FCM enabled
- (Optional) Railway account for hosting the Sign Recognition API

### Mobile App Setup

```bash
# 1. Clone the repository
git clone https://github.com/hakimi-as/GesturaApp.git
cd GesturaApp

# 2. Install dependencies
flutter pub get

# 3. Add your Firebase config
# Android: place google-services.json in android/app/
# iOS:     place GoogleService-Info.plist in ios/Runner/

# 4. Run the app
flutter run
```

### Sign Recognition API Setup

```bash
cd sign_api

# 1. Install Python dependencies
pip install -r requirements.txt

# 2. Add Firebase service account
# Place serviceAccount.json in sign_api/

# 3. Set environment variables
export API_KEY=your_secret_key      # optional — leave blank to disable auth
export FIREBASE_CREDENTIALS=serviceAccount.json

# 4. Run locally
uvicorn main:app --reload --port 8000
```

**Deploy to Railway:**
1. Push `sign_api/` to a Railway service
2. Set `API_KEY` and `FIREBASE_CREDENTIALS` env vars in Railway dashboard
3. Railway auto-detects the `Procfile` and starts the server

**API Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Liveness check + library status |
| `GET` | `/words?limit=50` | Sample of available sign words |
| `POST` | `/match` | Match landmark frames, returns top-K sign matches |

**POST /match request body:**
```json
{
  "frames": [
    {
      "pose":       [{"x": 0.5, "y": 0.3}, ...],
      "left_hand":  [{"x": 0.4, "y": 0.6}, ...],
      "right_hand": null
    }
  ],
  "top_k": 3
}
```

### Wire the app to your API

In `lib/services/remote_sign_service.dart`, set your Railway URL before calling the translate screen:

```dart
RemoteSignService.serverUrl = 'https://your-app.up.railway.app';
RemoteSignService.apiKey    = 'your_secret_key'; // if API_KEY is set
```

---

## Screens Overview

| Screen | Description |
|---|---|
| Onboarding | 4-page introduction with learning goal + experience level preference selection |
| Dashboard | XP stats, daily streak, quick actions, learning path entry card |
| Learn | Browse categories, lessons by category, recommended path banner based on experience level |
| Lesson Detail | Video demonstration with controls and completion tracking |
| Quiz | 5 modes: Sign-to-Text, Text-to-Sign, Timed Challenge, Spelling, Fill in the Blank |
| Quiz Results | Score breakdown, XP earned, wrong-answer review, retry option |
| Challenges | Daily / weekly / special challenges + ✨ personalised challenges from weak spots |
| Progress | Overview, Activity, Badges, and Analytics tabs |
| Analytics | 4-week XP velocity chart, accuracy per category, weak signs list |
| Translate | Sign-to-text (live camera + DTW matching) and text-to-sign animation |
| Leaderboard | Global and friends-only XP rankings |
| Social | Friends list, friend requests, friend profiles, activity feed |
| Badges | Full achievement gallery with unlock conditions |
| Profile | User stats, certificates, edit profile |
| Settings | Theme toggle, notification prefs, offline cache management |
| Admin | Full CMS — lessons, quizzes, badges, challenges, users, sign library |

---

## Acknowledgements

A special thanks to the **Malaysian Federation of the Deaf (MFD)** for granting permission to use their official **Bahasa Isyarat Malaysia (BIM) Sign Bank** as the foundation of all sign language content in this application. This project would not be possible without their support and dedication to the deaf community.

---

<div align="center">

Built with Flutter &nbsp;•&nbsp; Powered by Firebase &nbsp;•&nbsp; Sign recognition by DTW on Railway

Made for the BIM community

</div>
