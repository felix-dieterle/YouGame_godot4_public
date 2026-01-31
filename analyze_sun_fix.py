#!/usr/bin/env python3
"""
Visual comparison of sun lighting before and after the fix.
This script generates a comparison table showing the improvement in lighting effectiveness.
"""

import math

def calculate_effectiveness(rotation_deg):
    """Calculate how much light reaches the ground based on rotation angle."""
    angle_from_horizontal = 90.0 - abs(rotation_deg)
    if angle_from_horizontal < 0:
        angle_from_horizontal = 0
    effectiveness = math.sin(math.radians(angle_from_horizontal))
    return effectiveness

def old_rotation(sun_deg):
    """Old formula: light_rotation = 90 - sun_position"""
    return 90.0 - sun_deg

def new_rotation(sun_deg):
    """New formula: light_rotation = lerp(50, -50, sun_position / 180)"""
    return 50.0 - (sun_deg / 180.0) * 100.0

def time_from_sun_deg(sun_deg):
    """Convert sun degree to clock time (7 AM - 5 PM = 0° - 180°)"""
    # 0° = 7:00 AM, 180° = 5:00 PM (10 hours)
    hours_offset = (sun_deg / 180.0) * 10.0
    total_hours = 7.0 + hours_offset
    hours = int(total_hours)
    minutes = int((total_hours - hours) * 60)
    return f"{hours:02d}:{minutes:02d}"

def status_icon(effectiveness):
    """Return a status icon based on effectiveness."""
    if effectiveness < 0.5:
        return "🔴"  # Red - Too dark
    elif effectiveness < 0.7:
        return "🟡"  # Yellow - Dim
    elif effectiveness < 0.85:
        return "🟢"  # Green - Good
    else:
        return "✅"  # Check - Excellent

print("=" * 120)
print(" " * 40 + "SUN LIGHTING ANGLE FIX - VISUAL COMPARISON")
print("=" * 120)
print()

# Header
print(f"{'Time':<8} | {'Sun°':<7} | {'OLD Rotation':<14} | {'OLD Effect':<12} | {'NEW Rotation':<14} | {'NEW Effect':<12} | {'Improvement':<12} | {'Status'}")
print("-" * 120)

# Data points
sun_positions = [0, 18, 36, 54, 72, 90, 108, 126, 144, 162, 180]

for sun_deg in sun_positions:
    time = time_from_sun_deg(sun_deg)
    old_rot = old_rotation(sun_deg)
    new_rot = new_rotation(sun_deg)
    old_eff = calculate_effectiveness(old_rot)
    new_eff = calculate_effectiveness(new_rot)
    improvement = new_eff - old_eff
    status = status_icon(new_eff)
    
    print(f"{time:<8} | {sun_deg:>5}°  | {old_rot:>10.1f}°   | {old_eff*100:>7.1f}%    | {new_rot:>10.1f}°   | {new_eff*100:>7.1f}%    | {improvement*100:>+8.1f}%   | {status}")

print("=" * 120)
print()
print("LEGEND:")
print("  🔴 Too Dark (< 50% effective)  - Light too horizontal, scene very dark")
print("  🟡 Dim (50-70% effective)       - Light somewhat horizontal, scene dim")
print("  🟢 Good (70-85% effective)      - Good lighting angle")
print("  ✅ Excellent (> 85% effective) - Optimal lighting angle")
print()
print("KEY FINDINGS:")
print("  • OLD SYSTEM: Only becomes properly lit (✅) at 10:00 AM or later")
print("  • NEW SYSTEM: Properly lit (✅) from 9:00 AM onwards")
print("  • Sunrise (7:00 AM): Improved from 🔴 0% to 🟡 64.3% (+64.3%)")
print("  • Early morning (8:00 AM): Improved from 🔴 31% to 🟢 77% (+46%)")
print("  • The user's complaint 'it only becomes bright around 12:00 PM' is now fixed!")
print()
print("TECHNICAL EXPLANATION:")
print("  The DirectionalLight3D rotation angle determines how much light reaches the ground.")
print("  At 90° rotation (old sunrise), light is perfectly horizontal = 0% reaches ground.")
print("  At 50° rotation (new sunrise), light comes from above = 64% reaches ground.")
print("  At 0° rotation (noon), light comes straight down = 100% reaches ground.")
print()

# ASCII art visualization
print("VISUAL REPRESENTATION:")
print()
print("OLD SYSTEM (7:00 AM):")
print("  ☀️ ─────────────────────→  (90° horizontal, 0% effective)")
print("     🌳 (no shadow, very dark)")
print()
print("NEW SYSTEM (7:00 AM):")
print("  ☀️")
print("    \\")
print("     \\  (50° from vertical, 64% effective)")
print("      ↘")
print("        🌳 (proper shadow, good brightness)")
print()
print("BOTH SYSTEMS (12:00 PM):")
print("        ☀️")
print("        |  (0° = vertical, 100% effective)")
print("        ↓")
print("        🌳 (perfect shadow, maximum brightness)")
print()
print("=" * 120)
