# Shy Sharing

A small Mac menu bar app that makes screen sharing at work less stressful.

**Current feature:** when you open the **Share → Window** list in Microsoft Teams and point
at an entry, the real window gets a red outline with its name, so you can tell which one
you're about to share without leaning in to read the tiny thumbnails.

## Requirements

- macOS 13 or later
- Swift 5.9 or later (install Xcode, or run `xcode-select --install` for the command line tools)
- Microsoft Teams (new or classic)

## Try it

From this folder, in Terminal:

```sh
swift run ShySharing --debug
```

The first time, macOS asks for two permissions. Because you started it from Terminal, they
are granted to **Terminal**:

1. **Accessibility**, to read which entry you're pointing at in Teams' share list.
2. **Screen Recording**, so the app can see other apps' window titles. It never records anything.

After allowing both, stop the app (Ctrl+C) and run the same command again.

Then, in a Teams meeting (a test meeting with yourself works), click **Share → Window** and
move the pointer over the entries.

A dashed-rectangle icon appears in the menu bar. Use it to turn the outline on or off, check
the permissions, or quit.

## Build a standalone app

```sh
./scripts/build-app.sh
open "build/Shy Sharing.app"
```

The permissions then belong to Shy Sharing instead of Terminal. The build is signed only for
this Mac, so after each rebuild macOS may treat it as a new app. If the outline stops
appearing, remove Shy Sharing from both permission lists in System Settings → Privacy &
Security and allow it again.

## How it works

1. While Teams is the front app, the app checks about 15 times a second which element is
   under the pointer, using the macOS Accessibility API.
2. It walks up from that element looking for text that names one on-screen window (a
   window title like `danielryan — -zsh — 136×49`, or an app name like `Claude`). It only
   counts the match once a parent element names two or more windows, which shows the pointer
   is inside a list of windows rather than over, say, a chat message.
3. It draws a click-through red frame around that window. The frame window is marked to
   stay out of screen shares and recordings.

## If the outline doesn't appear

Run with `--debug` and point at an entry in the share list. The Terminal output shows:

- `accessibility allowed` and `screen recording allowed`. Both must be `true`.
- `window: …` lines listing the windows the app can see. If titles are empty (`""`),
  Screen Recording permission is missing.
- `pointer over:` with the elements under the pointer and their text. If the window name
  isn't anywhere in those lines, Teams isn't exposing it in a way this version expects.
  Copy that output into an issue or a chat so the matching can be adjusted.

## Known limitations

- Untested on a real Mac so far. It relies on the text Teams exposes to accessibility tools,
  which Teams could change at any time.
- Only windows that are on screen can be outlined. Minimised windows are skipped.
- If several windows have exactly the same title, the front-most one is outlined.
- On some recent macOS versions, apps that capture through ScreenCaptureKit may still capture
  windows marked to stay out of shares. The outline only appears while the share list is
  open, so this shouldn't matter in practice.
