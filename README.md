# Megan and Moonbeams

A cinematic entry screen for Megan's Christian storytelling app.

Live app: https://wolfbreed1829.github.io/megan-and-moonbeams/

## Run

Requires Node.js 22.12+ and Gleam 1.19+. This workspace includes a local Gleam executable in `.tools/gleam/`; elsewhere, install [Gleam](https://gleam.run/getting-started/installing/) or set `GLEAM_BIN`.

```sh
npm install
npm run dev
```

Open http://127.0.0.1:5173. Gleam changes rebuild automatically; CSS updates through Vite. Windows directory junctions are prepared automatically, without administrator privileges.

```sh
npm run check
npm run build
npm run preview
```

The production build is in `dist/`.

## GitHub Pages

Pushes to `main` run `.github/workflows/deploy.yml`, which checks and builds the Gleam app and deploys `dist/` to GitHub Pages. The workflow gets the site's base path from GitHub, so assets resolve correctly beneath the repository URL. Local development continues to use `/`.

For a local build with the same path on PowerShell:

```powershell
$env:SITE_BASE_PATH = '/megan-and-moonbeams/'
npm run build
npm run preview -- --base=/megan-and-moonbeams/
```

## Source

- `src/megan_and_moonbeams.gleam`: typed model, messages, updates, views, and managed narration effects.
- `src/stories.gleam`: sample story records, chapters, Scripture, and reflection prompts.
- `src/styles.css`: cinematic layout, responsive styles, reduced-motion support.
- `src/atmosphere.js`: eased pointer parallax and story transitions. Decorative motion pauses when the tab is hidden and respects both the pause control and reduced-motion preferences.
- `src/ocean.js`: a small WebGL water renderer that animates the waves and moonlight reflection at 30fps. The static ocean artwork remains available if WebGL is unavailable or lost. Water rendering stops when a story is open, motion is paused, or the tab is hidden.
- `src/ocean_audio.mjs`: opt-in ocean ambience synthesized with Web Audio. It starts only after a click, fades out when disabled, suspends in a hidden tab, and becomes quieter during narration.
- `src/browser.mjs`: optional browser speech synthesis. It is clearly labeled sample narration, not Megan's voice.
- `src/main.js`: starts Lustre and bridges native modal focus management.

Watch shows a short coming-soon state until Megan's videos are available. Read offers three sample reflections; Listen narrates the selected chapter with the browser's voice where supported. The story collection, chapter selection, reflection, Escape-to-close, focus restoration, and atmosphere pause all work. No video or recordings are fabricated.

The entrance defaults to Read so the first action opens a complete sample. Chapters lead into a quiet reflection with an optional breathing rhythm. The rhythm becomes static when motion is paused or reduced. Share previews use `public/images/share-preview.jpg`; the source layout is retained in `docs/artwork/share-preview.html`.

Replace the sample records with Megan's content, then connect actual video, audio, caption, and transcript assets in the story view as the app grows.

## Artwork

The moonlit ocean was created with the built-in image-generation tool. The optimized runtime asset is `public/images/moonlit-ocean.webp`; the original and exact generation prompt are `docs/artwork/moonlit-ocean.png` and `docs/artwork/moonlit-ocean-prompt.txt`. The earlier room artwork is retained in the repository. Fonts are Cormorant Garamond and DM Sans, served by Google Fonts with local fallbacks.

Framework reference: [Lustre](https://hexdocs.pm/lustre/).
