# 🏪 Play Store Listing — Unblock Puzzle: Slide Escape

> Complete metadata, store copy, asset specs, and launch checklist for Google Play Console.

---

## App Identity

| Field | Value |
|---|---|
| **App Name** | Unblock Puzzle: Slide Escape |
| **Package ID** | `com.colorslide.unblockescape` |
| **Category** | Games → Puzzle |
| **Sub-category** | Brain Games |
| **Content Rating** | Everyone (ESRB E / PEGI 3) |
| **Developer Name** | ColorSlide Studio |

---

## Short Description (80 chars max)

```
Slide blocks, free the hero — 200 brain-bending puzzles await!
```
*(63 chars)*

---

## Long Description (4000 chars max)

```
🧩 UNBLOCK PUZZLE: SLIDE ESCAPE — The Ultimate Mind-Bending Slide Puzzle!

Can you think ahead and free the hero block? Slide colored blocks across the grid to open a clear path to the exit — but every move matters. With 200 hand-crafted levels across 4 unique worlds, this is the puzzle game that will keep your brain sharp for months!

━━━ 200 LEVELS ACROSS 4 WORLDS ━━━

🧩 WORLD 1 — BEGINNER ESCAPE (Levels 1–50)
Start with the basics and master the fundamentals of sliding-block logic. Perfect for newcomers!

🚦 WORLD 2 — STRATEGIC TRAFFIC JAM (Levels 51–100)
Dense multi-block traffic jams that demand serious forward thinking. No lucky guesses here!

❄️ WORLD 3 — FROST CAVERN (Levels 101–150)
Frozen ice blocks lock the grid! Slide adjacent blocks to thaw the ice and create new paths.

⚡ WORLD 4 — LASER FACILITY (Levels 151–200)
Laser beams block your way! Step on switches to deactivate barriers and outsmart the grid.

━━━ DAILY MIND FORGE ━━━
A fresh medium-to-hard puzzle every single day — the same globally! Complete it to extend your Daily Streak and earn bonus coins. Reach 7 days for a Golden Chest!

━━━ 3 SPECIAL POWER-UP BOOSTERS ━━━
Stuck on a tough puzzle? Use your coins to unleash:
🔨 SLEDGEHAMMER — Smash and permanently remove any obstacle block
✂️ SHRINK RAY — Shrink a large block down to make room for new paths
🧲 CRANE PICKER — Lift any trapped block and drop it somewhere better

Boosters are optional — real puzzle masters never need them! But they're there when you want to push through and keep the momentum going.

━━━ EARN & COLLECT ━━━
🐷 Piggy Bank — Earn coins as you play. Smash the piggy when it's full for a big coin bonus!
🎡 Lucky Wheel — Spin once a day for free coin rewards, hints, and exclusive skins!
👑 Master Crown — Solve a level at or under par moves to earn an elite crown badge!
⚡ Rush Hour Blitz — Beat the 60-second time attack and compete on the global leaderboard!
🌟 Star Chests — Collect stars, hit milestones, and open treasure chests every 10 levels!

━━━ CUSTOMIZE YOUR EXPERIENCE ━━━
🎨 5 Unique Block Skins — Classic, Cyber Neon, Artisan Woodcraft, Obsidian Gem, Royal Gold
🐾 Pet Rescue Mode — Play with cute character-themed hero blocks instead of plain colors
🌐 8 Languages — English, Spanish, German, French, Japanese, Portuguese, Korean, Indonesian
🔊 Independent Sound & Haptics toggles — Full audio control for every situation

━━━ PLAY ANYWHERE, ANYTIME ━━━
✅ Fully offline — no internet required to play
✅ No energy timers, no forced waits
✅ Clean, ad-free experience with our optional Remove Ads upgrade
✅ Google Play Games — cloud save your progress across devices

Whether you have 2 minutes or 2 hours, Unblock Puzzle: Slide Escape delivers satisfying "aha!" moments every single session. Download free today!
```
*(~3,100 chars — leaves room for localized variants)*

---

## Store Localization

The app ships with 8 languages and Play Console should have translations for:

| Locale | Language |
|---|---|
| `en-US` | English (default) |
| `es-419` | Spanish (Latin America) |
| `de-DE` | German |
| `fr-FR` | French |
| `ja-JP` | Japanese |
| `pt-BR` | Portuguese (Brazil) |
| `ko-KR` | Korean |
| `id-ID` | Indonesian |

---

## Graphic Assets Specification

### App Icon
| Requirement | Spec |
|---|---|
| Size | 512 × 512 px |
| Format | PNG, 32-bit |
| Background | No transparency |
| Safe zone | Keep key art within inner 384×384 px |

### Feature Graphic
| Requirement | Spec |
|---|---|
| Size | 1024 × 500 px |
| Format | PNG or JPEG |
| Content | No text near edges (may be cropped to 16:9) |
| Suggested | Hero block + exit gate with world gradient background |

### Phone Screenshots (Required: 2 min, recommended: 8)
| Spec | Value |
|---|---|
| Dimensions | 1080 × 1920 px (portrait) |
| Format | PNG or JPEG |
| Min count | 2 |

**Recommended screenshot set:**
1. World 1 gameplay — tutorial clear solve
2. World 3 ice block mid-thaw
3. World 4 laser barrier + switch
4. Daily Challenge banner + streak counter
5. Booster bar in action (Sledgehammer selected)
6. Win Dialog — 3 stars + Master Crown
7. Level Select — World progress bar
8. Lucky Wheel + Shop skin grid

### 7-inch Tablet Screenshots (Recommended)
- 1200 × 1920 px (portrait) or 1920 × 1200 px (landscape)

### 10-inch Tablet Screenshots (Recommended)
- 1600 × 2560 px (portrait) or 2560 × 1600 px (landscape)

---

## Content Rating

**Complete the IARC Questionnaire as follows:**

| Question | Answer |
|---|---|
| Violence | None |
| Sexual content | None |
| Language | None |
| Controlled substances | None |
| Gambling / simulated gambling | No (Lucky Wheel is not gambling — fixed reward tables) |
| User interaction / sharing | No (no social/chat features) |

**Expected rating**: Everyone / PEGI 3 / All ages

---

## In-App Products

Create these in Play Console → Monetize → Products → In-app products:

| Product ID | Type | Suggested Price | Title |
|---|---|---|---|
| `coins_200` | Consumable | \$0.99 | 200 Coins Pack |
| `coins_600` | Consumable | \$2.49 | 600 Coins Pack |
| `coins_1500` | Consumable | \$4.99 | 1500 Coins Pack |
| `remove_ads` | Non-consumable | \$2.99 | Remove Ads (Forever) |

> IAP is handled via `GodotGooglePlayBilling` plugin in `monetization_manager.gd`.
> SKUs must be **activated** in Play Console before testing on a real device.

---

## Privacy Policy

**Required URL**: You must supply a Privacy Policy URL.

Suggested policy content (host at your domain):

```
Unblock Puzzle: Slide Escape does not collect, store, or share any
personal data. All game progress is saved locally on the device.
Optional cloud save is handled by Google Play Games — governed by
Google's Privacy Policy. AdMob may show personalized ads per Google's
advertising policies. No personal information is transmitted to our servers.
```

> Host at: `https://colorslide.studio/privacy` (or any public URL)
> Enter this URL in Play Console → App content → Privacy Policy

---

## Data Safety Section

| Data type | Collected? | Notes |
|---|---|---|
| Location | No | — |
| Personal info (name, email) | No | — |
| Financial info | No | (IAP handled by Google Play directly) |
| Health & fitness | No | — |
| Photos/videos | No | — |
| App activity (crash logs) | Optional | Only if Firebase Crashlytics added |
| Advertising ID | Yes (if AdMob active) | AdMob uses GAID for ad personalization |

**Mark**: "Data is not sold to third parties" ✅

---

## AdMob Configuration

Replace placeholder IDs in `project.godot` before shipping:

```ini
[android]
admob_app_id="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"      # Real App ID from AdMob Console
admob_banner_id="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"    # Banner Ad Unit
admob_interstitial_id="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"  # Interstitial Ad Unit
```

> Use test IDs during development:
> App: `ca-app-pub-3940256099942544~3347511713`
> Banner: `ca-app-pub-3940256099942544/6300978111`
> Interstitial: `ca-app-pub-3940256099942544/1033173712`

---

## Google Play Games Services

Create in Play Console → Play Games Services → Setup → Create new game:

| Resource | ID |
|---|---|
| **App** | Link to `com.colorslide.unblockescape` |
| **Leaderboard** | Name: "Blitz Rush Hour" → generates `leaderboard_blitz_rush_hour` |
| **Achievement 1** | "First Clear" — complete Level 1 |
| **Achievement 2** | "Blitz Beginner" — first Blitz Mode attempt |
| **Achievement 3** | "7-Day Warrior" — 7-day daily streak |
| **Achievement 4** | "Crown Collector" — earn 10 Master Crowns |
| **Achievement 5** | "Grandmaster" — complete all 200 levels |
| **Cloud Save** | Enable Snapshots API |

---

## Technical Requirements

| Field | Value |
|---|---|
| **Min Android SDK** | API 24 (Android 7.0 Nougat) |
| **Target SDK** | API 36 (Android 16) |
| **Architecture** | arm64-v8a + armeabi-v7a |
| **Export format** | `.aab` (Android App Bundle) for Play Store |
| **Internet permission** | Required (AdMob, GPGS) |
| **Vibrate permission** | Required (haptic feedback) |
| **Billing permission** | Required (IAP) |

---

## Release Track Recommendation

```
Internal Testing (5-10 testers)
        ↓
Closed Testing / Alpha (20–50 testers, 1 week)
        ↓
Open Testing / Beta (unlimited, 2 weeks)
        ↓
Production (staged rollout: 10% → 50% → 100%)
```

**Staged rollout checklist before 100% production:**
- [ ] 0 ANR (Application Not Responding) reports
- [ ] Crash rate < 0.5%
- [ ] Rating ≥ 4.0 stars from beta testers
- [ ] All IAP products verified as purchasable
- [ ] AdMob revenue tracking active in AdMob Console
- [ ] GPGS leaderboard showing scores from beta players

---

## A/B Test Suggestions (Play Console Experiments)

| Test | Variant A | Variant B |
|---|---|---|
| Icon | Current hero block icon | Neon grid with exit arrow |
| Short description | Current | "200 levels of pure puzzle logic — no timers, no stress!" |
| Screenshot order | Gameplay first | Daily Challenge streak first |
| `remove_ads` price | \$2.99 | \$1.99 |

---

## Pre-Launch Report Checklist

Run via Play Console → Android vitals → Pre-launch report:

- [ ] App launches without crash on API 24, 30, 33, 36
- [ ] No accessibility issues (touch target sizes ≥ 48dp)
- [ ] No security vulnerabilities flagged
- [ ] All permissions declared in `AndroidManifest.xml`
- [ ] No unencrypted HTTP traffic (all API calls use HTTPS)

---

## Store Listing Checklist

- [ ] App icon uploaded (512×512 PNG)
- [ ] Feature graphic uploaded (1024×500)
- [ ] Minimum 2 phone screenshots (1080×1920)
- [ ] Short description filled (≤ 80 chars)
- [ ] Long description filled (≤ 4000 chars)
- [ ] Privacy Policy URL entered
- [ ] Data Safety section completed
- [ ] Content rating questionnaire completed
- [ ] All IAP products created & activated
- [ ] AdMob app linked and ad units created
- [ ] GPGS app linked, leaderboard & achievements created
- [ ] Release notes written for first version
- [ ] Target SDK 36 confirmed in export preset
- [ ] `.aab` file uploaded to Internal Testing track
- [ ] At least 1 internal test device approved

---

*Last updated: 2026-11-13 • Package: `com.colorslide.unblockescape`*
