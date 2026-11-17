# 🎮 Unblock Puzzle: Slide Escape

> **A mobile slide-block puzzle game built with Godot 4.7.2 Mono.**
> Slide colored blocks to free the hero block through the exit — 200 hand-crafted levels, 4 worlds, 3 coin-powered boosters, daily challenges, and full Play Store integration.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Requirements](#requirements)
3. [Directory Structure](#directory-structure)
4. [World & Level Design](#world--level-design)
5. [Core Mechanics](#core-mechanics)
6. [Special Features](#special-features)
7. [Booster System](#booster-system)
8. [Autoloads](#autoloads)
9. [Save System](#save-system)
10. [Localization](#localization)
11. [Monetization](#monetization)
12. [Google Play Games Services (GPGS)](#google-play-games-services-gpgs)
13. [Running & Testing Locally](#running--testing-locally)
14. [Verification Test Suites](#verification-test-suites)
15. [Android Build & Play Store](#android-build--play-store)
16. [Known Limitations](#known-limitations)

---

## Project Overview

| Field | Value |
|---|---|
| **App Name** | Unblock Puzzle: Slide Escape |
| **Package ID** | `com.colorslide.unblockescape` |
| **Engine** | Godot 4.7.2 Mono (C# + GDScript) |
| **Platform** | Android (primary) · Desktop (dev/test) |
| **Levels** | 200 across 4 worlds |
| **Languages** | 8 (EN, ES, DE, FR, JA, PT, KO, ID) |
| **Monetization** | Google AdMob banners/interstitials + IAP coin packs |
| **GPGS** | Cloud Save + Leaderboards + Achievements |

---

## Requirements

- **Godot 4.7.2 Mono** (C# .NET 8 SDK required)
- **Android SDK** — min API 24, target API 35
- **Android Gradle Plugin / JDK 21**
- **Native AdMob Plugin** (`AdMobPlugin.java` + Google Mobile Ads SDK `23.6.0`)
- **Native Firebase Analytics Plugin** (`FirebaseAnalyticsPlugin.java` + Firebase BoM `35.2.0`)
- **Production Keystore**: `release.keystore` (alias: `colorslide_release`, pass: `colorslide2026`)

> Configured AdMob IDs:
> - App ID: `ca-app-pub-6827648916951660~3848367705`
> - Rewarded Ad Unit ID: `ca-app-pub-6827648916951660/1711113358`
> - Complete Play Store submission details: See `PLAYSTORE_UPLOAD_GUIDE.md`

---

## Directory Structure

```
d:/ColorSlide/
├── scenes/                   # All .tscn scene files
│   ├── Main.tscn             # In-game play scene
│   ├── MainMenu.tscn         # Home screen
│   ├── LevelSelect.tscn      # World/level picker with progress bar
│   ├── GameBoard.tscn        # Slide board control
│   ├── Block.tscn            # Individual block node
│   ├── WinDialog.tscn        # Level complete modal
│   ├── DailyChallengeDialog.tscn
│   ├── ShopDialog.tscn       # Coin & skin shop
│   ├── PiggyBankDialog.tscn  # Piggy bank smash mechanic
│   ├── LuckyWheelDialog.tscn # Spin-to-win daily wheel
│   ├── BlitzModeDialog.tscn  # Rush Hour Blitz setup
│   ├── StarChestDialog.tscn  # Milestone star chest reveal
│   ├── SettingsDialog.tscn   # Sound / Haptics / Language
│   ├── BoosterGuideDialog.tscn  # First-use booster tutorial
│   └── TutorialGuide.tscn    # In-level hint overlay
│
├── scripts/                  # All GDScript (.gd) files
│   ├── game_manager.gd       # ★ Core autoload: state, saves, daily, boosters
│   ├── sound_manager.gd      # ★ Autoload: ASMR audio + haptics
│   ├── monetization_manager.gd # ★ Autoload: AdMob, IAP, GPGS
│   ├── main.gd               # In-game controller (HUD, boosters, dialogs)
│   ├── game_board.gd         # Board rendering, sliding logic, booster visuals
│   ├── block.gd              # Individual block behavior + skin/theme system
│   ├── level_select.gd       # World tabs, progress bars, level grid
│   ├── main_menu.gd          # Home screen, daily streak banner, navigation
│   ├── win_dialog.gd         # Stars, crowns, next level flow
│   ├── tutorial_guide.gd     # Step-by-step hint overlay per level
│   ├── shop_dialog.gd        # Skin purchase + coin pack IAP
│   ├── settings_dialog.gd    # Sound, haptics, language toggles
│   ├── booster_guide_dialog.gd  # Booster guide card carousel
│   ├── daily_challenge_dialog.gd  # Daily puzzle result + streak UI
│   ├── blitz_mode_dialog.gd  # 60s arcade mode timer + leaderboard
│   ├── lucky_wheel_dialog.gd # 24hr spin wheel animation
│   ├── piggy_bank_dialog.gd  # Piggy smash particle + claim
│   ├── hero_preview.gd       # Pet character preview in menu
│   └── star_chest_dialog.gd  # Chest opening animation
│
├── levels/
│   └── levels.json           # 200 levels (128,416 lines) — full board definitions
│
├── localization/
│   └── strings.csv           # 8-language string table (EN/ES/DE/FR/JA/PT/KO/ID)
│
├── assets/                   # Sprites, icons, fonts, audio
│
├── android/
│   └── plugins/              # AdMob, GodotPlayBilling, PlayGames .aar + .gdap files
│
└── scripts/verify_*.gd       # Headless test suites (7 total)
```

---

## World & Level Design

| World | Levels | Theme | Unique Mechanic |
|---|---|---|---|
| **World 1 — Beginner Escape** | 1–50 | Clean blue grid | Standard sliding, tutorial L1-L4 |
| **World 2 — Strategic Traffic Jam** | 51–100 | Cyberpunk midnight | Dense block layouts, multi-block chains |
| **World 3 — Frost Cavern** | 101–150 | Icy blue-white | ❄️ Ice-frozen blocks (thaw by sliding adjacent) |
| **World 4 — Laser Facility** | 151–200 | Deep red-neon | ⚡ Laser barriers + switch pads to disable lasers |

Each level has:
- `level_id`, `world_id`, `title` metadata
- `board` grid (block positions, orientations, colors)
- `optimal_moves` (par score for Master Crown 👑)
- `hints` (step-by-step walkthrough for TutorialGuide)

---

## Core Mechanics

### Slide Movement
- Drag/tap blocks horizontally or vertically along their axis
- Blocks cannot cross each other
- Hero block (cyan/red) must reach the exit gate

### Ice Blocks (World 3)
- Frozen blocks display a frost overlay — cannot be moved directly
- Slide any adjacent block past a frozen block → it thaws (1 or 2 passes based on `freeze_level`)
- Visual: frost particle effect on thaw

### Laser Barriers (World 4)
- Laser beams block movement across their row/column
- Step on a switch pad (green) to toggle the laser off
- Laser activates again if the block leaves the switch

### Undo System
- Unlimited undo (tracks full board state stack)
- Booster actions are undo-able: inventory is refunded automatically on undo

---

## Special Features

### 🔥 Daily Challenge (Daily Mind Forge)
- One unique puzzle per calendar day — same globally for all players
- **Auto-generated** using deterministic seed from date string hash
- **Difficulty guaranteed**: BFS solver confirms 14–28 optimal moves
- Rewards: +100 Coins + +1 Daily Streak on completion
- **7-day streak** → Gold Chest (300 coins + booster items)

### 📅 Daily Streak System
- Streak counter on Main Menu banner
- Breaks if the player misses a day
- Best streak tracked and displayed

### 🐷 Piggy Bank (Coin Vault)
- Earns +25 coins per level solved, stored in Piggy up to 1000 coins max
- Tap the pig icon to smash and claim all banked coins
- Particle smash animation + satisfying sound

### 🎡 Lucky Wheel
- One free spin per 24 hours
- Prizes: Coin packs (50–300), Hints (1–3), Skin unlocks
- Animated wheel with easing spin

### ⚡ Rush Hour Blitz (Arcade Mode)
- 60-second time attack on a hand-picked set of levels
- +5 seconds bonus per correct move combo
- Global leaderboard via GPGS (`leaderboard_blitz_rush_hour`)

### 👑 Master Crown System
- Each level has an `optimal_moves` par
- Solve at or under par → earn a Master Crown badge
- Crown count tracked per level and shown in LevelSelect

### 🛒 Cosmetics Shop (Block Skins)
| Skin | Cost | Description |
|---|---|---|
| Classic Vibrant | Free | Clean colorful modern finish |
| Cyber Neon | 300 🪙 | Glowing electric cyan & magenta |
| Artisan Woodcraft | 500 🪙 | Mahogany grain + carved bevels |
| Obsidian Gem | 800 🪙 | Lustrous crystal jewel glass |
| Royal Gold | 1200 🪙 | 24k gold edges + royal star insignia |

### 🌟 Milestone Star Chests
- Every 10 levels: collect accumulated stars to open a chest
- Chests reward coins, hints, and rare boosters

### 🐾 Pet Rescue Mode
- Toggleable hero block character theme per world
- Cute character animations instead of plain colored blocks

---

## Booster System

Unlocked automatically at **Level 5** (first-time players receive a free starter pack of 3 each).
Boosters can be bought with coins or earned from chests/wheel.

| Booster | Cost | Function |
|---|---|---|
| 🔨 **Sledgehammer (Smash)** | 100 🪙 | Permanently removes 1 obstacle block |
| ✂️ **Shrink Ray** | 75 🪙 | Reduces a 3-cell block to 2, or 2-cell to 1 |
| 🧲 **Crane Picker** | 90 🪙 | Lifts any trapped block and drops it elsewhere |

### Booster UX Flow
1. Tap booster button → `STEP 1/2` prompt appears in status bar
2. Tap target block on board (pulsing outline highlights valid targets)
3. For Crane: `STEP 2/2` prompt → tap empty cell to drop
4. Tap button again to cancel without spending coins
5. **Undo**: booster action is undoable → 100% coin refund

### First-Use Guide
- On Level 5 entry: The board loads immediately with an attention pulse on the booster bar
- The `BoosterGuideDialog` opens naturally after the player's first move, or upon tapping the `❓ GUIDE` button
- Shows numbered `①②③` card per booster with step instructions
- Accessible anytime via ❓ button on booster bar

---

## Autoloads

Registered in `project.godot` → `[autoload]` section:

| Singleton | Script | Role |
|---|---|---|
| `GameManager` | `scripts/game_manager.gd` | Level state, save/load, daily challenge, boosters, coins, crowns, skins |
| `SoundManager` | `scripts/sound_manager.gd` | ASMR procedural audio synthesis, haptics, mute/unmute |
| `MonetizationManager` | `scripts/monetization_manager.gd` | AdMob, IAP billing, GPGS sign-in, cloud save, leaderboards, analytics |

---

## Save System

**Save file**: `user://colorslide_save.json`

Persisted fields (all serialized as JSON):
```
highest_unlocked_level, current_level_index,
total_coins, hints_count, stars_earned{}, master_crowns{},
daily_streak, best_daily_streak, last_daily_date, completed_dailies[],
opened_chests[], unlocked_skins[], equipped_skin,
piggy_coins, last_wheel_spin_time,
booster_sledgehammers, booster_shrinks, booster_cranes, boosters_unlocked,
blitz_high_score, pet_rescue_enabled, colorblind_mode,
has_rated_prompted, language_code
```

Load via `GameManager.load_progress()` on `_ready()`.
Save via `GameManager.save_progress()` after every state-changing event.

---

## Localization

- **File**: `res://localization/strings.csv`
- **Format**: First column = key, remaining columns = EN, ES, DE, FR, JA, PT, KO, ID
- **Runtime**: `TranslationServer.set_locale(language_code)` + `tr("KEY")` in scripts
- **Language switch**: Settings dialog → cycles through 8 locales → auto-saves

Key string prefixes:
- `BTN_*` — button labels
- `MSG_*` — in-game status messages
- `LBL_*` — UI field labels
- `WIN_*` — win dialog copy
- `SHOP_*` — shop/IAP copy

---

## Monetization

### AdMob
- **App ID**: `ca-app-pub-6827648916951660~3848367705`
- **Rewarded Ad Unit ID**: `ca-app-pub-6827648916951660/1711113358`
- **Rewarded Video Ad Rewards**:
  - **Special Features / Boosters (Level 5+)**: Watch a short video ad to claim **+1 Free Booster** (🔨 Smash, ✂️ Shrink, 🧲 Crane) immediately!
  - **Walkthrough Hints**: Watch a short video ad to claim **+1 Free Hint** (`gm.add_hints(1)`), available on hint button & in Shop!
- **Banner**: shown on MainMenu and LevelSelect
- **Interstitial**: shown every ~5 level completions (frequency-capped)

### In-App Purchases (IAP)
| SKU | Price | Product |
|---|---|---|
| `coins_200` | \$0.99 | 200 coins |
| `coins_600` | \$2.49 | 600 coins |
| `coins_1500` | \$4.99 | 1500 coins |
| `remove_ads` | \$2.99 | Remove all ads forever |

### Economy Balance
- Starting coins: 150 (+ 3 free boosters of each type at Level 5)
- Tiered Level Completion Rewards:
  - **Optimal Master Solution (3★ / Par Crown - less moves)**: **120 coins**
  - **Standard Level Completion (2★)**: **100 coins**
  - **More Moves Used (1★)**: **80 coins**
  - **Beginner Bonus (Levels 1–10)**: +25 extra coins
  - **Pure Booster-Free Crown**: +25 bonus coins
- Additional Sources: +100 daily puzzle, +50–300 from Lucky Wheel, +25 per level deposited into Piggy Bank vault
- Booster costs: 75–100 🪙 (Shrink Ray: 75 🪙, Crane Picker: 90 🪙, Sledgehammer: 100 🪙)

---

## Google Play Games Services (GPGS)

Plugin: `GodotPlayGames` / `PlayGamesServices` singleton (auto-detected at runtime).
Falls back gracefully to offline mode if unavailable.

| Feature | ID / Notes |
|---|---|
| **Sign-in** | `gpgs_sign_in()` called on app start |
| **Cloud Save** | `PGSSnapshot` — saves `colorslide_save.json` to cloud on level complete |
| **Blitz Leaderboard** | `leaderboard_blitz_rush_hour` |
| **Achievements** | Unlocked via `unlock_achievement(id)` on milestones |

---

## Running & Testing Locally

### Set Godot path (PowerShell)
```powershell
$godot = "C:\Users\RAM\Downloads\Godot_v4.7.2-stable_mono_win64\...\Godot_v4.7.2-stable_mono_win64_console.exe"
```

### Run the game (desktop preview)
```powershell
& $godot --path "d:\ColorSlide"
```

### Run all 7 test suites
```powershell
$scripts = @(
	"scripts/verify_200_gameplay.gd",
	"scripts/verify_retention_features.gd",
	"scripts/verify_interactive_features.gd",
	"scripts/verify_ice_melting.gd",
	"scripts/verify_ui_redesign.gd",
	"scripts/verify_playstore_readiness.gd",
    "scripts/verify_boosters_and_daily.gd"
)
foreach ($s in $scripts) {
	& $godot --headless --path "d:\ColorSlide" -s $s
	if ($LASTEXITCODE -ne 0) { Write-Error "FAILED: $s"; break }
}
```

---

## Verification Test Suites

| Script | Tests |
|---|---|
| `deep_audit_whole_app.gd` | Audits all 16 scenes, 64 localization keys, 11 audio synthesizers, 200 levels, Monetization API, Atomic Save Version 3 & Player Stats |
| `verify_all_200_levels_and_hints.gd` | Exhaustive 200-level audit: 4,068 hint steps simulated, 100% solvable pass rate, step-by-step difficulty progression |
| `verify_200_gameplay.gd` | 200 levels load, 4 worlds, LevelSelect tabs, hint system |
| `verify_retention_features.gd` | Daily streak, daily date seed, chest milestone rewards |
| `verify_interactive_features.gd` | Piggy Bank smash, Lucky Wheel, Master Crown, Blitz Mode, scene hierarchy |
| `verify_ice_melting.gd` | World 3 ice block thaw by adjacent slide (freeze_level 1 & 2) |
| `verify_ui_redesign.gd` | ASMR sound synthesizers, button sizes, font sizes, all 8 modals load |
| `verify_playstore_readiness.gd` | 15 checks: package ID, IAP SKUs, AdMob IDs, strings.csv, settings |
| `verify_boosters_and_daily.gd` | 10 checks: daily auto-gen (14-28 moves), booster economics, audio, board interactions, Level 5 gating, guide dialog, exit path glow, undo refund, LevelSelect stats, haptics, GPGS |

**Current status: ALL 9 SUITES PASS 100%**

---

## Android Build & Play Store

1. **Production Release AAB**:
   - Location: `build/UnblockPuzzleSlideEscape.aab` (61.1 MB)
   - Signed with `release.keystore` (validity 10,000 days).
   - Bundles both `arm64-v8a` and `armeabi-v7a` architectures.
   - Ready for immediate upload to Google Play Console.
2. **Direct Phone Testing APK**:
   - Location: `build/UnblockPuzzleSlideEscape.apk` (173.6 MB)
   - Fully self-contained with all game assets embedded for direct USB/ADB sideloading.
3. **Step-by-Step Play Store Upload Guide**:
   - For all store listing copy-pastes, descriptions, AdMob linking, and Data Safety questionnaires, see [PLAYSTORE_UPLOAD_GUIDE.md](file:///D:/ColorSlide/PLAYSTORE_UPLOAD_GUIDE.md).

---

## Known Limitations

- **GPGS / AdMob plugins**: Only activate on a real Android device — headless tests mock them via null checks
- **Haptic feedback**: Requires `Input.vibrate_handheld()` — no effect on desktop
- **Leaderboard UI**: Calls GPGS native overlay — requires Play Games app installed on device
- **Daily puzzle BFS**: Runs at app start for today's date only; no pre-generation cache
- **Custom font for ①②③ glyphs**: Relies on Godot's default NotoSans — verify on low-end Android that Unicode circled numbers render correctly
- **IAP products**: Must be created manually in Play Console before testing on device

---

*Built with ❤️ using Godot 4.7.2 Mono — © 2026 ColorSlide Studio*
#   c o l o r s l i d e  
 