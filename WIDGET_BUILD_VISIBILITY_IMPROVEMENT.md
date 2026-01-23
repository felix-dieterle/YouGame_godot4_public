# Widget Build Failure Visibility Improvement

## Problem Statement

The Android Widget build was failing in CI with the error:
```
ERROR: Export: Trying to build from a gradle built template, but no version info for it exists. Please reinstall from the 'Project' menu.
ERROR: Project export for preset "Android Widget" failed.
```

However, these failures were not clearly visible in the CI logs, making it difficult to diagnose and fix the issues.

## Root Cause

The widget build requires:
1. Android build template installed in `android/build/` directory
2. A `.gradle.build.version` file with the correct Godot version

When either of these requirements is not met, Godot fails with an error, but the error was being hidden by the `continue-on-error: true` flag in the workflow.

## Solution Implemented

### 1. Added Pre-Build Verification Step

A new step "Verify Android Build Template Installation" runs immediately after template installation to check:

- ✅ `android/build` directory exists
- ✅ `android/build/build.gradle` file is present
- ✅ `android/build/.gradle.build.version` file exists
- ✅ Version format is correct (X.Y.Z.stable)

**Benefits:**
- Fails fast if template installation didn't work correctly
- Shows exact file contents for debugging
- Clear error messages about what's missing

### 2. Enhanced Widget Build Error Reporting

Modified the "Build Widget APK" step to:

**Before:**
```bash
godot --headless --export-debug "Android Widget" export/YouGame-Widget.apk
```

**After:**
```bash
# Capture both stdout and stderr
set +e
godot --headless --export-debug "Android Widget" export/YouGame-Widget.apk 2>&1 | tee /tmp/widget_build.log
EXPORT_EXIT_CODE=${PIPESTATUS[0]}
set -e

# Analyze the output for specific error patterns
if grep -q "no version info for it exists" /tmp/widget_build.log; then
  echo "🔍 DETECTED: Missing version info error"
  # Show file status and contents
fi

# Display last 50 lines of output
tail -50 /tmp/widget_build.log
```

**Benefits:**
- All Godot output is captured and saved
- Specific error patterns are detected and explained
- Full context is available with last 50 lines of output
- Visual markers (✅, ❌, 🔍) make it easy to scan logs

### 3. Improved Status Reporting

Enhanced the "Report Widget Build Status" step to show:

```
=========================================
⚠️⚠️⚠️  WIDGET BUILD FAILED  ⚠️⚠️⚠️
=========================================

The widget-enabled APK could not be built.
Only the standard APK will be available for this build.

Common causes:
  1. Missing or incorrect .gradle.build.version file
  2. Incomplete Android build template installation
  3. Gradle build configuration issues

See the 'Build Widget APK' step above for detailed error information.
=========================================
```

**Benefits:**
- Impossible to miss in CI logs
- Provides common causes to check
- Points to where detailed information can be found

## Changes Made

### Files Modified

1. `.github/workflows/build.yml` - Enhanced error reporting in two places:
   - `build-android` job
   - `release` job

### Specific Enhancements

| Area | Enhancement |
|------|-------------|
| Template Installation | Added verification step with explicit checks |
| Error Detection | Captures all Godot output for analysis |
| Pattern Matching | Detects specific error messages and explains them |
| Visual Clarity | Uses emoji and banner lines for better readability |
| Debug Information | Shows file contents and exit codes |
| Context | Displays last 50 lines of output on failure |

## Expected Behavior

### When Build Succeeds

```
=========================================
Building Widget-enabled Android APK...
=========================================
Using debug export with automatic debug keystore signing

[Godot output]

=========================================
Widget Build Result Analysis
=========================================
✅ SUCCESS: Widget APK created successfully!
-rw-r--r-- 1 runner runner 45M YouGame-Widget.apk
```

### When Build Fails

```
=========================================
Building Widget-enabled Android APK...
=========================================
Using debug export with automatic debug keystore signing

[Godot output with errors]

=========================================
Widget Build Result Analysis
=========================================
❌ FAILURE: Widget APK was not created
Godot exit code: 1

Error Analysis:
🔍 DETECTED: Missing version info error
   The .gradle.build.version file may be missing or has incorrect content.
   Expected location: android/build/.gradle.build.version
   File exists with content: 4.3.0.stable

Full build output (last 50 lines):
-----------------------------------
[Detailed error output]
-----------------------------------

=========================================
⚠️⚠️⚠️  WIDGET BUILD FAILED  ⚠️⚠️⚠️
=========================================
```

## Testing

These changes improve visibility without changing the actual build logic. They will:

1. Make failures immediately obvious in CI logs
2. Provide clear diagnostic information
3. Help identify root causes faster
4. Guide users to fix common issues

## Benefits

1. **Faster Debugging**: Clear error messages and context reduce time to diagnosis
2. **Better Visibility**: Impossible to miss build failures in CI logs
3. **Actionable Information**: Specific guidance on common causes and fixes
4. **No Silent Failures**: All errors are captured and displayed
5. **Fail Fast**: Verification step catches issues before attempting to build

## Related Issues

This improvement addresses the issue where widget build failures were happening but not being clearly communicated in the CI output. The error message "Trying to build from a gradle built template, but no version info for it exists" is now:

1. ✅ Clearly displayed in logs
2. ✅ Explained with context
3. ✅ Accompanied by diagnostic information
4. ✅ Easy to spot with visual markers

## No Breaking Changes

These changes only affect:
- ✅ CI log output (improved)
- ✅ Error reporting (enhanced)
- ✅ Diagnostic information (added)

They do NOT affect:
- ❌ Build logic
- ❌ Export configuration
- ❌ Template installation process
- ❌ APK output
