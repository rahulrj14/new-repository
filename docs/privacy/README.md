# Publishing the privacy policy

Google Play needs a public URL for the privacy policy, even though Lock In collects nothing. `index.html` is a single static page with no scripts, trackers or external files.

## Before publishing
Replace `[your contact email]` in `index.html` with the address you'll put on the Play listing.

## GitHub Pages (free)
1. Merge this branch into `main`, so the page is on your default branch.
2. On GitHub: **Settings → Pages**.
   - **Source:** "Deploy from a branch".
   - **Branch:** `main`, folder **`/docs`**.
3. After a minute or two the page is live at
   `https://<your-username>.github.io/new-repository/privacy/`.
4. Paste that URL into Play Console → App content → Privacy policy, and into the store listing.

The repository must be public for free GitHub Pages. If you'd rather keep the code private, you have two options:
- Paste the page into any free static host.
- Make a separate small public repository containing only `docs/privacy/index.html`.
