# Snappy

A macOS window manager inspired by [Divvy](https://mizage.com/divvy/).

Assign keyboard shortcuts to grid-based regions and snap any window into place instantly.

![Snappy Screenshot](docs/screenshot.png)

## Features

- **Grid selection** — Drag across a 6×4 grid to define any region
- **Custom shortcuts** — Assign a key combo to each region
- **Instant snapping** — Press the shortcut to move and resize the frontmost window
- **Menu bar app** — Runs in the background with no Dock icon
- **Liquid Glass UI** — Built for macOS 26
- **Launch at Login** — Toggle from the preferences window

## Requirements

- macOS 26.0+
- Apple Silicon or Intel

## Building & Installing

### Prerequisites

- Xcode 26+
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

### Install

```bash
git clone https://github.com/katsuma/snappy.git
cd snappy
make install
```

This builds the app, copies it to `~/Applications/Snappy.app`, registers it with LaunchServices, and launches it. Running from `~/Applications` is required for Accessibility permissions and Launch at Login to work correctly.

### Uninstall

```bash
make clean
```

Removes `~/Applications/Snappy.app` and resets Accessibility permissions.

## First-time Setup

1. Launch the app — a menu bar icon appears
2. Click the icon → **Preferences…**
3. **General** tab → click **Open System Settings…**
4. Enable Snappy under **Privacy & Security → Accessibility**
5. The status in Preferences updates to "Access granted" within a few seconds

## Usage

### Adding a shortcut

1. **Shortcuts** tab → **New**
2. Enter a name (e.g. `Left Half`)
3. Drag across the grid to select the target region
4. Click the key recorder and press your desired key combo (e.g. `⌘←`)

### Moving a window

Press the shortcut while any window is in focus — it snaps to the assigned region immediately.

## Architecture

```
Snappy/
├── App/
│   ├── SnappyApp.swift        # @main entry point
│   └── AppDelegate.swift      # Menu bar item and preferences window
├── Models/
│   ├── Shortcut.swift         # Shortcut data model
│   ├── GridRegion.swift       # Grid region (6×4)
│   └── KeyCombo.swift         # Key code + modifier flags
├── Services/
│   ├── HotkeyManager.swift    # Global hotkeys via Carbon RegisterEventHotKey
│   ├── WindowMover.swift      # Window move/resize via AXUIElement
│   └── ShortcutStore.swift    # JSON persistence (~/Library/Application Support/Snappy/)
└── Views/
    ├── PreferencesView.swift  # Preferences window (TabView)
    ├── GeneralView.swift      # Accessibility status and login item
    ├── ShortcutsView.swift    # Shortcut list
    ├── ShortcutRowView.swift  # Per-shortcut editor row
    ├── GridPickerView.swift   # 6×4 grid picker (Canvas + DragGesture)
    └── KeyRecorderView.swift  # Key capture (NSViewRepresentable)
```

**Notable implementation details:**
- Global hotkeys use Carbon's `RegisterEventHotKey` + `InstallEventHandler`. Self is recovered inside the C callback via `Unmanaged`.
- Window manipulation uses `AXUIElement`. Coordinates require a flip: NSScreen uses a bottom-left origin while AX uses the top-left of the primary display.
- App Sandbox is disabled — required for both AXUIElement and Carbon hotkeys.

## Development Notes

Accessibility permissions are tied to the app's install path and code signature. Always use `make install` rather than running directly from Xcode's DerivedData — otherwise the app icon won't appear in System Settings and permissions won't stick.

If permissions get out of sync after a rebuild:

```bash
make clean && make install
```

## License

MIT
