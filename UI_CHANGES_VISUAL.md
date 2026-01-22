# UI Changes - Visual Guide

## Debug Log Overlay - New Export Buttons

### Before
```
┌─────────────────────────────────────────┐
│ [📋] [🗑] [📄]                          │ ← Only 3 buttons
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Debug Log Panel                     │ │
│ │                                     │ │
│ │ [10.23s] Player spawned             │ │
│ │ [11.45s] World generated            │ │
│ │ [12.78s] Day cycle started          │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### After
```
┌─────────────────────────────────────────────────┐
│ [📋] [🗑] [📄] [☀] [🌙]                        │ ← 5 buttons now!
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ Debug Log Panel                             │ │
│ │                                             │ │
│ │ [10.23s] Player spawned                     │ │
│ │ [11.45s] World generated                    │ │
│ │ [12.78s] Day cycle started                  │ │
│ │ [15.67s] Sun lighting logs exported! (142)  │ │ ← Export confirmation
│ │ [15.67s] File: user://logs/sun_lighting...  │ │
│ │                                             │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Button Functions

| Button | Color  | Function                              |
|--------|--------|---------------------------------------|
| 📋     | Blue   | Toggle log panel visibility           |
| 🗑     | Red    | Clear current debug logs              |
| 📄     | Green  | Copy logs to clipboard                |
| ☀     | Yellow | **Export sun lighting issue logs**    |
| 🌙     | Purple | **Export sleep state issue logs**     |

## Export Flow

### Sun Lighting Logs (☀ Button)

```
1. Player notices lighting issue
   ↓
2. Clicks ☀ button
   ↓
3. System creates file: sun_lighting_issue_2026-01-22T19-16-36.log
   ↓
4. Confirmation shown in debug log
   ↓
5. File path displayed
   ↓
6. Player can find file in:
   - Windows: %APPDATA%\Godot\app_userdata\YouGame\logs\
   - Linux: ~/.local/share/godot/app_userdata/YouGame/logs\
   - Android: /storage/emulated/0/Android/data/com.yougame.godot4/files/logs/
```

### Sleep State Logs (🌙 Button)

```
1. Player loads save game (was in sleeping phase)
   ↓
2. Notices sleep state issue
   ↓
3. Clicks 🌙 button
   ↓
4. System creates file: sleep_state_issue_2026-01-22T19-16-36.log
   ↓
5. Confirmation shown in debug log
   ↓
6. File contains all sleep state data from load
```

## Log File Format

### Sun Lighting Issue Log
```
=== YouGame Debug Logs ===
Log Type: SUN_LIGHTING
Export Time: 2026-01-22 19:16:36
Total Entries: 142
Game Version: 1.0.107
================================

[2026-01-22 19:16:36] Sun Position: 85.23° | Sun Angle: -15.67° | Light Energy: 2.45 | Time Ratio: 0.35 | Current Time: 1890.45
[2026-01-22 19:16:37] Sun Position: 86.12° | Sun Angle: -14.98° | Light Energy: 2.48 | Time Ratio: 0.36 | Current Time: 1920.12
[2026-01-22 19:16:38] SUNRISE - Progress: 0.95 | Sun Position: 7.00° | Sun Angle: -21.00° | Light Energy: 1.14
...
[2026-01-22 19:22:15] Sun Position: 179.45° | Sun Angle: 19.45° | Light Energy: 1.25 | Time Ratio: 0.98 | Current Time: 5285.67
[2026-01-22 19:22:16] SUNSET - Progress: 0.12 | Sun Position: 32.00° | Sun Angle: 32.00° | Light Energy: 1.06
```

### Sleep State Issue Log
```
=== YouGame Debug Logs ===
Log Type: SLEEP_STATE
Export Time: 2026-01-22 19:16:36
Total Entries: 8
Game Version: 1.0.107
================================

[2026-01-22 19:16:36] LOAD - is_locked_out: true | lockout_end_time: 1737577136.00 | current_unix_time: 1737563136.00 | time_until_end: 14400.00 | current_time: 5400.00 | day_count: 3 | night_start_time: 1737562736.00
[2026-01-22 19:16:36] DayNightCycle LOAD - is_locked_out: true | lockout_end_time: 1737577136.00 | current_unix_time: 1737563136.00 | time_until_end: 14400.00 | current_time: 5400.00 | day_count: 3 | night_start_time: 1737562736.00
```

## Widget Integration (No UI Change in Game)

The widget appears on the Android home screen after installation:

```
Android Home Screen
┌────────────────────────────────────┐
│                                    │
│  ┌──────────────────────────────┐  │
│  │ YouGame Save Status          │  │
│  │                              │  │
│  │ Day: 3                       │  │
│  │ Health: 87%                  │  │
│  │ Torches: 45                  │  │
│  │ Position: (123.5, 456.7)     │  │
│  │                              │  │
│  │ Last saved: 2 hours ago      │  │
│  └──────────────────────────────┘  │
│                                    │
└────────────────────────────────────┘
```

Widget updates automatically when game is saved!
