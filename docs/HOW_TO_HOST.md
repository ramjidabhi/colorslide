# 🌐 How to Get Your Live Privacy Policy URL (Free & Instant)

Google Play Console requires a public `https://...` URL for your Privacy Policy before you can submit your app.

Here are the 3 easiest ways to host `docs/index.html`:

---

### Method 1: GitHub Pages (Recommended — 1 minute)
If your game repository is hosted on GitHub:
1. Push your repository to GitHub (including the `docs/` folder).
2. Go to your GitHub repository in your browser.
3. Click **Settings** (tab at the top) → **Pages** (on the left sidebar).
4. Under **Branch**, select `main` (or `master`), and in the folder dropdown select `/docs`.
5. Click **Save**.
6. Within 60 seconds, GitHub will give you a live URL:
   ```
   https://<your-github-username>.github.io/<your-repo-name>/
   ```
7. Paste this URL into Google Play Console under **Policy & programs → App content → Privacy Policy**.

---

### Method 2: Netlify Drop (30 seconds — No code needed)
1. Go to [app.netlify.com/drop](https://app.netlify.com/drop).
2. Drag and drop the `docs` folder onto the page.
3. Netlify will immediately generate a live secure HTTPS link (e.g., `https://colorslide-privacy.netlify.app`).
4. Paste that link into Google Play Console.

---

### Method 3: Google Sites (Free)
1. Go to [sites.google.com](https://sites.google.com) and create a blank page.
2. Title it **"Privacy Policy - Unblock Puzzle: Slide Escape"**.
3. Copy and paste the text from `docs/index.html`.
4. Click **Publish** and copy the published URL.
