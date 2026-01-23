# Widget-Enabled APK Build Fix Summary

## Problem Diagnosed

### User Question (German)
> "Note: Widget-enabled APK build was not available for this release. was heißt das? stimmt da was nicht?"
> 
> Translation: "Note: Widget-enabled APK build was not available for this release. What does that mean? Is something wrong?"

### Issue
Starting with release v1.0.117, the widget-enabled APK was no longer being built by the GitHub Actions workflow. Release notes showed:

```
**Note:** Widget-enabled APK build was not available for this release.
```

This was intentional fallback text, but indicated a real problem - the widget build was failing.

## Root Cause Analysis

### Background
The repository builds TWO APK variants:
1. **Standard APK** (`YouGame-{version}.apk`) - Uses regular Godot export (gradle_build=false)
2. **Widget APK** (`YouGame-Widget-{version}.apk`) - Uses Gradle build (gradle_build=true) with Android home screen widget support

The widget APK requires the Android build template to be installed in `android/build/` directory.

### What Went Wrong
The GitHub Actions workflow uses `chickensoft-games/setup-godot@v1` to install Godot and export templates. However:

1. The `install_android_build_template.sh` script looked for templates at:
   ```
   $HOME/.local/share/godot/export_templates/4.3.stable
   ```

2. The chickensoft action may install templates in a different location or format

3. When the script couldn't find templates, it exited with an error

4. The workflow had `|| { echo warning }` which allowed the build to continue

5. The widget APK build then failed with:
   ```
   ERROR: Cannot export project with preset "Android Widget" due to configuration errors:
   Android build template not installed in the project.
   ```

6. The workflow detected this failure and generated release notes saying "Widget-enabled APK build was not available"

## Solution Implemented

### 1. Enhanced Install Script (`install_android_build_template.sh`)

Made the template search more robust by checking multiple possible locations:

```bash
POSSIBLE_TEMPLATE_DIRS=(
    "$HOME/.local/share/godot/export_templates/$GODOT_VERSION"
    "$HOME/.local/share/godot/export_templates/4.3.0"
    "$HOME/.local/share/godot/templates/$GODOT_VERSION"
    "$HOME/.local/share/godot/templates/4.3.0"
    "/home/runner/.local/share/godot/export_templates/$GODOT_VERSION"
    "/home/runner/.local/share/godot/export_templates/4.3.0"
)
```

Also added a fallback using `find` command to search the entire godot directory tree.

### 2. Added Fallback in Workflow (`.github/workflows/build.yml`)

If the install script fails, the workflow now:

1. Downloads Godot export templates directly from GitHub releases:
   ```bash
   wget https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
   ```

2. Extracts the `.tpz` file (which is actually a ZIP)

3. Finds `android_source.zip` within the extracted templates

4. Extracts `android_source.zip` to `android/build/` directory

5. Verifies that `build.gradle` exists to confirm successful installation

### 3. Improved Error Handling

- Changed `wget -q` to `wget -nv` for better error visibility
- Added explicit error checks with `if ! command; then ... fi` pattern
- Added informative error messages at each step
- Shows file sizes and directory contents when things fail for easier debugging

### 4. Reduced Code Duplication

Moved the Godot version to job-level environment variable:
```yaml
env:
  GODOT_RELEASE_VERSION: "4.3-stable"
```

This is used in both the `build-android` and `release` jobs.

## Expected Outcome

With these changes:

1. **Primary path**: If chickensoft action installs templates in a findable location, the script will locate and use them
2. **Fallback path**: If templates aren't found, workflow downloads them directly from Godot releases
3. **Widget APK builds successfully** and both APKs are included in releases
4. **Release notes show both APKs** with descriptions of each variant

Future releases should include:
- `YouGame-{version}.apk` - Standard APK
- `YouGame-Widget-{version}.apk` - Widget-enabled APK

With release notes explaining both variants.

## Testing Status

The fix has been implemented and committed to the PR branch. Testing will occur when:
- The PR workflow is approved and runs successfully, OR
- The PR is merged to main and triggers a release

## Answer to User's Question

**German:**
> Die Nachricht "Widget-enabled APK build was not available for this release" bedeutet, dass das Build-System die Widget-Version der APK nicht erstellen konnte. Ja, da stimmte etwas nicht - das Android Build Template wurde nicht gefunden. Ich habe das Problem jetzt behoben. Ab dem nächsten Release sollten wieder beide APK-Varianten verfügbar sein.

**English:**
> The message "Widget-enabled APK build was not available for this release" means that the build system couldn't create the widget version of the APK. Yes, something was wrong - the Android build template wasn't being found. I've now fixed the problem. Starting with the next release, both APK variants should be available again.

## Files Modified

1. `install_android_build_template.sh` - Enhanced template search logic
2. `.github/workflows/build.yml` - Added fallback download mechanism, improved error handling, reduced duplication

## Security Analysis

- ✅ No security vulnerabilities detected by CodeQL
- ✅ Downloads use HTTPS from official Godot GitHub releases
- ✅ No credentials or secrets exposed
- ✅ Proper error handling prevents silent failures
