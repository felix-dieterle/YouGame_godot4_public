# Widget Build Fix - Trailing Newline Issue

## Problem Statement

The widget-enabled Android APK build was consistently failing in CI/CD with the error:
```
ERROR: Export: Trying to build from a gradle built template, but no version info for it exists. 
Please reinstall from the 'Project' menu.
```

Despite the `.gradle.build.version` file existing with the correct content `4.3.stable`, Godot was not recognizing it as valid.

## Root Cause Analysis

The issue was caused by **a trailing newline character** in the `.gradle.build.version` file. 

### Technical Details

When using the `echo` command in bash:
```bash
echo "4.3.stable" > android/build/.gradle.build.version
```

This creates a file containing:
```
4.3.stable\n
```
(11 bytes: 10 for the text + 1 for newline)

When Godot reads this file and compares it to its internal version string `"4.3.stable"` (10 bytes), the comparison fails because:
- File content: `"4.3.stable\n"` (with newline)
- Expected value: `"4.3.stable"` (without newline)
- Result: Mismatch → Error

### Verification

Created a test script that confirmed:
```bash
# With echo (adds newline)
echo "4.3.stable" > test.txt
# Result: 11 bytes, contains "4.3.stable\n"

# With echo -n (no newline)  
echo -n "4.3.stable" > test.txt
# Result: 10 bytes, contains "4.3.stable"
```

## Solution Implemented

### 1. Use `echo -n` Instead of `echo`

Changed all instances where `.gradle.build.version` is created to use `echo -n`:

**Before:**
```bash
echo "4.3.stable" > android/build/.gradle.build.version
```

**After:**
```bash
echo -n "4.3.stable" > android/build/.gradle.build.version
```

### 2. Extract Version from Templates

Added logic to extract the version from the templates' `version.txt` file to ensure exact version matching:

```bash
VERSION_FILE=$(find /tmp/godot_templates -name "version.txt" | head -n 1)
if [ -n "$VERSION_FILE" ]; then
  TEMPLATE_VERSION=$(tr -d '\r\n' < "$VERSION_FILE")
  echo -n "$TEMPLATE_VERSION" > android/build/.gradle.build.version
else
  # Fallback
  echo -n "4.3.stable" > android/build/.gradle.build.version
fi
```

This ensures the version in `.gradle.build.version` exactly matches the version in the downloaded templates.

## Files Modified

1. **`.github/workflows/build.yml`** (2 locations)
   - build-android job: Install Android Build Template step
   - release job: Install Android Build Template step
   
2. **`install_android_build_template.sh`**
   - Changed `echo "$GODOT_VERSION"` to `echo -n "$GODOT_VERSION"`

## Code Quality Improvements

Based on code review feedback, also improved the code:
- Removed useless use of `cat` (UUOC): Changed from `cat "$FILE" | tr` to `tr < "$FILE"`
- Simplified file existence check: Removed redundant `[ -f "$FILE" ]` when `find` already ensures file exists

## Expected Outcome

With these fixes:
1. The `.gradle.build.version` file will contain exactly `4.3.stable` without any trailing characters
2. Godot's version comparison will succeed
3. The widget-enabled APK will build successfully in CI/CD
4. Both APK variants will be available in releases

## Testing

- ✅ Local test script verified `echo -n` produces correct output (10 bytes, no newline)
- ✅ Code review completed - feedback addressed
- ✅ CodeQL security scan - no vulnerabilities detected
- ⏳ CI/CD testing - will be validated when PR is merged

## Related Documentation

- Previous attempt: `WIDGET_BUILD_VERSION_FIX.md` (changed from 4.3.0.stable to 4.3.stable)
- This fix: Removes trailing newline that was preventing version match

## Security Analysis

- ✅ No security vulnerabilities introduced
- ✅ All changes are in build scripts and CI configuration
- ✅ No credentials or secrets exposed
- ✅ CodeQL scan passed with 0 alerts
