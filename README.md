# DashCam — redesigned dash cam companion app (sample build)

A SwiftUI iPhone app built from the redesign concept: Home, Live view, Gallery (find clips by day), Clip player, Saved (background downloads) and Settings.

**This build runs on sample data.** The screens, filters, downloads queue, firmware update and settings all work, but nothing talks to your 70mai A510 yet. The camera connection lives behind one protocol (`DashCam/Services/CameraService.swift`), so it can be added later without touching the screens.

- iOS 17 or later (runs on iOS 26), iPhone only, portrait, dark theme.
- No third-party libraries.

## Install on your iPhone from a Windows PC

You need: a free GitHub account, a free Apple ID, your iPhone 13 and its USB cable.

### 1. Build the app on GitHub (one time per change)

1. Sign in to github.com and create a new repository (name it `DashCam`). **Public** is simplest: GitHub's Mac build machines are free for public repos; private repos use up free minutes quickly.
2. Unzip `DashCam.zip` on your PC.
3. In the new repository, choose **Add file → Upload files** and drag in everything inside the unzipped `DashCam` folder, including the `.github` folder. Commit.
   - If Windows hides the `.github` folder, create the file by hand instead: **Add file → Create new file**, name it `.github/workflows/build-ipa.yml`, paste the contents of that file, and commit.
4. Open the **Actions** tab. The "Build iPhone app" run starts by itself (or click **Run workflow**). It takes about 5–10 minutes.
5. When it shows a green tick, open the run and download **DashCam-ipa** under *Artifacts*. Unzip it to get `DashCam.ipa`.

If the run fails, download **build-log** from the same page and send it to Claude to fix.

### 2. Install it with Sideloadly

1. Install **iTunes and iCloud from apple.com** (not the Microsoft Store versions), then install **Sideloadly** from sideloadly.io.
2. Connect the iPhone by USB and tap **Trust** on the phone.
3. In Sideloadly, choose `DashCam.ipa`, enter your Apple ID, and click **Start**. Approve any two-factor code.
4. On the iPhone:
   - **Settings → Privacy & Security → Developer Mode** → turn on, restart, confirm.
   - **Settings → General → VPN & Device Management** → tap your Apple ID → **Trust**.
5. Open **DashCam** from the Home Screen.

### Limits of a free Apple ID

- The app stops opening after **7 days**. Re-run Sideloadly (or leave its auto-refresh on with the PC and phone on the same Wi-Fi) to renew it.
- At most **3** sideloaded apps at once.
- A paid Apple Developer account ($99/year) removes the 7-day limit and allows TestFlight.

## Project layout

| Path | What it is |
|---|---|
| `project.yml` | XcodeGen spec; the build generates the Xcode project from it |
| `DashCam/App` | App entry point |
| `DashCam/Theme` | Colours, card styles, haptics |
| `DashCam/Models` | Clip, day, device and download types |
| `DashCam/Services/CameraService.swift` | Camera protocol + sample-data implementation |
| `DashCam/Services/AppState.swift` | Shared state, simulated background downloads, toasts |
| `DashCam/Views` | The six screens, tab bar and shared components |
| `.github/workflows/build-ipa.yml` | Cloud build that produces `DashCam.ipa` |

## Next step: connecting the A510

1. Join the camera's Wi-Fi from iOS Settings and capture how the official app talks to it (clip list, live stream, download URLs).
2. Implement `CameraService` as `A510CameraService` and pass it to `AppState(camera:)`.
3. Replace the drawn road previews with real thumbnails and video (`AVPlayer`), and move downloads to a background `URLSession`.
