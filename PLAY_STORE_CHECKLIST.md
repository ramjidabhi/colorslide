# Google Play Launch & Organic Growth Checklist

## 1. Store Listing Metadata (ASO Ready)
- **App Title (28/30 chars):** `Unblock Puzzle: Slide Escape`
- **Short Description (78/80 chars):** `Slide blocks to escape! 200 brain levels, ice blocks, laser gates & 60s Blitz.`
- **Package ID:** `com.colorslide.unblockescape` (update in `export_presets.cfg` and `scripts/game_manager.gd` `PLAY_STORE_PACKAGE_ID` if changed).

## 2. Long Description Template (4,000 chars max)
> Slide the obstacles, clear the path, and escape the Red Block!
>
> **Unblock Puzzle: Slide Escape** is a crisp, tactile sliding block puzzle game with 200 handcrafted brain-teasing levels across 4 unique worlds — 100% playable offline with no Wi-Fi required.
>
> **4 WORLDS & UNIQUE MECHANICS:**
> • **World 1 – Beginner Escape (Levels 1–50):** Classic sliding unblock foundations.
> • **World 2 – Strategic Traffic Jam (Levels 51–100):** Heavy 3-cell trucks and tricky deadlock puzzles.
> • **World 3 – Frost Cavern (Levels 101–150):** Frozen ice blocks! Slide adjacent blocks to melt the ice.
> • **World 4 – Laser Facility (Levels 151–200):** Step on floor switches to deactivate laser barriers.
>
> **GAME MODES & REWARDS:**
> • **60-Second Rush Hour Blitz:** Race against the clock with combo multipliers and +5s bonuses.
> • **Daily Challenge & Streaks:** A fresh daily brain puzzle every day with 7-day streak rewards.
> • **Master Crowns & 1–3 Stars:** Beat par moves to earn Master Crowns on every level.
> • **Smart Step-by-Step Hints:** Stuck? Use live pathfinding hints that adapt to your current board.
> • **Custom Block Skins & ASMR Audio:** Unlock Cyber Neon, Woodcraft, Obsidian Gem, and Royal Gold themes.

## 3. Android Export Setup (Godot 4.7)
1. Install **Android Studio / Android SDK** (API 35) and **OpenJDK 17**; set their paths in Godot **Editor → Editor Settings → Export → Android**.
2. Generate a **Release Keystore** (`keytool -genkey -v -keystore release.keystore ...`) and set `keystore/release`, `release_user`, and `release_password` in `export_presets.cfg` (do NOT commit your `.keystore` or passwords to git).
3. In Godot: **Project → Install Android Build Template**, then **Project → Export → Android → Export Project** to generate `build/UnblockPuzzleSlideEscape.aab`.

## 4. Optional Monetization & Analytics Plugins
`scripts/monetization_manager.gd` is already wired to bind native Android plugins when installed:
- **AdMob:** Poing Godot AdMob (`PoingAdMob`) — rewarded video for hints, interstitials gated to `level_id >= 6` with 90s cooldown.
- **Billing:** `GodotGooglePlayBilling` for `remove_ads` SKU in `ShopDialog`.
- **In-App Review:** `GodotPlayInAppReview` (falls back to `market://details?id=...` automatically).

## 5. Mandatory Play Console Steps
- **Closed Testing (New Personal Accounts):** Upload `.aab` to Closed Testing, recruit **12+ active testers for 14 consecutive days** who open and play levels, then apply for Production access.
- **Privacy Policy & Data Safety:** Host a simple Privacy Policy URL (matching the offline/ad-SDK disclosures you ship) and complete the Data Safety + Content Rating questionnaires.
- **Store Listing Graphics:** Create 6–8 portrait screenshots (1080×1920) highlighting Classic, Ice, Laser, Blitz, and Skins, plus a 1024×500 Feature Graphic.
