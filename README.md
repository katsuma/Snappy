# Snappy

A macOS window manager inspired by [Divvy](https://mizage.com/divvy/).

Open a floating panel, drag across a grid to define any region, and snap the frontmost window into place instantly.

## Features

- **Floating panel** — Opens on launch and via the menu bar; shows the target app's icon and name
- **Grid drag selection** — Drag across a 6×4 grid to define any region, then release to snap
- **Local shortcuts** — Assign key combos that fire while the panel is open (no system-wide conflicts)
- **Optional global hotkey** — Optionally bind a global key combo to open the panel
- **Menu bar app** — Runs in the background with no Dock icon
- **Liquid Glass UI** — Built for macOS 26
- **Launch at Login** — Toggle from Settings

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

### Install to ~/Applications (default)

```bash
git clone https://github.com/katsuma/snappy.git
cd snappy
make install
```

### Install to /Applications (system-wide)

```bash
make install-system   # prompts for sudo password
```

Both commands build the app, copy it to the target directory, register it with LaunchServices, and launch it. Running from `~/Applications` or `/Applications` is required for Accessibility permissions and Launch at Login to work correctly.

### Uninstall

```bash
make clean
```

Removes the app from both `~/Applications` and `/Applications`, and resets Accessibility permissions.

## First-time Setup

1. Launch the app — a menu bar icon appears and the panel opens automatically
2. Click the menu bar icon → **Settings…**
3. **General** tab → click **Open System Settings…**
4. Enable Snappy under **Privacy & Security → Accessibility**
5. The status in Settings updates to "Access granted" within a few seconds

## Usage

### Snapping a window

1. The panel opens automatically when Snappy launches, or click the menu bar icon → **Show Panel**
2. The panel displays the frontmost app's icon and name as the target
3. Drag across the grid to define the region — release to snap the window
4. Press **Esc** or click **✕** to dismiss without snapping

### Adding a shortcut

1. Click **Settings…** → **Shortcuts** tab → **New**
2. Enter a name (e.g. `Left Half`)
3. Drag across the small grid to select the target region
4. Click the key recorder and press your desired key combo (e.g. `⌘←`)

### Using a shortcut

Open the panel, then press the configured key combo — the target window snaps to the assigned region and the panel closes.

Shortcuts are **local to the panel** and are not registered system-wide, so they never conflict with other apps' shortcuts.

### Optional global hotkey

To open the panel with a global key combo:

1. **Settings…** → **General** tab → enable **Use global shortcut to open panel**
2. Click the key recorder and press your desired combo

## Architecture

```
Snappy/
├── App/
│   ├── SnappyApp.swift          # @main entry point
│   └── AppDelegate.swift        # Menu bar, panel lifecycle, settings window
├── Models/
│   ├── Shortcut.swift           # Shortcut data model (name + region + key combo)
│   ├── GridRegion.swift         # Grid region (6×4)
│   └── KeyCombo.swift           # Key code + Carbon modifier flags
├── Services/
│   ├── SnapPanelManager.swift   # Panel window lifecycle, target app tracking
│   ├── HotkeyManager.swift      # Optional global hotkey via Carbon RegisterEventHotKey
│   ├── WindowMover.swift        # Window move/resize via AXUIElement
│   ├── ShortcutStore.swift      # JSON persistence (~/Library/Application Support/Snappy/)
│   └── PanelSettings.swift      # Panel hotkey settings (UserDefaults)
└── Views/
    ├── SnapPanelView.swift       # Floating panel (target app header + grid)
    ├── PreferencesView.swift     # Settings window (General + Shortcuts tabs)
    ├── GeneralView.swift         # Accessibility, login item, panel hotkey
    ├── ShortcutsView.swift       # Shortcut list
    ├── ShortcutRowView.swift     # Per-shortcut editor row
    ├── GridPickerView.swift      # 6×4 grid picker (Canvas + DragGesture)
    └── KeyRecorderView.swift     # Key capture (NSViewRepresentable)
```

**Notable implementation details:**

- The panel captures `NSWorkspace.frontmostApplication` and `kAXFocusedWindowAttribute` *before* activating Snappy, so the correct target window is always acquired. When Snappy is already frontmost (e.g. via menu bar click), it falls back to the last observed non-Snappy app tracked via `NSWorkspace.didActivateApplicationNotification`.
- Local shortcuts use `NSEvent.addLocalMonitorForEvents` installed while the panel is visible — they are never registered as global hotkeys.
- The optional global hotkey uses Carbon's `RegisterEventHotKey` + `InstallEventHandler`. Self is recovered inside the C callback via `Unmanaged`.
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
