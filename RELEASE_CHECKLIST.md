# SpeedRead — Release Checklist (macOS, online distribution)

Goal: ship a `.dmg` that any macOS user can download and open with a double‑click —
no "unidentified developer" wall, no right‑click‑Open workaround.

**Distribution channel:** Developer ID + notarization (direct download).
**Not** the Mac App Store — SpeedRead synthesizes ⌘C, installs a Carbon global
hotkey, and vends a system Service, none of which survive App Sandbox.

**Already done** (2026‑08‑28): universal binary (`project.yml` → `arm64 x86_64`,
verified `x86_64 arm64`), hardened runtime on for Release, `LICENSE` (MIT + upstream
credit), `scripts/package.sh` (build → sign → notarize → DMG, all env‑gated),
`make package`, GitHub Actions `ci.yml` + `release.yml`, public `README.md` with
screenshots.

**Still blocking a public download:** no Apple Developer account → still adhoc‑signed
→ `spctl` **rejected** → downloaders hit Gatekeeper. Sections 1, 5, 6 below.

---

## 1. Prerequisites (one‑time)

- [ ] Enroll in the **Apple Developer Program** ($99/yr) — required for a
      Developer ID certificate and the notary service.
- [ ] In Xcode → Settings → Accounts, add the Apple ID and
      **create a "Developer ID Application" certificate** (Manage Certificates → +).
- [ ] Note the **Team ID** (10 chars, e.g. `AB12CD34EF`) from
      developer.apple.com → Membership.
- [ ] Create an **app‑specific password** for notarization
      (appleid.apple.com → Sign‑In & Security), or set up API‑key auth, and store it:
      ```sh
      xcrun notarytool store-credentials "speedread-notary" \
        --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-pw"
      ```
- [ ] Decide the permanent **bundle identifier**. `com.cami.SpeedRead` works, but it
      can never change after release (TCC/Accessibility grants and any future
      updater are keyed to it). Ideally use a domain you control.

## 2. Project readiness (edit `project.yml`, then `xcodegen generate`)

- [x] **Universal binary** — `project.yml` sets `ARCHS: "arm64 x86_64"`;
      `scripts/package.sh` verifies `lipo -archs` on every build.
- [x] **Hardened runtime** — on for the Release config. No extra entitlements
      needed (CGEvent posting / AX tree are gated by the runtime Accessibility
      grant). Still: **confirm the hotkey + Service work in a hardened, notarized
      build** on a clean machine (section 8).
- [ ] Set the real **Team ID / signing identity** for the Release config
      (`DEVELOPMENT_TEAM`, `CODE_SIGN_IDENTITY: "Developer ID Application"`,
      `CODE_SIGN_STYLE: Manual`). Keep Debug on automatic/adhoc for local runs.
- [ ] **Confirm the deployment target** (`macOS 14.0`). Either test on a real
      14.x machine/VM, or raise it to a version you can test.
- [ ] **Version stamp**: `MARKETING_VERSION` (e.g. `1.0`) and a monotonic
      `CURRENT_PROJECT_VERSION` (e.g. `1`). Establish a bump rule for future builds.
- [x] Icon: 10 slots filled by `Tools/makeicon.swift`; asset catalog compiles clean.
- [ ] Strip debug noise: no `print`/`NSLog` on hot paths, no leftover test text.

## 3. Legal / trust content

- [x] `LICENSE` — MIT + a paragraph crediting ClaysonIO's upstream extension.
- [x] Privacy statement + Accessibility explanation — in `README.md`
      ("No network", "Permissions"). Reuse on the release page.

## 4–7. Build → sign → notarize → DMG  (automated)

`scripts/package.sh` does all of it in one run. Unsigned by default; export signing
env to produce a shippable build:

```sh
export DEVELOPER_ID_APP="Developer ID Application: NAME (TEAMID)"
xcrun notarytool store-credentials speedread-notary \
  --apple-id you@example.com --team-id TEAMID --password app-specific-pw
export NOTARY_PROFILE=speedread-notary
make package          # → dist/SpeedRead-<version>.dmg  (+ SHA-256 printed)
```

The script: `xcodegen` → universal `archive` → `lipo` check → `codesign --options
runtime --timestamp` → `notarytool submit --wait` → `stapler staple` → DMG (app +
`/Applications` symlink) → sign + staple the DMG.

Or let CI do it: push a `vX.Y` tag and `.github/workflows/release.yml` runs the same
script and creates the GitHub Release. Set repo secrets first (`MACOS_CERTIFICATE`
base64 `.p12`, `MACOS_CERTIFICATE_PWD`, `MACOS_SIGN_IDENTITY`, `NOTARY_APPLE_ID`,
`NOTARY_TEAM_ID`, `NOTARY_PWD`) — without them the workflow publishes an **unsigned**
dmg (pipeline test only).

- [ ] First real run: verify `codesign -dvvv` shows `flags=…(runtime)`,
      `Authority=Developer ID Application: …`, and notarization returns `Accepted`
      (`xcrun notarytool log <id> …` if `Invalid`).
- [ ] Publish the DMG's **SHA‑256** on the release page.

## 8. Verify like a real user (critical — do on another Mac or a fresh user account)

- [ ] Download the DMG **through a browser** (so it gets the quarantine bit), or
      simulate: `xattr -w com.apple.quarantine "0083;00000000;Safari;" SpeedRead.dmg`
- [ ] `spctl -a -vvv SpeedRead.app` → **accepted**, source =
      "Notarized Developer ID".
- [ ] Open the DMG, drag to Applications, launch — should open with **no
      Gatekeeper prompt**.
- [ ] Test the full feature set on that machine:
  - [ ] Paste text → Reader plays; slider, pause/resume, rewind, restart, drag‑seek.
  - [ ] Right‑click selected text in Safari/TextEdit → **Services → speedRead**
        launches and loads it (may need `pbs -flush` or a logout on first install).
  - [ ] Global hotkey ⇧⌥⌘T → Accessibility prompt appears, grant it, hotkey works.
  - [ ] Quit + relaunch → Accessibility grant persists (it should now, with a
        stable Developer ID identity; adhoc builds lost it every rebuild).
  - [ ] Settings persist; theme = Match System follows light/dark + accent.
  - [ ] Test on an **Intel Mac** if you support one.

## 9. Publish

- [ ] Landing page / repo release with: screenshots, system requirements
      (macOS 14+, Apple Silicon or Intel), the privacy paragraph, the
      Accessibility explanation, DMG link + SHA‑256, and the note that the
      right‑click item appears under **Services** and may need a one‑time enable in
      System Settings → Keyboard → Keyboard Shortcuts → Services → Text.
- [ ] `git tag vX.Y && git push origin vX.Y` — the Release workflow builds, signs
      (if secrets set), notarizes, and creates the GitHub Release with the DMG.
      Then edit the release notes to add the requirements/privacy/Services lines.
- [ ] Keep `dist/SpeedRead.xcarchive` — its dSYMs symbolicate crash reports.

## 10. Optional but recommended

- [ ] **Auto‑update** via [Sparkle](https://sparkle-project.org/) (EdDSA‑signed
      appcast). Add it before 1.0 if you want painless updates later.
- [ ] First‑run **onboarding** screen explaining the Service + hotkey + the
      Accessibility ask, instead of surfacing the permission only on first hotkey use.
- [ ] `ITSAppUsesNonExemptEncryption = false` in Info.plist (harmless now, saves a
      question if you ever add TestFlight).
- [ ] A simple crash‑report intake (email or a service) + the dSYMs to read them.

---

### If you are NOT enrolling in the Developer Program

You can still post the DMG, but every user will hit "SpeedRead can't be opened
because Apple cannot check it for malicious software." They'd have to right‑click →
Open, or run `xattr -dr com.apple.quarantine /Applications/SpeedRead.app`. This is
a poor first impression and increasingly restricted on newer macOS — enrolling is
strongly recommended before any public posting.
