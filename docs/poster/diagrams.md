# Gestura — Poster Diagrams

> **How to render:** Go to https://mermaid.live  
> Paste the code block below (without the triple backtick lines) into the editor on the left.  
> Then click **Actions → Export PNG** (use 4× scale for poster quality).

---

## Diagram 1 — System Architecture

Paste this into mermaid.live:

```
flowchart TB
    classDef ui       fill:#6366F1,stroke:#4F46E5,color:#fff,font-weight:bold
    classDef state    fill:#8B5CF6,stroke:#7C3AED,color:#fff,font-weight:bold
    classDef service  fill:#0EA5E9,stroke:#0284C7,color:#fff,font-weight:bold
    classDef cache    fill:#10B981,stroke:#059669,color:#fff,font-weight:bold
    classDef external fill:#F59E0B,stroke:#D97706,color:#fff,font-weight:bold
    classDef ml       fill:#EF4444,stroke:#DC2626,color:#fff,font-weight:bold

    subgraph UI["Flutter UI — Presentation Layer"]
        direction LR
        NAV["Main Navigator\nIndexedStack"]
        DB["Dashboard"]
        LN["Learn & Lessons"]
        TR["Translate"]
        CH["Challenges"]
        PR["Profile & Badges"]
        QZ["Quiz"]
    end

    subgraph STATE["State Management — Provider Pattern"]
        direction LR
        AP["Auth Provider"]
        PP["Progress Provider"]
        CP["Challenge Provider"]
        BP["Badge Provider"]
        NP["Notification Provider"]
        TP["Translate Provider"]
        LP["Lesson Provider"]
    end

    subgraph SVC["Services Layer"]
        direction LR
        FS["Firestore Service"]
        NS["Notification Service"]
        BS["Badge Service"]
        CLS["Cloudinary Service"]
        FRS["Friend Service"]
        RSS["RemoteSign Service"]
    end

    subgraph ML["Sign Recognition Pipeline"]
        direction LR
        WV["MediaPipe Holistic\nWebView — 15 fps"]
        DTW["DTW Service\ncompute() Isolate"]
        SP["Sign Player\nSkeleton Painter"]
    end

    subgraph CACHE["On-Device Cache"]
        direction LR
        AC["AppCache\nIn-Memory TTL"]
        HV["Hive\nOffline DB"]
        SHP["Shared Preferences"]
    end

    subgraph CLOUD["Cloud & External Services"]
        direction LR
        FA[("Firebase Auth")]
        CF[("Cloud Firestore")]
        FCM["Firebase Cloud\nMessaging"]
        CDN["Cloudinary CDN"]
        MCDN["MediaPipe CDN\nModels"]
        SPD["SignPuddle\nSVG API"]
    end

    UI    --> STATE
    STATE --> SVC
    STATE --> ML
    SVC   --> CACHE
    SVC   --> CLOUD
    ML    --> CLOUD
    CACHE -.->|cache hit| SVC

    class NAV,DB,LN,TR,CH,PR,QZ       ui
    class AP,PP,CP,BP,NP,TP,LP        state
    class FS,NS,BS,CLS,FRS,RSS        service
    class WV,DTW,SP                   ml
    class AC,HV,SHP                   cache
    class FA,CF,FCM,CDN,MCDN,SPD     external
```

---

## Diagram 2 — Sign-to-Text Recognition Pipeline

Paste this into mermaid.live:

```
flowchart TD
    classDef user    fill:#6366F1,stroke:#4F46E5,color:#fff,font-weight:bold
    classDef device  fill:#0EA5E9,stroke:#0284C7,color:#fff,font-weight:bold
    classDef ml      fill:#EF4444,stroke:#DC2626,color:#fff,font-weight:bold
    classDef logic   fill:#8B5CF6,stroke:#7C3AED,color:#fff,font-weight:bold
    classDef output  fill:#10B981,stroke:#059669,color:#fff,font-weight:bold
    classDef cloud   fill:#F59E0B,stroke:#D97706,color:#fff,font-weight:bold

    U1(["User performs\nhand sign"])
    CAM["Device Camera\ngetUserMedia"]
    MP["MediaPipe Holistic\nIn-App WebView\n15 fps"]
    LM["Pose + Hand Landmarks\n543 key points extracted"]
    BUF["Rolling Frame Buffer\n12 – 30 frames"]
    STILL{"Hand\nstill?"}
    TRIG["Auto-trigger\nor Capture tap"]
    RSS{"Remote server\nconfigured?"}
    REMOTE["HTTP POST\nRailway Server\nServer-side DTW"]
    LOCAL["compute Isolate\nLocal DTW Service\n12-dim pose vectors"]
    LOAD{"DTW library\nloaded?"}
    FLOAD["Load from\nCloud Firestore\nsign_animations"]
    MATCH["Top-K Sign Matches\n+ Confidence Score"]
    CONF{"Confidence\n> 0.15?"}
    WORD["Word added to\nTranslateProvider\nsentence buffer"]
    DISP["Translation Output\ndisplayed to user"]
    NONE["Low confidence\nignored — keep signing"]

    U1     --> CAM
    CAM    --> MP
    MP     --> LM
    LM     --> BUF
    BUF    --> STILL
    STILL  -->|8 frames still| TRIG
    STILL  -->|moving| BUF
    TRIG   --> RSS
    RSS    -->|yes| REMOTE
    RSS    -->|no| LOCAL
    LOCAL  --> LOAD
    LOAD   -->|no| FLOAD
    FLOAD  --> LOCAL
    LOAD   -->|yes| MATCH
    REMOTE --> MATCH
    MATCH  --> CONF
    CONF   -->|yes| WORD
    CONF   -->|no| NONE
    WORD   --> DISP

    class U1                user
    class CAM               device
    class MP,LM             ml
    class BUF,STILL,TRIG    logic
    class RSS,LOAD,CONF     logic
    class NONE              logic
    class REMOTE,FLOAD      cloud
    class LOCAL,MATCH       ml
    class WORD,DISP         output
```

---

## Diagram 3 — Text-to-Sign Pipeline

Paste this into mermaid.live:

```
flowchart TD
    classDef user   fill:#6366F1,stroke:#4F46E5,color:#fff,font-weight:bold
    classDef logic  fill:#8B5CF6,stroke:#7C3AED,color:#fff,font-weight:bold
    classDef cache  fill:#10B981,stroke:#059669,color:#fff,font-weight:bold
    classDef cloud  fill:#F59E0B,stroke:#D97706,color:#fff,font-weight:bold
    classDef render fill:#EF4444,stroke:#DC2626,color:#fff,font-weight:bold
    classDef output fill:#0EA5E9,stroke:#0284C7,color:#fff,font-weight:bold

    U2(["User types text\nor uses voice input"])
    TP["TranslateProvider\nsetSentence()"]
    SP["SignPlayer\n_loadSentence()"]
    PAR["Split into words\nAll words fetched in parallel\nFuture.wait"]

    C1{"Sign Cache\nhit?"}
    C2{"Local Asset\nassets/signs/word.json"}
    C3{"Cloud Firestore\nsign_animations"}
    C4["Fingerspell\nLetter by letter\n(parallel fetch)"]

    FRAMES["Ordered Frame Sequences\nassembled in word order"]
    SVG["SignPuddle SVG\nprefetch — background"]
    ANIM["Skeleton Animator\nCustomPaint at 30 fps\nValueNotifier — no rebuilds"]
    CTRL["Player Controls\nPlay / Pause / Speed / Skip"]

    U2     --> TP
    TP     --> SP
    SP     --> PAR
    PAR    --> C1
    C1     -->|hit — instant| FRAMES
    C1     -->|miss| C2
    C2     -->|found| FRAMES
    C2     -->|miss| C3
    C3     -->|found| FRAMES
    C3     -->|miss| C4
    C4     --> FRAMES
    FRAMES --> ANIM
    FRAMES --> SVG
    SVG    -.->|SVG ready| ANIM
    ANIM   --> CTRL

    class U2             user
    class TP,SP,PAR      logic
    class C1             cache
    class C2             logic
    class C3             cloud
    class C4             logic
    class FRAMES         logic
    class SVG            cloud
    class ANIM,CTRL      output
```

---

## Diagram 4 — App User Flow

Paste this into mermaid.live:

```
flowchart TD
    classDef screen   fill:#6366F1,stroke:#4F46E5,color:#fff,font-weight:bold
    classDef decision fill:#F59E0B,stroke:#D97706,color:#1a1a1a,font-weight:bold
    classDef action   fill:#10B981,stroke:#059669,color:#fff,font-weight:bold

    START(["App Launch"])
    SPLASH["Splash Screen\nFirebase Auth check"]
    OB{"First\nlaunch?"}
    ONBOARD["Onboarding\n+ Preferences"]
    AUTH{"Logged\nin?"}
    LOGIN["Login / Register\nFirebase Auth"]
    MAIN["Main Navigator\nBottom Tab Bar"]

    DB["Dashboard\nStreak · XP · Daily Goals\nProgress · Friends activity"]
    LN["Learn\nCategories & Lessons\nLearning Paths"]
    TR["Translate\nSign to Text\nText to Sign"]
    CH["Challenges\nDaily & Weekly Goals\nProgress tracking"]
    PR["Profile\nBadges · Stats\nSettings · Leaderboard"]

    CAT["Category List"]
    LES["Lesson List"]
    DET["Lesson Detail\nSign video / animation"]
    COMP["Mark Complete\nXP earned\nBadge check\nGoal update"]

    QH["Quiz Home"]
    QS["Quiz Screen\n4 answer types\nImage / Video / Text / Sign"]
    QR["Quiz Results\nScore + XP reward"]

    LEAD["Leaderboard\nGlobal & Friends"]
    FRIENDS["Friends\nAdd · View · Profile"]

    START   --> SPLASH
    SPLASH  --> OB
    OB      -->|yes| ONBOARD
    OB      -->|no| AUTH
    ONBOARD --> AUTH
    AUTH    -->|no| LOGIN
    AUTH    -->|yes| MAIN
    LOGIN   --> MAIN
    MAIN    --> DB
    MAIN    --> LN
    MAIN    --> TR
    MAIN    --> CH
    MAIN    --> PR
    LN      --> CAT
    CAT     --> LES
    LES     --> DET
    DET     --> COMP
    LN      --> QH
    QH      --> QS
    QS      --> QR
    PR      --> LEAD
    PR      --> FRIENDS

    class START,SPLASH         action
    class OB,AUTH              decision
    class ONBOARD,LOGIN        screen
    class MAIN                 action
    class DB,LN,TR,CH,PR       screen
    class CAT,LES,DET,COMP     screen
    class QH,QS,QR             screen
    class LEAD,FRIENDS         screen
```

