# Widget Build Version Format Fix

## Problem
The widget-enabled Android APK build was failing with the error:
```
ERROR: Export: Trying to build from a gradle built template, but no version info for it exists. 
Please reinstall from the 'Project' menu.
```

## Root Cause
The `.gradle.build.version` file was being created with the version string `4.3.0.stable`, but Godot 4.3 expects the version format `4.3.stable` (without the patch version `.0`).

When Godot exports an Android project using a gradle build template, it checks the `.gradle.build.version` file to verify that the template version matches the Godot version. The version format mismatch caused Godot to reject the template as invalid.

## Evidence
- Godot version: `Godot Engine v4.3.stable.official.77dcf97d8`
- Expected version in `.gradle.build.version`: `4.3.stable`
- Actual version (before fix): `4.3.0.stable` ❌

The Godot version string uses the format `X.Y.stable` (e.g., `4.3.stable`), not `X.Y.Z.stable`.

## Solution
Updated all references to the version format from `4.3.0.stable` to `4.3.stable`:

### Files Changed
1. **install_android_build_template.sh**
   - Changed `GODOT_VERSION` from `"4.3.0.stable"` to `"4.3.stable"`

2. **.github/workflows/build.yml**
   - Updated version string written to `.gradle.build.version` file (2 locations)
   - Updated regex validation pattern from `^[0-9]+\.[0-9]+\.[0-9]+\.stable$` to `^[0-9]+\.[0-9]+\.stable$`
   - Updated expected format messages from "X.Y.Z.stable" to "X.Y.stable"

3. **Documentation updates**
   - DUAL_APK_BUILD.md
   - WIDGET_BUILD_VISIBILITY_IMPROVEMENT.md
   - WIDGET_BUILD_FIX_SUMMARY.md

## Expected Outcome
With this fix, the `.gradle.build.version` file will now contain the correct version format that matches Godot's expectations. The widget-enabled APK should build successfully in CI/CD pipelines.

## Testing
The fix will be validated when:
- The GitHub Actions workflow runs and successfully builds both APK variants
- The widget-enabled APK exports without the "no version info" error

## Related Issues
This fix addresses the CI build failure where the widget APK was not being created, resulting in releases that only included the standard APK.
