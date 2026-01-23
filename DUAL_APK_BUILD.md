# Two APK Build Configuration

This repository is configured to build and release TWO separate APK files:

## APK Variants

### 1. Standard APK (`YouGame-{version}.apk`)
- **gradle_build**: disabled
- **Widget**: Not included
- **Size**: Smaller
- **Use case**: Standard game installation for most users

### 2. Widget APK (`YouGame-Widget-{version}.apk`)
- **gradle_build**: enabled  
- **Widget**: Included - home screen widget displaying save game status
- **Size**: Slightly larger
- **Use case**: For users who want the home screen widget feature

## Widget Features

The widget-enabled APK includes an Android home screen widget that displays:
- Last saved timestamp
- Current game day
- Player health percentage
- Torch inventory count
- Player position (X, Z coordinates)

See [ANDROID_WIDGET_IMPLEMENTATION.md](ANDROID_WIDGET_IMPLEMENTATION.md) for full widget documentation.

## Building Locally

### Standard APK
```bash
./build.sh
```

### Widget APK
The widget APK requires the Android build template to be installed:

```bash
# Install Android build template (one-time setup)
./install_android_build_template.sh

# Then build using the Widget preset
godot --headless --export-debug "Android Widget" export/YouGame-Widget.apk
```

## CI/CD Build Process

The GitHub Actions workflow automatically:
1. Builds the standard APK (always succeeds)
2. Installs the Android build template
3. Builds the widget APK (requires build template)
4. Creates releases with both APKs (if widget build succeeds)

## Export Presets

Two export presets are configured in `export_presets.cfg`:

- **preset.0** "Android" - Standard build
- **preset.1** "Android Widget" - Widget-enabled build

## Troubleshooting

### Widget APK build fails

If the widget APK build fails with "Android build template not installed":

1. Run the installation script: `./install_android_build_template.sh`
2. Ensure Godot 4.3.0 export templates are installed
3. Try the build again

### Android build template installation fails

Ensure:
- Godot 4.3.0 is installed
- Export templates are downloaded (Editor -> Manage Export Templates)
- You're running from the repository root directory
