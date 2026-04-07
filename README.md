<div align="center">

<img src="assets/icons/AppIcon.png" alt="Gestura Logo" width="120" height="120" />

# Gestura
### *Break Silence, Build Bridges*

**A full-featured Malaysian Sign Language (BIM) learning mobile application**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=for-the-badge)](https://flutter.dev)

</div>

---

## About

**Gestura** is a mobile application designed to make Malaysian Sign Language (Bahasa Isyarat Malaysia / BIM) accessible to everyone. It bridges the communication gap between the hearing and deaf communities through structured lessons, gamified learning, real-time translation, and a social experience — all in one app.

> Sign language assets and content in this application are used with direct permission from the **Malaysian Federation of the Deaf (MFD)** from their official BIM Sign Bank. We are deeply grateful for their collaboration and support in making this project possible.

---

## Features

### Learning System
- **Structured Lessons** — Category-based BIM sign lessons with video demonstrations
- **Learning Paths** — Guided Beginner → Intermediate → Advanced progression
- **Quizzes** — Standard and timed quizzes with multiple-choice questions
- **Certificates** — Auto-generated PDF completion certificates per category

### Gamification
- **XP & Levelling** — Earn experience points for completing lessons and quizzes
- **Streak System** — Daily learning streaks with freeze protection
- **Badges & Achievements** — Unlock badges for milestones reached
- **Challenges** — Daily, weekly, and special event challenges

### Social & Community
- **Friends System** — Add friends, send/accept requests, view profiles
- **Leaderboard** — Global and friends-only XP rankings
- **Activity Feed** — See friends' progress and achievements

### Translation
- **Sign-to-Text** — Camera-based sign language recognition *(in development)*
- **Text-to-Sign** — Convert text input to sign language output

### Technical Highlights
- **Offline Support** — Full lesson caching with Hive; syncs when back online
- **Push Notifications** — FCM-powered reminders, streak alerts, and achievement alerts
- **Admin Dashboard** — Content management for lessons, quizzes, badges, and users
- **Dark / Light Mode** — Full theme support with persistence
- **QR Code** — Generate and scan QR codes for friend connections

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart) |
| **State Management** | Provider + ChangeNotifier |
| **Backend & Database** | Firebase Firestore |
| **Authentication** | Firebase Auth |
| **File Storage** | Firebase Storage + Cloudinary |
| **Push Notifications** | Firebase Cloud Messaging (FCM) + flutter_local_notifications |
| **Local Storage / Offline** | Hive + SharedPreferences |
| **Media** | Video Player + flutter_cache_manager |
| **Charts** | fl_chart |
| **PDF Generation** | pdf + printing |
| **QR Code** | qr_flutter + mobile_scanner |
| **Speech** | speech_to_text + flutter_tts |
| **UI & Animations** | flutter_animate + shimmer + google_fonts |

---

## Architecture

```
lib/
├── config/          # App-wide constants and theme
├── models/          # Firestore data models (User, Lesson, Quiz, Badge, ...)
├── providers/       # State management (Auth, Progress, Badge, Theme, ...)
├── screens/         # Feature screens (auth, learn, quiz, social, admin, ...)
├── services/        # Business logic (Firestore, Auth, Notification, Offline, ...)
├── widgets/         # Reusable UI components
│   ├── badges/      # Badge cards and unlock dialogs
│   ├── cards/       # Stat, welcome, and action cards
│   ├── challenges/  # Challenge completion dialogs
│   ├── common/      # Shared UI (shimmer, state, skeleton, emoji picker)
│   ├── gamification/# Streak freeze and XP chart widgets
│   ├── learning/    # Learning path widgets and entry cards
│   ├── offline/     # Offline banners, download, and settings widgets
│   ├── share/       # Progress sharing card
│   ├── social/      # Activity feed widget
│   └── video/       # Cached video player and sign player
└── utils/           # Helper utilities
```

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`
- Android Studio / VS Code with Flutter extension
- Firebase project with Firestore, Auth, Storage, and FCM enabled

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/hakimi-as/GesturaApp.git
cd GesturaApp

# 2. Install dependencies
flutter pub get

# 3. Add your Firebase config
# Place google-services.json in android/app/
# Place GoogleService-Info.plist in ios/Runner/

# 4. Run the app
flutter run
```

---

## Screens Overview

| Screen | Description |
|---|---|
| Onboarding | 4-page introduction with preference selection |
| Dashboard | XP stats, streaks, quick actions, learning path entry |
| Learn | Browse categories, lessons, and learning paths |
| Quiz | Timed and standard quiz modes |
| Challenges | Daily / weekly / special event challenges |
| Progress | XP history chart, streak stats, time spent |
| Translate | Sign-to-text and text-to-sign translation |
| Leaderboard | Global and friends XP rankings |
| Social | Friends list, requests, profiles, activity feed |
| Badges | Full achievement gallery |
| Settings | Theme, notifications, offline, profile |
| Admin | Full CMS for lessons, quizzes, badges, users |

---

## Acknowledgements

A special thanks to the **Malaysian Federation of the Deaf (MFD)** for granting permission to use their official **Bahasa Isyarat Malaysia (BIM) Sign Bank** as the foundation of all sign language content in this application. This project would not be possible without their support and dedication to the deaf community.

---

<div align="center">

Built with Flutter &nbsp;•&nbsp; Powered by Firebase &nbsp;•&nbsp; Made for the BIM community

</div>
