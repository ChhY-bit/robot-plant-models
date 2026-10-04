---
sidebar: false
search: false
---

# Website maintenance

This directory contains the website source, not a MATLAB installation package. The site extends VitePress with an original Vue-inspired theme. Generated HTML and dependencies are excluded from Git.

## Local development

Use Node.js 22 or later. From this directory:

```sh
npm ci
npm run dev
```

Open the URL printed by VitePress, including its `/robot-plant-models/` base path. For a production preview:

```sh
npm test
npm run build
npm run check:links
npm run preview
```

The website is built into `.vitepress/dist/`. Do not open its HTML files directly with `file://`; use the preview server.

The optional browser smoke test is `node tests/browser-smoke.mjs`. It needs a separately installed Playwright package and a browser, or the host's bundled Playwright via `PLAYWRIGHT_MODULE`. Set `BROWSER_CHANNEL=msedge` to use an existing Microsoft Edge installation, `WEBSITE_URL` to select the running preview, and `SCREENSHOT_DIR` to save screenshots. Browser tooling is not required to build or serve the website.

## Where to make changes

| Item | Source |
| --- | --- |
| Home text and feature descriptions | `index.md` (frontmatter and Markdown body) |
| Home HTML template | `.vitepress/theme/components/Home.vue` |
| Colors, typography, responsive layout | `.vitepress/theme/style.css` |
| GitHub, Releases, URL base | `.vitepress/site.mjs` |
| Top navigation and site features | `.vitepress/config.mts` |
| Optional sidebar labels and ordering | `.vitepress/navigation.mjs` |
| FAQ and About placeholders | `FAQ/index.md`, `About/index.md` |

The GitHub links in `site.mjs` use `ChhY-bit/robot-plant-models`. The local default base is `/robot-plant-models/`; the GitHub workflow derives the production base from the actual repository name. If the repository is renamed again, update both links and the local default base in `site.mjs`. For a custom-domain root deployment, set `PAGES_BASE=/` before building.

## Documentation behavior

The left sidebar scans Markdown documents under `Get-Started/` and `Robots/`. New documents and folders are included automatically, and empty folders are omitted. The development server restarts its configuration when files are added or removed. A small presentation map supplies sensible reading order; unknown entries are sorted by name. An entry with frontmatter `sidebar: false` is excluded from the tree.

The first Markdown H1 becomes the page title above the prose; it is removed only from rendered prose, not from the source. The right outline uses H2 and H3. Previous/next navigation follows the scanned sidebar order, scoped to its top-level section. Existing empty documents retain their routes and show an explicit work-in-progress panel without modifying their source.

Relative Markdown links are processed by VitePress. Moving a document may still break existing links and public URLs: update references and provide redirects where needed. `npm run check:links` checks the built pages and heading anchors, including the existing API cross-references.

## Website languages

English keeps the existing paths. Translations mirror them, for example:

```text
Robots/Ackermann-Robot/API-Reference/Methods.md
zh/Robots/Ackermann-Robot/API-Reference/Methods.md
ja/Robots/Ackermann-Robot/API-Reference/Methods.md
```

English and Simplified Chinese are enabled. No `-zh` suffix is needed inside `zh/`. The Chinese mirror includes all document routes, including this maintenance guide; empty English pages remain empty mirrors with a localized work-in-progress panel.

The custom language menu switches to the corresponding page and preserves the current heading anchor. Chinese headings use explicit `{#original-anchor}` IDs so existing cross-references and language switches remain valid. Keep API identifiers, YAML keys, units, formulas, and executable examples unchanged when translating. Update both language versions when the API or source documentation changes; translations are maintained Markdown, not generated during the site build.

To add another language, create its full mirror, register it in `.vitepress/languages.mjs`, add locale-specific navigation and UI strings in `.vitepress/config.mts` and the custom theme, and add its sidebars and canonical-path handling. Missing translations must provide an explicit English-original link, not silently masquerade as translated content. Run the navigation tests, production build, link checker, and browser smoke tests after changes.

## GitHub Pages

The repository contains `.github/workflows/pages.yml`. It builds and validates the site for pull requests and pushes that change website files, and deploys only default-branch pushes or manual runs on that branch. In repository Settings → Pages, select **GitHub Actions** as the publishing source. A `github-pages` environment may require approval according to repository settings.

Adding the workflow does not publish from this local checkout. No commit, push, or remote settings change is part of this first implementation.

## Items still to be supplied

- Final project icon and approved Home copy (the first version uses an original schematic icon and model illustrations).
- Installation, quickstart, and detailed modeling content in the existing empty documents.
- FAQ answers, author information, contribution/citation instructions, and final license details.
- Published release assets and verified MATLAB compatibility information.
- Additional languages as needed; keep the existing English and Chinese mirrors synchronized.

The website does not assert that a native Python/C library, a verified installer, or a specific software license is already available.
