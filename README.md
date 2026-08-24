# FitCoach — Smart Fitness Trainer App

A full-stack fitness application with smart food scanning, personalized diet & workout plans, and progress tracking.

**Live:** https://fitcoach.veridianabode.in  
**Status:** Production (iOS + Android)

---

## Table of Contents

1. [Product Requirements (PRD)](#product-requirements-prd)
2. [Application Flow](#application-flow)
3. [App Structure](#app-structure-flutter)
4. [Server Structure](#server-structure-nodejs)
5. [API Endpoints](#api-endpoints)
6. [Database Schema](#database-schema)
7. [Git Workflow](#git-workflow)
8. [Known Limitations & Future Work](#known-limitations--future-work)

---

## Product Requirements (PRD)

### Vision
An all-in-one fitness trainer app that combines smart food scanning, Indian diet plans, gym workout tracking, progress monitoring, and gamification — fully free, no subscription walls.

### Target Users
- Indian gym-goers and fitness enthusiasts (18–35 age group)
- People who want calorie/macro tracking without manual logging
- Users who want structured diet + workout plans tailored to their body

### Core Features

| Feature | Description | Status |
|---|---|---|
| **Auth** | Register, login, one-tap login, password change | ✅ Done |
| **Diet Scan** | Camera photo → identifies food, returns calories/protein/carbs/fiber | ✅ Done |
| **Barcode Scanner** | Scan Indian food barcodes for instant nutrition data | ✅ Done |
| **Food Search** | Search 50+ Indian foods by name | ✅ Done |
| **Personalized Diet Plan** | Veg/non-veg, cut/bulk/maintain, carb cycling, fiber targets | ✅ Done |
| **Workout Plans** | 7-day split, push/pull/legs/core/cardio/abs, calendar-based | ✅ Done |
| **Progress Tracking** | Weight, body fat, waist/neck/hip measurements with trend chart | ✅ Done |
| **Intermittent Fasting** | 16:8, 18:6, 20:4 timers with history | ✅ Done |
| **Streaks & Badges** | Gamification — current streak, longest streak, achievement badges | ✅ Done |
| **Water Reminders** | Configurable notifications | ✅ Done |
| **Gym Attendance** | Check-in tracking with calendar view | ✅ Done |
| **Admin Dashboard** | User management, activity logs, login tracking | ✅ Done |
| **Diet Logging** | Log scanned/manual meals, daily totals | ✅ Done |
| **Profile** | Photo, body metrics, fitness level, goals | ✅ Done |

### Success Metrics
- Diet scan accuracy > 85%
- App crash rate < 1%
- Server uptime > 99%
- User retention (weekly) > 40%

---

## Application Flow

### First Launch Flow
```
App Install → Splash Screen → Login/Register
    ↓
Register Screen:
  Name, Email, Password
  Gender, Age, Height, Weight
  Activity Level (sedentary/light/moderate/active/very_active)
  Fitness Level (beginner/intermediate/advanced)
  Goal (cut/bulk/maintain)
  Veg/Non-Veg
    ↓
Server Creates User → Generates BMI, BMR, Body Fat, TDEE
  → Generates Personalized Diet Plan (macros per meal)
  → Generates 7-Day Workout Plan
    ↓
Home Screen (7 tabs: Home/Diet/Workout/Calendar/Progress/Fasting/Profile)
```

### Daily Use Flow
```
Home Screen
├── Streak card (current streak, badges)
├── Quick stats (calories, protein, workouts)
│
Diet Tab
├── View today's meals (breakfast/lunch/dinner/snacks)
├── Diet Scan → Camera → identifies food → Log meal
├── Barcode Scan → Instant nutrition lookup
├── Food Search → Search Indian foods
├── Daily totals (calories, protein, carbs, fiber)
│
Workout Tab
├── View today's exercises (scrollable)
├── Check off completed exercises
├── Calendar-based day tracking (Day 1-7 rotating)
├── Past days: read-only, expandable
├── Future days: view-only, expandable
│
Progress Tab
├── Log weight, body fat, waist/neck/hip
├── Trend chart (weight over time)
├── Measurement summary
│
Fasting Tab
├── Start fasting (16:8, 18:6, 20:4)
├── Live countdown timer
├── Fasting history
│
Calendar Tab
├── Monthly gym attendance view
├── Check-in/out times
├── Duration tracking
│
Profile Tab
├── Edit body metrics, fitness level, goal
├── Change password
├── Toggle water reminders
├── Developer screen
```

### Auth Flow
```
Login → Token stored locally
    ↓
Token sent with every API request (Authorization: Bearer <token>)
    ↓
Token expires after 30 days
    ↓
One-Tap Login: enabled by user → device token stored → bypasses password
    ↓
One-Tap Token rotates on each use
    ↓
Change Password → Revokes all sessions
```

---

## App Structure (Flutter)

```
app/
├── lib/
│   ├── main.dart                    # Entry point, routes, theme
│   ├── config.dart                  # API base URL config
│   ├── theme.dart                   # AppColors, dark theme
│   │
│   ├── models/
│   │   └── models.dart              # User, WorkoutPlan, DietPlan, Exercise, etc.
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── splash_screen.dart   # Logo + auto-login check
│   │   │   ├── login_screen.dart    # Email/password login
│   │   │   ├── register_screen.dart # Full registration wizard
│   │   │   └── one_tap_consent.dart # One-tap login setup
│   │   │
│   │   ├── home/
│   │   │   ├── home_shell.dart      # 7-tab bottom navigation
│   │   │   └── home_screen.dart     # Dashboard with streak card + stats
│   │   │
│   │   ├── diet/
│   │   │   ├── diet_screen.dart     # Today's meals + daily totals
│   │   │   └── diet_scan_screen.dart # Smart scan + barcode + food search
│   │   │
│   │   ├── workout/
│   │   │   └── workout_screen.dart  # Exercises with checkboxes + calendar
│   │   │
│   │   ├── calendar/
│   │   │   └── calendar_screen.dart # Gym attendance monthly view
│   │   │
│   │   ├── progress/
│   │   │   └── progress_screen.dart # Weight/measurement charts + logging
│   │   │
│   │   ├── fasting/
│   │   │   └── fasting_screen.dart  # Timer + protocol selector + history
│   │   │
│   │   ├── profile/
│   │   │   └── profile_screen.dart  # Edit profile, photo upload
│   │   │
│   │   └── settings/
│   │       ├── settings_screen.dart # Water reminders, about
│   │       └── developer_screen.dart # Developer tools
│   │
│   ├── services/
│   │   ├── api_client.dart          # All API calls, token management
│   │   ├── session.dart             # Token persistence (SharedPreferences)
│   │   ├── notification_service.dart # Local notifications (water reminders)
│   │   └── profile_photo.dart       # Photo upload/compress
│   │
│   └── widgets/
│       ├── streak_card.dart         # Gamification card (fire gradient)
│       ├── ad_banner.dart           # Ad banner placeholder
│       ├── gym_check_in_sheet.dart  # Bottom sheet for gym check-in
│       ├── personal_training_card.dart
│       ├── profile_avatar.dart      # Circular avatar with initials fallback
│       ├── section_header.dart      # Reusable section header
│       └── stat_card.dart           # Reusable stat display card
│
├── pubspec.yaml                     # Dependencies
└── ios/, android/, macos/           # Platform configs
```

### Flutter Dependencies
| Package | Purpose |
|---|---|
| `http` | API calls |
| `shared_preferences` | Token/session persistence |
| `intl` | Date/number formatting |
| `flutter_local_notifications` | Water reminder notifications |
| `timezone` | Timezone support |
| `image_picker` | Camera/gallery access |
| `image_cropper` | Profile photo cropping |
| `url_launcher` | Open external links |

---

## Server Structure (Node.js)

```
server/
├── server.js                       # HTTP server, keepalive, timeout config
├── app.js                          # Express app, CORS, routes, admin dashboard, downloads
├── package.json                    # Dependencies
├── ecosystem.config.cjs            # PM2 process config
├── .env                            # Secrets (not in git)
├── .env.example                    # Template
│
├── src/
│   ├── storage.js                  # SQLite — users, activity, CRUD
│   ├── validation.js               # requireAuth middleware, input validation
│   ├── rateLimit.js                # In-memory rate limiter
│   ├── photoStorage.js             # Base64 photo save/serve
│   │
│   ├── routes/
│   │   ├── auth.js                 # Register, login, one-tap, logout, change-password
│   │   ├── profile.js              # Get/update profile
│   │   ├── plans.js                # Diet plan, workout plan, schedule, ticks, complete
│   │   ├── gym.js                  # Gym check-in/out, attendance
│   │   ├── dietScan.js             # Food scanning (Gemini), diet logging
│   │   ├── barcode.js              # Barcode lookup, food search, categories
│   │   ├── progress.js             # Weight/measurement CRUD + summary
│   │   ├── streaks.js              # Current/longest streak, badges, stats
│   │   ├── fasting.js              # Start/stop fasting, history
│   │   └── developer.js            # Developer tools endpoint
│   │
│   ├── services/
│   │   ├── bodyCalc.js             # BMI, BMR, body fat, TDEE, ideal weight
│   │   ├── dietPlan.js             # Macro calculation, meal planning, carb cycling
│   │   └── workoutPlan.js          # 7-day workout generation, muscle group rotation
│   │
│   └── data/
│       ├── exercises.js            # 15 muscle groups, 100+ exercises
│       ├── foods.js                # Basic food nutrition data
│       └── foodDatabase.js         # 50+ Indian foods + 30 barcoded items with micronutrients
│
└── data/
    └── fitcoach.db                 # SQLite database
```

### Server Dependencies
| Package | Purpose |
|---|---|
| `express` | HTTP framework |
| `cors` | Cross-origin requests |
| `dotenv` | Environment variable loading |
| `better-sqlite3` | SQLite database (sync, fast) |

---

## API Endpoints

### Auth (`/api/auth`)
| Method | Path | Description |
|---|---|---|
| POST | `/register` | Create account, returns token |
| POST | `/login` | Email/password login |
| POST | `/one-tap-login` | Token-based login (no password) |
| POST | `/enable-one-tap` | Enable one-tap for device |
| POST | `/disable-one-tap` | Disable one-tap |
| POST | `/logout` | Invalidate session |
| POST | `/change-password` | Change password, revokes all sessions |

### Profile (`/api/profile`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | Get user profile |
| PUT | `/` | Update profile (body metrics, goal, etc.) |

### Plans (`/api/plans`)
| Method | Path | Description |
|---|---|---|
| GET | `/assessment` | Body metrics (BMI, BMR, body fat, TDEE) |
| GET | `/diet` | Personalized diet plan (macros per meal) |
| GET | `/workout` | 7-day workout plan with exercises |
| POST | `/workout/ticks` | Save exercise checkboxes |
| POST | `/workout/complete` | Mark day complete + update streaks |
| POST | `/workout/uncomplete` | Undo completed day |
| GET | `/schedule` | Weekly schedule |

### Gym (`/api/gym`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | Get gym attendance |
| PUT | `/` | Check in/out |
| PUT | `/attendance` | Update attendance record |

### Diet Scan (`/api/diet`)
| Method | Path | Description |
|---|---|---|
| POST | `/scan` | Food scan (Gemini Vision) |
| POST | `/log` | Log a food item |
| GET | `/logged` | Today's logged meals + totals |

### Barcode (`/api/barcode`)
| Method | Path | Description |
|---|---|---|
| GET | `/lookup/:barcode` | Lookup barcode → nutrition info |
| GET | `/search?q=` | Search foods by name |
| GET | `/categories` | List food categories |

### Progress (`/api/progress`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | All progress entries |
| GET | `/summary` | Current/starting weight, trends |
| POST | `/` | Log weight/measurement entry |
| DELETE | `/:id` | Delete entry |

### Streaks (`/api/streaks`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | Current streak, longest streak, badges, total stats |

### Fasting (`/api/fasting`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | Active fast + history |
| POST | `/start` | Start fasting (protocol: 16:8, 18:6, 20:4) |
| POST | `/stop` | Stop active fast |

### Developer (`/api/developer`)
| Method | Path | Description |
|---|---|---|
| GET | `/` | Developer info |

### Public
| Method | Path | Description |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/download` | Download page (APK + IPA) |
| GET | `/download.apk` | Android APK |
| GET | `/download.ipa` | iOS IPA |

---

## Database Schema

### SQLite

**users** table:
| Column | Type | Description |
|---|---|---|
| id | TEXT PK | UUID |
| user_id | TEXT UNIQUE | Secondary ID |
| email | TEXT UNIQUE | Email address |
| token | TEXT | Session token |
| token_expires_at | TEXT | 30-day expiry |
| remember_token | TEXT | One-tap token |
| remember_expires_at | TEXT | 90-day expiry |
| data | TEXT (JSON) | All user data blob |

**activity** table:
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| user_id | TEXT | FK → users.id |
| email | TEXT | User email |
| action | TEXT | Action type |
| ip | TEXT | Client IP |
| ts | TEXT | ISO timestamp |

**Activity actions:** `register`, `login`, `one-tap-login`, `logout`, `workout_complete`, `diet_scan`, `diet_log`

---

## Git Workflow

### Repositories
| Repo | Branch |
|---|---|
| fitcoach-app | main |
| fitcoach-server | main |

### Commit Convention
```
feat: <description>      — New feature
fix: <description>       — Bug fix
security: <description>  — Security improvement
chore: <description>     — Maintenance, config changes
docs: <description>      — Documentation
```

### What to Commit
| Location | Commit To | Notes |
|---|---|---|
| `app/lib/**` | fitcoach-app | Flutter source |
| `app/pubspec.yaml` | fitcoach-app | Dependencies |
| `server/app.js` | fitcoach-server | Routes, dashboard, config |
| `server/src/**` | fitcoach-server | Business logic, routes |
| `server/package.json` | fitcoach-server | Dependencies |
| `server/ecosystem.config.cjs` | fitcoach-server | PM2 config |

### What NOT to Commit
| File | Reason |
|---|---|
| `.env` | Secrets (API keys, auth tokens) |
| `data/fitcoach.db` | User data |
| `node_modules/` | Dependencies |
| `build/` | Flutter build artifacts |
| `.dart_tool/` | Dart cache |
| `ios/Pods/` | CocoaPods cache |

---

## Known Limitations & Future Work

| Gap | Priority | Notes |
|---|---|---|
| No wearable sync | Medium | Apple Health / Google Fit integration |
| No voice logging | Low | Speech-to-text for meals |
| No recipe library | Low | Meal suggestions with recipes |
| No social features | Low | Challenges, leaderboards |
| No App Store listing | High | Needs TestFlight / Play Console |
| No on-device ML | Low | CoreML/TFLite for offline scan |
| No dark mode toggle | Low | Currently always dark |
| No data export | Medium | CSV/PDF export of progress |
