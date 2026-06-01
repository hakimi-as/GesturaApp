# Gestura — Poster Diagrams

Paste each Mermaid block into **https://mermaid.live** → export as PNG or SVG.

---

## 1. System Architecture

```mermaid
flowchart TB
    classDef ui       fill:#6366F1,stroke:#4F46E5,color:#fff,rx:8
    classDef state    fill:#8B5CF6,stroke:#7C3AED,color:#fff,rx:8
    classDef service  fill:#0EA5E9,stroke:#0284C7,color:#fff,rx:8
    classDef cache    fill:#10B981,stroke:#059669,color:#fff,rx:8
    classDef external fill:#F59E0B,stroke:#D97706,color:#fff,rx:8
    classDef ml       fill:#EF4444,stroke:#DC2626,color:#fff,rx:8

    %% ── UI Layer ────────────────────────────────────────────────
    subgraph UI["📱  Flutter UI  ·  Presentation Layer"]
        direction LR
        NAV["Main Navigator\nIndexedStack"]
        DB["Dashboard"]
        LN["Learn &\nLessons"]
        TR["Translate"]
        CH["Challenges"]
        PR["Profile &\nBadges"]
        QZ["Quiz"]
    end

    %% ── State Management ─────────────────────────────────────────
    subgraph STATE["🔄  State Management  ·  Provider Pattern"]
        direction LR
        AP["Auth\nProvider"]
        PP["Progress\nProvider"]
        CP["Challenge\nProvider"]
        BP["Badge\nProvider"]
        NP["Notification\nProvider"]
        TP["Translate\nProvider"]
        LP["Lesson\nProvider"]
    end

    %% ── Service Layer ────────────────────────────────────────────
    subgraph SVC["⚙️  Services Layer"]
        direction LR
        FS["Firestore\nService"]
        NS["Notification\nService"]
        BS["Badge\nService"]
        CLS["Cloudinary\nService"]
        FRS["Friend\nService"]
        RSS["RemoteSign\nService"]
    end

    %% ── Sign Recognition ─────────────────────────────────────────
    subgraph ML["🤖  Sign Recognition Pipeline"]
        direction LR
        WV["MediaPipe\nHolistic\nWebView"]
        DTW["DTW Service\ncompute() Isolate"]
        SP["Sign Player\nSkeleton Painter"]
    end

    %% ── Cache Layer ──────────────────────────────────────────────
    subgraph CACHE["💾  On-Device Cache"]
        direction LR
        AC["AppCache\nIn-Memory TTL"]
        HV["Hive\nOffline DB"]
        SHP["Shared\nPreferences"]
    end

    %% ── External / Cloud ─────────────────────────────────────────
    subgraph CLOUD["☁️  Cloud & External Services"]
        direction LR
        FA[("Firebase\nAuth")]
        CF[("Cloud\nFirestore")]
        FCM["Firebase Cloud\nMessaging"]
        CDN["Cloudinary\nCDN"]
        MCDN["MediaPipe\nCDN Models"]
        SPD["SignPuddle\nSVG API"]
    end

    %% ── Connections ──────────────────────────────────────────────
    UI       --> STATE
    STATE    --> SVC
    STATE    --> ML
    SVC      --> CACHE
    SVC      --> CLOUD
    ML       --> CLOUD
    CACHE   -. "cache hit" .-> SVC

    class DB,LN,TR,CH,PR,QZ,NAV                ui
    class AP,PP,CP,BP,NP,TP,LP                  state
    class FS,NS,BS,CLS,FRS,RSS                  service
    class WV,DTW,SP                             ml
    class AC,HV,SHP                             cache
    class FA,CF,FCM,CDN,MCDN,SPD               external
```

---

## 2. Sign-to-Text Recognition Pipeline

```mermaid
flowchart TD
    classDef user    fill:#6366F1,stroke:#4F46E5,color:#fff
    classDef device  fill:#0EA5E9,stroke:#0284C7,color:#fff
    classDef ml      fill:#EF4444,stroke:#DC2626,color:#fff
    classDef logic   fill:#8B5CF6,stroke:#7C3AED,color:#fff
    classDef output  fill:#10B981,stroke:#059669,color:#fff
    classDef cloud   fill:#F59E0B,stroke:#D97706,color:#fff

    U1(["👤 User performs\nhand sign"])
    CAM["📷 Device Camera\ngetUserMedia"]
    MP["🤖 MediaPipe Holistic\nIn-App WebView\n15 fps"]
    LM["Pose + Hand\nLandmarks\n543 points"]
    BUF["Rolling Frame Buffer\n12–30 frames"]
    STILL{"Hand\nstill?"}
    TRIG["Auto-trigger\nor Capture tap"]
    RSS{"Remote\nServer\nconfigured?"}
    REMOTE["HTTP POST\nto Railway Server\nServer-side DTW"]
    LOCAL["compute() Isolate\nLocal DTW Service\n12-dim pose vectors"]
    LOAD{"DTW library\nloaded?"}
    FLOAD["Load from\nCloud Firestore\nsign_animations"]
    MATCH["Top-K Sign\nMatches + Confidence"]
    CONF{"Confidence\n> 0.15?"}
    WORD["Word added to\nTranslateProvider\nsentence buffer"]
    DISP["📝 Translation\nOutput displayed"]
    NONE["Low confidence\n– ignored"]

    U1      --> CAM
    CAM     --> MP
    MP      --> LM
    LM      --> BUF
    BUF     --> STILL
    STILL   -- "≥ 8 frames still" --> TRIG
    STILL   -- "moving"           --> BUF
    TRIG    --> RSS
    RSS     -- yes  --> REMOTE
    RSS     -- no   --> LOCAL
    LOCAL   --> LOAD
    LOAD    -- no   --> FLOAD
    FLOAD   --> LOCAL
    LOAD    -- yes  --> MATCH
    REMOTE  --> MATCH
    MATCH   --> CONF
    CONF    -- yes --> WORD
    CONF    -- no  --> NONE
    WORD    --> DISP

    class U1                        user
    class CAM                       device
    class MP,LM                     ml
    class BUF,STILL,TRIG,CONF,NONE logic
    class RSS,LOAD                  logic
    class REMOTE,FLOAD              cloud
    class LOCAL,MATCH               ml
    class WORD,DISP                 output
```

---

## 3. Text-to-Sign Pipeline

```mermaid
flowchart TD
    classDef user   fill:#6366F1,stroke:#4F46E5,color:#fff
    classDef logic  fill:#8B5CF6,stroke:#7C3AED,color:#fff
    classDef cache  fill:#10B981,stroke:#059669,color:#fff
    classDef cloud  fill:#F59E0B,stroke:#D97706,color:#fff
    classDef render fill:#EF4444,stroke:#DC2626,color:#fff
    classDef output fill:#0EA5E9,stroke:#0284C7,color:#fff

    U2(["👤 User types text\nor uses voice input"])
    TP["TranslateProvider\nsetSentence()"]
    SP["SignPlayer\n_loadSentence()"]
    PAR["Split into words\nFetch ALL in parallel\nFuture.wait"]

    subgraph RESOLVE["Word Resolution  ·  per word"]
        C1{"signCache\nhit?"}
        C2{"Local Asset\nassets/signs/*.json"}
        C3{"Cloud Firestore\nsign_animations"}
        C4["Fingerspell\nletter-by-letter\n(parallel)"]
    end

    FRAMES["Ordered Frame\nSequences assembled"]
    SVG["SignPuddle SVG\nprefetch\n(background)"]
    ANIM["🎬 Skeleton Animator\nCustomPaint\n30 fps\nValueNotifier"]
    CTRL["Player Controls\nPlay / Pause / Speed / Skip"]

    U2   --> TP
    TP   --> SP
    SP   --> PAR
    PAR  --> C1
    C1   -- hit  --> FRAMES
    C1   -- miss --> C2
    C2   -- found --> FRAMES
    C2   -- miss  --> C3
    C3   -- found --> FRAMES
    C3   -- miss  --> C4
    C4             --> FRAMES
    FRAMES --> SVG
    FRAMES --> ANIM
    SVG   -. "ready" .-> ANIM
    ANIM  --> CTRL

    class U2         user
    class TP,SP,PAR,C1,C2,C3,C4 logic
    class FRAMES     logic
    class SVG        cloud
    class ANIM,CTRL  output
```

---

## 4. App User Flow

```mermaid
flowchart TD
    classDef screen  fill:#6366F1,stroke:#4F46E5,color:#fff,rx:10
    classDef decision fill:#F59E0B,stroke:#D97706,color:#fff
    classDef action  fill:#10B981,stroke:#059669,color:#fff,rx:6
    classDef external fill:#EF4444,stroke:#DC2626,color:#fff

    START(["📱 App Launch"])
    SPLASH["Splash Screen\nFirebase Auth check"]
    OB{"First\nlaunch?"}
    ONBOARD["Onboarding\n+ Preferences"]
    AUTH{"Logged\nin?"}
    LOGIN["Login / Register\nFirebase Auth"]
    MAIN["Main Navigator\nIndexedStack"]

    subgraph TABS["Bottom Navigation Tabs"]
        direction LR
        T1["🏠 Dashboard\nStreak · XP · Goals\nProgress · Friends"]
        T2["📚 Learn\nCategories → Lessons\nLearning Paths"]
        T3["🤟 Translate\nSign→Text\nText→Sign"]
        T4["🏆 Challenges\nDaily · Weekly\nGoals tracking"]
        T5["👤 Profile\nBadges · Stats\nSettings · Leaderboard"]
    end

    subgraph LEARN_FLOW["Learn Flow"]
        direction TB
        CAT["Category List"] --> LES["Lesson List"] --> DET["Lesson Detail\n+ Video"] --> COMP["Mark Complete\n→ XP + Badge check\n→ Goal update"]
    end

    subgraph QUIZ_FLOW["Quiz Flow"]
        direction TB
        QH["Quiz Home"] --> QS["Quiz Screen\nImage / Video / Text\n4 answer types"] --> QR["Results\n+ XP reward"]
    end

    subgraph SOCIAL["Social"]
        direction TB
        LEAD["Leaderboard\nGlobal · Friends"] 
        FRIENDS["Friends Screen\nAdd · View · Profile"]
    end

    START   --> SPLASH
    SPLASH  --> OB
    OB      -- yes --> ONBOARD --> AUTH
    OB      -- no  --> AUTH
    AUTH    -- no  --> LOGIN --> MAIN
    AUTH    -- yes --> MAIN
    MAIN    --> TABS
    T2      --> LEARN_FLOW
    T2      --> QUIZ_FLOW
    T5      --> SOCIAL

    class START,SPLASH                          action
    class OB,AUTH                               decision
    class ONBOARD,LOGIN                         screen
    class MAIN,T1,T2,T3,T4,T5                  screen
    class CAT,LES,DET,COMP                      screen
    class QH,QS,QR                              screen
    class LEAD,FRIENDS                          screen
```

---

## How to export for your poster

1. Go to **https://mermaid.live**
2. Paste one diagram's code block (without the triple backticks)
3. Click **Actions → Export PNG** (4× scale for poster quality) or **Export SVG**
4. Repeat for each diagram

**Recommended layout for A1/A2 poster:**
- Diagram 1 (System Architecture) → full-width top section
- Diagram 2 (Sign→Text) + Diagram 3 (Text→Sign) → side by side in middle
- Diagram 4 (User Flow) → bottom section
