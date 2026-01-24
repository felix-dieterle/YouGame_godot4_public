# DEPRECATED: Godot Plugin-Based Widget

**Status:** This Godot plugin-based widget implementation is **deprecated** and no longer used.

## Reason for Deprecation

This plugin-based approach caused constant build failures:
- Required complex Android build template installation
- Gradle/Godot version compatibility issues
- CI/CD build instability
- Errors: "Android build template not installed" or "no version info for it exists"

## Replacement

The widget has been reimplemented as a **standalone native Android app**.

See: **[../../../widget_app/](../../../widget_app/)** for the new implementation.

## New Architecture

Instead of integrating the widget into the Godot build, we now have:
- **Main Game APK**: Pure Godot build (no Gradle needed)
- **Widget APK**: Standalone native Android app
- **Data Sharing**: File-based communication via external storage

Benefits:
- ✅ No build template installation needed
- ✅ Simple, reliable builds
- ✅ Independent widget development
- ✅ Widget failures don't block game release

## Documentation

- [STANDALONE_WIDGET_IMPLEMENTATION.md](../../../STANDALONE_WIDGET_IMPLEMENTATION.md) - New architecture
- [widget_app/README.md](../../../widget_app/README.md) - Widget development guide
- [DUAL_APK_BUILD.md](../../../DUAL_APK_BUILD.md) - Build configuration

## This Directory

This directory is kept for:
- Historical reference
- Potential rollback if needed
- Understanding the evolution of the widget implementation

**Do not use this code for new development.**

---

**Deprecated:** 2026-01-24  
**Replacement:** `widget_app/` standalone native widget
