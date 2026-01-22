# Android Widget Visual Guide

This document provides a visual description of the YouGame Save Status widget.

## Widget Appearance

The widget displays game save information with a dark theme matching the game's aesthetic.

```
┌─────────────────────────────────────┐
│ ╔═══════════════════════════════╗ │
│ ║ YouGame Save Status           ║ │  ← Title (white, bold)
│ ╚═══════════════════════════════╝ │
│                                     │
│ Last saved: Jan 22, 14:30          │  ← Timestamp (light gray)
│                                     │
│ ┌────────────┬──────────────────┐  │
│ │ Day        │ Health           │  │
│ │ 5          │ 75%              │  │  ← Day count & Health (bold)
│ └────────────┴──────────────────┘  │
│                                     │
│ ┌────────────┬──────────────────┐  │
│ │ Torches    │ Position         │  │
│ │ 42         │ 100, 200         │  │  ← Torches & Position (bold)
│ └────────────┴──────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

## Color Scheme

- **Background**: Dark semi-transparent (#DD000000)
- **Border**: Green (#FF4CAF50) with 8dp rounded corners
- **Title**: White (#FFFFFF), bold, 16sp
- **Timestamp**: Light gray (#CCCCCC), 12sp
- **Labels**: Gray (#AAAAAA), 10sp
- **Values**: 
  - Day count: White (#FFFFFF), bold, 14sp
  - Health: Green (#00FF00), bold, 14sp
  - Torches: Orange (#FFA500), bold, 14sp
  - Position: White (#FFFFFF), 12sp

## Widget States

### With Save Data
When the game has been saved at least once, the widget displays:
- Current save timestamp
- Day number in the game
- Player's health percentage
- Number of torches in inventory
- Player's position (X, Z coordinates)

### No Save Data
When no save file exists, the widget displays:
- "No save data available" message
- All metrics show "--"

## Widget Sizes

The widget is resizable with:
- **Minimum width**: 250dp (~2-3 home screen columns)
- **Minimum height**: 120dp (~1-2 home screen rows)
- **Resize mode**: Horizontal and vertical
- **Category**: Home screen widget

## Interaction

- **Tap on title**: Opens the YouGame application
- **Auto-update**: Widget refreshes automatically when the game is saved
- **Manual refresh**: Updates every 30 minutes (system default)

## Use Cases

### 1. Quick Status Check
Players can glance at their home screen to see:
- How far they've progressed (day count)
- Current health status
- Resource availability (torches)
- Where they are in the world

### 2. Bug Analysis
When reporting bugs, developers/players can:
- See the exact game state before reproducing an issue
- Know the player position for location-specific bugs
- Verify save data integrity
- Check if certain metrics are updating correctly

### 3. Game Planning
Players can decide whether to:
- Continue their current game or start fresh
- Prepare for nighttime (if day count indicates it)
- Check if they have enough resources (torches)

## Technical Notes

### Data Update Flow
```
Game Save Event
    ↓
Widget displays updated info within 1 second
```

### Data Persistence
- Widget data survives app restarts
- Widget data survives device restarts
- Clearing app data will reset widget to "No save data"

### Platform Requirements
- Android API 21+ (Android 5.0 Lollipop)
- Requires game to be installed
- No special permissions needed
- Works on all Android launchers supporting widgets

## Future Enhancements

Potential visual improvements:
- [ ] Add battery indicator for flashlight
- [ ] Show air level (underwater oxygen)
- [ ] Display time of day (morning/afternoon/night)
- [ ] Add small map preview
- [ ] Show crystal inventory summary
- [ ] Health bar visualization (graphical instead of percentage)
- [ ] Different widget sizes (1x1, 2x1, 2x2, 4x2)

## Screenshot Reference

_Note: Actual screenshots will be available after building and installing the APK on an Android device._

Expected appearance on home screen:
- Widget blends with other home screen elements
- Green border makes it easily identifiable
- Dark background ensures text readability
- Compact size allows placement alongside other widgets

## Comparison with In-Game UI

The widget provides a subset of the information shown in the game's pause menu or save screen:
- **Widget**: Quick glance at key metrics
- **In-Game**: Full details including inventory, quests, settings, etc.

This makes the widget perfect for external monitoring without needing to launch the game.
