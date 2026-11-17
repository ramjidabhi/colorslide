# 🚀 Google Play Store Upload & Release Guide
## Unblock Puzzle: Slide Escape

This document contains everything needed to upload and publish **Unblock Puzzle: Slide Escape** to the Google Play Console. All fields, descriptions, questionnaire answers, credentials, and step-by-step instructions are ready to copy and paste.

---

## 📦 1. Production Release Files & Credentials

| Property | Value | Notes |
| :--- | :--- | :--- |
| **Play Store Release Bundle** | `build/UnblockPuzzleSlideEscape.aab` | **61.1 MB** — Upload this file to Google Play Console |
| **Direct Device Test APK** | `build/UnblockPuzzleSlideEscape.apk` | **173.6 MB** — For manual USB/ADB installation |
| **Package Name** | `com.colorslide.unblockescape` | Defined in `AndroidManifest.xml` & `export_presets.cfg` |
| **Version Name** | `1.0.0` | Initial release |
| **Version Code** | `1` | Increment by +1 on future updates |
| **Target SDK** | `35` (Android 15) | Complies with Google Play 2026 requirements |
| **Minimum SDK** | `24` (Android 7.0) | Supports 99%+ of Android devices |
| **Architectures** | `arm64-v8a`, `armeabi-v7a` | Bundled in AAB; Google serves device-specific size (~28 MB) |

### 🔑 Signing Keystore Details
> ⚠️ **CRITICAL**: Keep `release.keystore` safe. You cannot update the app on Google Play without this exact keystore!

* **Keystore Location**: `D:\ColorSlide\release.keystore`
* **Keystore Backup**: `C:\Users\RAM\AppData\Roaming\Godot\keystores\release.keystore`
* **Keystore Alias**: `colorslide_release`
* **Keystore Password**: `colorslide2026`
* **Key Password**: `colorslide2026`
* **Key Algorithm**: RSA 2048-bit (Validity: 10,000 days)

---

## 📝 2. Main Store Listing Details (Copy & Paste)

### App Title (30 / 30 characters)
```text
Unblock Puzzle: Slide Escape
```

### Short Description (78 / 80 characters)
```text
Slide blocks, clear the path & escape! 200 brain puzzles, ice, lasers & blitz.
```

### Full Description (ASO Optimized — English)
```text
🧩 UNBLOCK PUZZLE: SLIDE ESCAPE — The Ultimate Mind-Bending Slide Puzzle!

Can you think ahead and free the hero block? Slide colored blocks across the grid to open a clear path to the exit — but every move matters! With 200 hand-crafted levels across 4 unique worlds, this is the crisp, tactile brain workout that keeps your mind sharp.

━━━ 200 LEVELS ACROSS 4 DYNAMIC WORLDS ━━━

🧩 WORLD 1 — BEGINNER ESCAPE (Levels 1–50)
Master the fundamentals of horizontal and vertical sliding. Clean, accessible puzzles designed for all skill levels.

🚦 WORLD 2 — STRATEGIC TRAFFIC JAM (Levels 51–100)
Dense multi-block configurations, 3-unit trucks, and complex deadlock shifts that demand serious forward planning.

❄️ WORLD 3 — FROST CAVERN (Levels 101–150)
Frozen ice blocks lock the grid! Slide adjacent blocks past frozen obstacles to thaw them and forge new escape paths.

⚡ WORLD 4 — LASER FACILITY (Levels 151–200)
High-tech laser barriers block your path! Park blocks onto pressure switch pads to deactivate lasers and outsmart the defense grid.

━━━ 🔥 DAILY MIND FORGE ━━━
A fresh, procedural puzzle every single day (14–28 optimal moves) — identical for players worldwide!
• Solve daily puzzles to build your Daily Streak counter.
• Reach 7-day milestones to claim golden mystery chests packed with bonus coins and free boosters!

━━━ 3 SATISFYING COIN BOOSTERS ━━━
Stuck on a tricky deadlock? Unleash powerful special tools:
🔨 SLEDGEHAMMER — Smash and permanently shatter any obstacle block!
✂️ SHRINK RAY — Shrink a 3-cell truck to 2, or a 2-cell block to a 1x1 mini block!
🧲 CRANE PICKER — Lift any trapped obstacle and drop it into any open space!
💡 100% Undo Refund: Accidentally use a booster? Just tap Undo — your booster and coins are refunded instantly!

━━━ REWARDING PROGRESSION & RETENTION ━━━
🐷 Piggy Bank Vault — Automatically banks +25 coins per level cleared. Smash it open whenever you want a huge coin payout!
🎡 Lucky Wheel — Free daily spin for coin jackpots, hints, and exclusive skins!
👑 Master Crown — Solve any puzzle at or under the Par move target to earn the prestigious Crown badge!
⚡ 60-Second Rush Hour Blitz — Time-attack arcade mode! Chain combos for +5s time bonuses and climb the global leaderboard!
🌟 Milestone Star Chests — Unlock treasure chests every 10 levels for bonus hints and items.

━━━ CUSTOMIZATION & ACCESSIBILITY ━━━
🎨 5 Gorgeous Visual Themes: Classic Vibrant, Cyber Neon, Artisan Woodcraft, Obsidian Gem, and Royal Gold.
🐾 Pet Rescue Mode: Toggle charming character faces on the hero block!
🔊 Tactile Audio & Haptics: Independent sound, ambient music, and vibration toggles.
🌐 8 Full Languages: English, Spanish, German, French, Japanese, Portuguese, Korean, and Indonesian.

━━━ PLAY ANYWHERE, ANYTIME ━━━
✅ 100% Offline Playable — No Wi-Fi or mobile data connection required.
✅ Zero Energy Barriers — No hearts, no lives, no forced waiting timers.
✅ Smart Step-by-Step Hints — Stuck? Use adaptive pathfinding hints to guide your next move.

Download Unblock Puzzle: Slide Escape today and experience the most satisfying slide puzzle ever created!
```

### Categorization & Tags
* **Application Type**: Game
* **Category**: Games → Puzzle
* **Tags** (select up to 5):
  1. *Puzzle*
  2. *Brain Games*
  3. *Casual*
  4. *Single Player*
  5. *Offline*

---

## 📊 3. Firebase Analytics & Realtime User Tracking

Firebase Analytics is fully integrated and linked with your `google-services.json` (Project: **ExamVeda** / `examveda-54b88`).

### What you can track in Firebase Console:
1. **Daily Active Users (DAU) & Monthly Active Users (MAU)**:
   * View exactly how many unique players open and play the game each day.
2. **User Engagement & Active Watch Time**:
   * Automatic `user_engagement` tracking measures average active play time per user and total engagement time per day.
3. **Realtime Analytics**:
   * View live players on a worldwide map in the last 30 minutes.
4. **Gameplay & Monetization Events**:
   * `app_open`, `level_start`, `level_complete` (with stars, moves, and level ID).
   * `rewarded_ad_user_earned_reward` (tracks ad watch conversion for hints, coins, and boosters).
   * `blitz_score_submitted`, `lucky_wheel_spun`, `chest_opened`.

---

## 💰 4. Google AdMob Configuration

| Ad Format | Setting | Value |
| :--- | :--- | :--- |
| **AdMob Application ID** | App ID | `ca-app-pub-6827648916951660~3848367705` |
| **Rewarded Video** | Ad Unit Name | `unblock_puzzle_video` |
| **Rewarded Video** | Ad Unit ID | `ca-app-pub-6827648916951660/1711113358` |

### In-Game Economy & Reward Rules:
1. **Free Hints**: 1 Rewarded Ad = **+1 Free Walkthrough Hint** (or 100 coins in Shop).
2. **Free Coins**: 1 Rewarded Ad = **+100 Coins** in the Shop.
3. **Free Boosters**: 1 Rewarded Ad = **+1 Free Booster** (Hammer, Shrink, Crane) when balance is zero.

> ℹ️ **Post-Publication Note**: Once your app is live on Google Play, go to [AdMob Console](https://apps.admob.com) → **Apps** → **App Settings** → **App Store details** and link your live Google Play store URL. Live ads will begin filling automatically within a few hours.

---

## 🔒 4. Google Play Data Safety Questionnaire Answers

Fill in **Play Console → Policy & programs → App content → Data safety**:

| Question | Answer |
| :--- | :--- |
| **Does your app collect or share any of the required user data types?** | **Yes** (Google AdMob SDK collects pseudonymous Device IDs). |
| **Is all user data collected by your app encrypted in transit?** | **Yes** (All network traffic uses HTTPS/TLS). |
| **Do you provide a way for users to request that their data be deleted?** | **No** (Game saves are stored locally on the device; uninstalling clears all data). |

### Data Types Declaration:
* Select: **Device or other IDs** → **Device or other IDs** (e.g. Advertising ID).
  * **Collected?**: Yes
  * **Shared?**: Yes (shared with Google AdMob for advertising)
  * **Ephemeral?**: No
  * **Required or Optional?**: Required (for ad-supported features)
  * **Purposes**: 
    - *Advertising or marketing*
    - *Analytics*
    - *Fraud prevention, security, and compliance*

---

## 🛡️ 5. App Content & Policy Declarations

Complete each section in **Play Console → App content**:

1. **Privacy Policy**:
   * Host the file `D:\ColorSlide\privacy_policy.html` on your website or GitHub Pages (e.g., `https://<username>.github.io/ColorSlide/privacy_policy.html`).
   * Paste the public URL into the **Privacy policy** field.
2. **Ads**:
   * Select: **"Yes, my app contains ads"**.
3. **App Access**:
   * Select: **"All functionality is available without special access"**.
4. **Target Audience & Content**:
   * Target age groups: Select **13 and older** (13–15, 16–17, 18+).
   * Appeal to children: Select **"No"** (avoids strict Designed for Families review requirements).
5. **Government Apps**:
   * Select: **"No"**.
6. **Financial Features**:
   * Select: **"My app doesn't provide any financial features"**.
7. **IARC Content Rating Questionnaire**:
   * Category: **Game**
   * Violence: **No**
   * Fear / Horror: **No**
   * Sexuality / Nudity: **No**
   * Simulated Gambling: **No** (Lucky Wheel uses in-game virtual coins with no real-money stakes)
   * Language: **No**
   * Controlled Substances: **No**
   * Miscellaneous: **No** (Does not share physical location, does not allow user-to-user chat)
   * **Result**: **PEGI 3 / ESRB Everyone (E) / USK 0**

---

## 🎨 6. Store Graphic Assets Checklist

| Asset | Dimensions | Format | Requirement |
| :--- | :--- | :--- | :--- |
| **App Icon** | 512 × 512 px | 32-bit PNG, max 1MB | Required (Transparent or solid bg) |
| **Feature Graphic** | 1024 × 500 px | JPEG or 24-bit PNG, max 15MB | Required (Shows game title & hero block) |
| **Phone Screenshots** | 1080 × 1920 or 1080 × 2400 | JPEG or 24-bit PNG | Minimum 4 required (portrait) |

---

## 🚀 7. Step-by-Step Google Play Console Upload Walkthrough

### Step 1: Create the App
1. Go to [Google Play Console](https://play.google.com/console).
2. Click **Create app** (top-right).
3. Fill initial details:
   * **App name**: `Unblock Puzzle: Slide Escape`
   * **Default language**: `English (United States) - en-US`
   * **App or game**: `Game`
   * **Free or paid**: `Free`
4. Accept Developer Program Policies and US Export Laws, then click **Create app**.

### Step 2: Complete "Set up your app" Tasks
In the left sidebar, navigate to **Dashboard** and complete all tasks under **Set up your app**:
1. Set privacy policy URL
2. Declare ads (Yes)
3. Set app access (All functionality available)
4. Complete Content rating (IARC)
5. Select Target audience (13+)
6. Complete Data safety questionnaire (as detailed in Section 4 above)
7. Select game category (`Puzzle`) and provide contact email

### Step 3: Set up Main Store Listing
1. Navigate to **Grow → Store presence → Main store listing**.
2. Enter **App name**, **Short description**, and **Full description** from Section 2.
3. Upload **App icon** (512×512), **Feature graphic** (1024×500), and phone screenshots.
4. Click **Save**.

### Step 4: Create Production / Testing Release
1. Navigate to **Release → Production** (or **Testing → Closed testing** for new personal accounts).
2. Click **Create new release**.
3. Under **App bundles**, click **Upload** and select:
   ```text
   D:\ColorSlide\build\UnblockPuzzleSlideEscape.aab
   ```
4. Play Console will automatically verify the bundle, extract version `1.0.0 (1)`, and confirm Android API 35 target.
5. In **Release notes**, enter:
   ```text
   en-US
   Initial release of Unblock Puzzle: Slide Escape!
   • 200 brain-bending slide puzzles across 4 unique worlds
   • Frost Cavern ice blocks & Laser Facility switches
   • 60-Second Rush Hour Blitz mode & Daily Challenges
   • Smart step-by-step hint solver & 3 coin boosters
   • 5 unlockable block visual themes
   ```
6. Click **Next** → **Save and review release**.
7. If all checks pass with zero errors, click **Start rollout to Production** (or submit to Closed Testing)!

---

*© 2026 ColorSlide Studio. All rights reserved.*
