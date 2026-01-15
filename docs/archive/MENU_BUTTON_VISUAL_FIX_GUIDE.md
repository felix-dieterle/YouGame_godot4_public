# Visual Guide: Menu Button Visibility Fix

## Before Fix - Button Hidden ❌

```
┌─────────────────────────────────────────────┐
│ 📋🗑 Debug Panel (z=99)      🐛 (z=10)      │
│ [Green debug log window visible]            │
│                                             │
│                                             │
│           3D GAME VIEW                      │
│                                             │
│                                             │
│                                             │
│    (o) Joystick                 [☰ HIDDEN] │ ← Menu button exists but not visible!
└─────────────────────────────────────────────┘

Rendering Order (Scene Tree):
1. UIManager (z=0)        → Renders first (bottom)
2. MobileControls (z=0)   → Renders second
   └─ Menu button (z=10)  → Effective z-index: 0+10 = 10
3. DebugNarrativeUI (z=0) → Renders third
4. DebugLogOverlay (z=0)  → Renders last (top)
   └─ Panel (z=99)        → Effective z-index: 0+99 = 99

Problem: 99 > 10, so debug overlay covers menu button!
```

## After Fix - Button Visible ✅

```
┌─────────────────────────────────────────────┐
│ 📋🗑 Debug Panel (z=104)      🐛 (z=111)    │
│ [Green debug log window visible]            │
│                                             │
│                                             │
│           3D GAME VIEW                      │
│                                             │
│                                             │
│                                             │
│    (o) Joystick                  ☰ VISIBLE │ ← Menu button now on top!
└─────────────────────────────────────────────┘

Rendering Order (Effective Z-Index):
  0 - UIManager labels (0+0)
104 - Debug log panel (5+99)
105 - Debug log buttons (5+100)
111 - Menu button (10+101)        ← NOW ON TOP!
111 - Debug narrative button (10+101)
112 - Settings panel (10+102)

Solution: 111 > 104-105, so menu button renders above debug overlay!
```

## Z-Index Calculation Explained

### How Godot Calculates Effective Z-Index

```
Effective Z-Index = Parent Z-Index + Child Z-Index
```

### Example: Menu Button

**Before:**
```
Parent (MobileControls): z_index = 0 (default)
Child (menu_button):     z_index = 10
─────────────────────────────────────────
Effective Z-Index:       0 + 10 = 10
```

**After:**
```
Parent (MobileControls): z_index = 10
Child (menu_button):     z_index = 101
─────────────────────────────────────────
Effective Z-Index:       10 + 101 = 111
```

### Example: Debug Log Panel

**Before:**
```
Parent (DebugLogOverlay): z_index = 0 (default)
Child (log_panel):        z_index = 99
─────────────────────────────────────────
Effective Z-Index:        0 + 99 = 99

Result: 99 > 10, panel covers menu button ❌
```

**After:**
```
Parent (DebugLogOverlay): z_index = 5
Child (log_panel):        z_index = 99
─────────────────────────────────────────
Effective Z-Index:        5 + 99 = 104

Result: 104 < 111, menu button appears on top ✅
```

## Complete Z-Index Hierarchy

```
                    BEFORE FIX                   AFTER FIX
                ╔════════════════╗           ╔════════════════╗
Higher   ┌──────║  Debug Panel  ║           ║ Settings Panel ║ 112
         │      ║   (z=99)      ║           ╟────────────────╢
         │      ╚════════════════╝           ║  Menu Button   ║ 111
         │                                   ║  Debug Button  ║ 111
         │                                   ╟────────────────╢
Render   │                                   ║  Debug Btns    ║ 105
Order    │                                   ╟────────────────╢
         │      ╔════════════════╗           ║  Debug Panel   ║ 104
         │      ║  Menu Button  ║           ╟────────────────╢
         │      ║   (z=10)      ║           ║  UI Labels     ║   0
         └──────╚════════════════╝           ╚════════════════╝
Lower            BUTTON HIDDEN!              BUTTON VISIBLE!
```

## Interactive Elements Layer Priority

Our fix ensures this priority order:

```
Layer 3 (z=10+): Interactive UI Controls
┌────────────────────────────────────────────┐
│ • Menu Button (tap to open settings)       │
│ • Debug Button (tap to show debug info)    │
│ • Settings Panel (when opened)             │
└────────────────────────────────────────────┘
         ↑ ALWAYS ACCESSIBLE TO USER

Layer 2 (z=5+): Debug Information
┌────────────────────────────────────────────┐
│ • Debug Log Panel (informational)          │
│ • Debug Log Buttons (view/clear logs)      │
└────────────────────────────────────────────┘
         ↑ VISIBLE BUT NOT BLOCKING

Layer 1 (z=0+): Status Labels
┌────────────────────────────────────────────┐
│ • Loading messages                         │
│ • Chunk generation info                    │
└────────────────────────────────────────────┘
         ↑ BACKGROUND INFORMATION
```

## Key Takeaways

1. **Z-Index is Additive**: Child z-index + Parent z-index = Effective z-index
2. **Scene Order Matters**: Siblings with same z-index render in tree order
3. **Set Parent Z-Indices**: Always set explicit z-index on parent Controls
4. **Plan the Hierarchy**: Group related UI elements in same z-index range

## Testing Verification

When testing, verify this rendering from bottom to top:

```
[ ] Status labels appear in background
[ ] Debug panel appears above status
[ ] Debug buttons appear above panel
[ ] Menu button appears above everything (interactive)
[ ] Settings panel appears on top when opened
```

All checkboxes should be ✅ after fix!
