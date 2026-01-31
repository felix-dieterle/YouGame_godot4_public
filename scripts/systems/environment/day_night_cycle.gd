extends Node3D
class_name DayNightCycle

#region ===== DAY/NIGHT CYCLE OVERVIEW =====
# This system manages the complete day/night cycle including:
# 
# DAY CYCLE TIMING (7:00 AM - 5:00 PM = 10 game hours):
#   - Day begins at 7:00 AM with sunrise animation (60 seconds)
#   - Sun rises from horizon (0°) to zenith at noon (90°)
#   - Sun sets from zenith to horizon (180°) at 5:00 PM
#   - Day ends at 5:00 PM with sunset animation (60 seconds)
#   - Night period enforces 4-hour lockout before next day
#
# BRIGHTNESS PROGRESSION:
#   - Darkest: At sunrise (7:00 AM) and sunset (5:00 PM) - MIN_LIGHT_ENERGY (1.2)
#   - Brightest: At noon (12:00 PM) - MAX_LIGHT_ENERGY (3.0)
#   - Brightness follows quadratic curve: intensity = 1.0 - (distance_from_noon)²
#   - Night: Complete darkness (0.0 light energy)
#
# SUN POSITION & LIGHTING:
#   - Display angle: 0° (sunrise/7AM) → 90° (noon/12PM) → 180° (sunset/5PM)
#   - Light rotation: +50° (sunrise) → 0° (noon) → -50° (sunset)
#   - Limited to ±50° to ensure light reaches ground (64% effective at sunrise/sunset)
#   - Position during night: -1 (not visible)
#endregion

#region ===== TIME CONFIGURATION =====
# Core timing constants that define the day/night cycle structure
const DAY_CYCLE_DURATION: float = 90.0 * 60.0  # 90 minutes in seconds (3x longer for player)
const DAY_DURATION_HOURS: float = 10.0  # Day cycle represents 10 game hours (7 AM to 5 PM)
const INITIAL_TIME_OFFSET_HOURS: float = 0.0  # Hours to advance sun position at game start (0.0 = start at sunrise, 7:00 AM)

# Transition timing
const SUNRISE_DURATION: float = 60.0  # 1 minute sunrise animation (7:00 AM)
const SUNSET_DURATION: float = 60.0  # 1 minute sunset animation (5:00 PM)

# Night lockout and warnings
const SLEEP_LOCKOUT_DURATION: float = 4.0 * 60.0 * 60.0  # 4 hours in seconds
const WARNING_TIME_2MIN: float = 2.0 * 60.0  # 2 minutes before sunset
const WARNING_TIME_1MIN: float = 1.0 * 60.0  # 1 minute before sunset

# Save file path
const SAVE_FILE_PATH: String = "user://day_night_save.cfg"
#endregion

#region ===== BRIGHTNESS & LIGHTING CONFIGURATION =====
# Lighting intensity constants that control brightness throughout the day
# The brightness follows a quadratic curve from sunrise to sunset:
# - MIN at sunrise (7:00 AM) → MAX at noon (12:00 PM) → MIN at sunset (5:00 PM)
const MIN_LIGHT_ENERGY: float = 1.2        # Minimum light at sunrise/sunset (7 AM / 5 PM)
const MAX_LIGHT_ENERGY: float = 3.0        # Maximum light at noon (12:00 PM)

# Light rotation configuration
# Controls the angle range of the DirectionalLight3D to ensure proper ground illumination
# Using ±50° instead of ±90° ensures light reaches ground effectively even at sunrise/sunset
const MAX_LIGHT_ANGLE: float = 50.0        # Maximum rotation from noon position (0° = overhead)

# Color constants for sunset warmth effect
const SUNSET_WARMTH_FACTOR: float = 0.7    # How quickly warmth builds during sunset
const SUNSET_COLOR_INTENSITY: float = 1.5  # Intensity of warm colors during sunset
#endregion

#region ===== CELESTIAL OBJECTS CONFIGURATION =====
# Distance constants for positioning sun, moon, and stars in the sky
const CELESTIAL_DISTANCE: float = 2000.0   # Distance for sun and moon from player
const MOON_ZENITH_HEIGHT: float = 1500.0   # Moon height at zenith during night
const STAR_DISTANCE: float = 1800.0        # Distance for stars (closer than sun/moon)
#endregion

#region ===== DEBUG & DEVELOPMENT =====
# Debug mode for faster testing
@export var debug_mode: bool = false  # When true, time runs 60x faster
@export var debug_skip_lockout: bool = false  # When true, skip the 4-hour lockout
#endregion

#region ===== STATE VARIABLES =====
# Time tracking variables
var current_time: float = 0.0  # Current time in the day cycle (0 to DAY_CYCLE_DURATION)
var time_scale: float = 2.0  # Multiplier for time progression (2.0 = default)
var sun_time_offset_hours: float = 0.0  # Offset in hours to adjust displayed time

# Day/Night state
var is_night: bool = false
var is_locked_out: bool = false
var lockout_end_time: float = 0.0  # Unix timestamp when lockout ends
var day_count: int = 1  # Track number of days passed
var night_start_time: float = 0.0  # Unix timestamp when night began

# Transition animation states
var is_animating_sunrise: bool = false
var sunrise_animation_time: float = 0.0
var is_animating_sunset: bool = false
var sunset_animation_time: float = 0.0

# Warning states
var warning_2min_shown: bool = false
var warning_1min_shown: bool = false

# Logging throttle
var last_log_time: float = 0.0  # Track last time we logged for throttling (DebugLogOverlay)
var last_sun_log_time: float = 0.0  # Track last time we logged sun/lighting data for throttling

# Scene references
var directional_light: DirectionalLight3D
var world_environment: WorldEnvironment
var ui_manager: Node
var player: Node3D
var moon: Node3D
var sun: Node3D
var stars: Node3D
#endregion

#region ===== LIFECYCLE & INITIALIZATION =====
func _ready() -> void:
    # Add to DayNightCycle group so other systems can find this node
    add_to_group("DayNightCycle")
    
    # Find references
    directional_light = get_tree().get_first_node_in_group("DirectionalLight3D")
    if not directional_light:
        directional_light = get_parent().get_node_or_null("DirectionalLight3D")
        if not directional_light:
            push_warning("DayNightCycle: DirectionalLight3D not found - sun movement will not work")
    
    world_environment = get_tree().get_first_node_in_group("WorldEnvironment")
    if not world_environment:
        world_environment = get_parent().get_node_or_null("WorldEnvironment")
        if not world_environment:
            push_warning("DayNightCycle: WorldEnvironment not found - ambient lighting changes will not work")
    
    player = get_tree().get_first_node_in_group("Player")
    if not player:
        player = get_parent().get_node_or_null("Player")
        if not player:
            push_warning("DayNightCycle: Player not found - input control will not work")
    
    ui_manager = get_parent().get_node_or_null("UIManager")
    if not ui_manager:
        push_warning("DayNightCycle: UIManager not found - messages and night overlay will not work")
    
    # Create celestial objects
    _create_sun()
    _create_moon()
    _create_stars()
    
    # Load saved state
    _load_state()
    
    # Notify UI of loaded time scale
    _notify_time_scale_changed()
    
    # Log initial environment state for debugging
    _log_environment_state("GAME_START")
    
    # Check if we need to show sunrise animation
    if is_locked_out:
        DebugLogOverlay.add_log("=== DayNightCycle: Player is locked out ===", "yellow")
        var current_unix_time = Time.get_unix_time_from_system()
        DebugLogOverlay.add_log("Current unix time: %.2f" % current_unix_time, "yellow")
        DebugLogOverlay.add_log("Lockout end time: %.2f" % lockout_end_time, "yellow")
        DebugLogOverlay.add_log("Time remaining: %.2f sec" % (lockout_end_time - current_unix_time), "yellow")
        
        # Log sleep state details
        var log_msg = LogExportManager.format_sleep_state_log(
            "READY_LOCKED_OUT",
            is_locked_out,
            lockout_end_time,
            current_time,
            day_count,
            night_start_time
        )
        LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
        
        if debug_skip_lockout or current_unix_time >= lockout_end_time:
            # Lockout expired: start new day with sunrise animation and increment day counter
            DebugLogOverlay.add_log("Lockout expired, starting new day", "green")
            is_locked_out = false
            is_animating_sunrise = true
            sunrise_animation_time = 0.0
            current_time = 0.0  # Start of new day
            day_count += 1
            _disable_player_input()
            _hide_night_screen()  # Hide night overlay since lockout has expired
            _show_day_message()
            
            # Log state change
            log_msg = LogExportManager.format_sleep_state_log(
                "LOCKOUT_EXPIRED",
                is_locked_out,
                lockout_end_time,
                current_time,
                day_count,
                night_start_time
            )
            LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
        else:
            # Still in lockout, show night screen
            DebugLogOverlay.add_log("Still locked out, showing night screen", "yellow")
            is_night = true
            _show_night_screen()
            _set_night_lighting()
    else:
        # Normal day start
        DebugLogOverlay.add_log("=== DayNightCycle: Normal day start ===", "green")
        DebugLogOverlay.add_log("Starting current_time: %.2f" % current_time, "green")
        
        # Log normal day start state
        var log_msg = LogExportManager.format_sleep_state_log(
            "NORMAL_DAY_START",
            is_locked_out,
            lockout_end_time,
            current_time,
            day_count,
            night_start_time
        )
        LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
        
        _update_lighting()

func _process(delta) -> void:
    # Apply debug time multiplier and time scale
    var time_delta = delta
    if debug_mode:
        time_delta *= 60.0  # 60x faster for testing
    else:
        time_delta *= time_scale  # Apply user-controlled time scale
    
    # Handle lockout check
    if is_locked_out and not is_night:
        var current_unix_time = Time.get_unix_time_from_system()
        # Validate time makes sense (not in the past relative to lockout start)
        # Also skip lockout if debug mode is enabled
        if debug_skip_lockout or current_unix_time >= lockout_end_time:
            # Lockout expired: start new day with sunrise animation and increment day counter
            is_locked_out = false
            is_animating_sunrise = true
            sunrise_animation_time = 0.0
            current_time = 0.0
            day_count += 1
            _disable_player_input()
            _hide_night_screen()
            _show_day_message()
        elif current_unix_time < lockout_end_time - SLEEP_LOCKOUT_DURATION:
            # System time appears to have been set backwards significantly
            # Reset to reasonable lockout end time (4 hours from now)
            push_warning("DayNightCycle: System time appears invalid, resetting lockout period")
            lockout_end_time = current_unix_time + SLEEP_LOCKOUT_DURATION
            _save_state()
            if ui_manager and ui_manager.has_method("show_night_overlay"):
                ui_manager.show_night_overlay(lockout_end_time)
        return
    
    # Handle sunrise animation
    if is_animating_sunrise:
        sunrise_animation_time += time_delta
        var progress = sunrise_animation_time / SUNRISE_DURATION
        
        if progress >= 1.0:
            # Sunrise complete
            is_animating_sunrise = false
            sunrise_animation_time = 0.0
            
            # Log completing sunrise
            _log_environment_state("SUNRISE_COMPLETE")
            
            _enable_player_input()
        else:
            _animate_sunrise(progress)
        return
    
    # Handle sunset animation
    if is_animating_sunset:
        sunset_animation_time += time_delta
        var progress = sunset_animation_time / SUNSET_DURATION
        
        if progress >= 1.0:
            # Sunset complete, enter night
            is_animating_sunset = false
            sunset_animation_time = 0.0
            is_night = true
            is_locked_out = true
            night_start_time = Time.get_unix_time_from_system()  # Record when night began
            lockout_end_time = night_start_time + SLEEP_LOCKOUT_DURATION
            
            # Log entering night/sleep mode
            _log_environment_state("ENTERING_NIGHT")
            var log_msg = LogExportManager.format_sleep_state_log(
                "ENTERING_SLEEP_MODE",
                is_locked_out,
                lockout_end_time,
                current_time,
                day_count,
                night_start_time
            )
            LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
            
            _save_state()
            _save_game_state()  # Save game state when bedtime starts
            if ui_manager and ui_manager.has_method("show_message"):
                ui_manager.show_message("Game auto-saved for the night", 3.0)
            _show_night_screen()
            _set_night_lighting()
            _disable_player_input()
        else:
            _animate_sunset(progress)
        return
    
    # Normal day progression
    if not is_night:
        current_time += time_delta
        
        # Check for warnings
        var time_until_sunset = DAY_CYCLE_DURATION - current_time
        
        if time_until_sunset <= WARNING_TIME_2MIN and not warning_2min_shown:
            warning_2min_shown = true
            _show_warning("2 minutes until sunset! Find a place to sleep.")
        
        if time_until_sunset <= WARNING_TIME_1MIN and not warning_1min_shown:
            warning_1min_shown = true
            _show_warning("1 minute until sunset! Find a place to sleep NOW!")
        
        # Check if sunset should start
        if current_time >= DAY_CYCLE_DURATION:
            is_animating_sunset = true
            sunset_animation_time = 0.0
            warning_2min_shown = false
            warning_1min_shown = false
        else:
            _update_lighting()
#endregion

#region ===== BRIGHTNESS & LIGHTING SYSTEM =====
# These functions control the brightness throughout the day cycle.
# The brightness follows a quadratic curve:
#   - Darkest at sunrise (7:00 AM, 0°) and sunset (5:00 PM, 180°): MIN_LIGHT_ENERGY = 1.2
#   - Brightest at noon (12:00 PM, 90°): MAX_LIGHT_ENERGY = 3.0
#   - Formula: intensity = lerp(MIN, MAX, 1.0 - (distance_from_noon)²)

func _update_lighting() -> void:
    if not directional_light:
        return
    
    # Update UI time display (includes sun offset for display)
    if ui_manager and ui_manager.has_method("update_game_time"):
        # Only log every 5 seconds to avoid spam
        if current_time - last_log_time >= 5.0:
            DebugLogOverlay.add_log("update_game_time called: current_time=%.2f, cycle_duration=%.2f, offset=%.2f" % [current_time, DAY_CYCLE_DURATION, sun_time_offset_hours], "white")
            last_log_time = current_time
        ui_manager.update_game_time(current_time, DAY_CYCLE_DURATION, sun_time_offset_hours)
    
    # Update UI sun position display
    if ui_manager and ui_manager.has_method("update_sun_position"):
        ui_manager.update_sun_position(get_sun_position_degrees())
    
    # Calculate sun angle based on current time
    # Use the display angle which accounts for INITIAL_TIME_OFFSET_HOURS
    var display_angle = get_sun_position_degrees()
    
    # Handle special cases (night, sunrise, sunset animations handled separately)
    if display_angle < 0:
        # Night time - lighting handled by _set_night_lighting()
        return
    
    # Convert display angle to light rotation
    # Limited to ±50° to ensure light always reaches ground effectively
    # 0° (sunrise) -> +50° rotation (light from east, 64% effective)
    # 90° (noon) -> 0° rotation (light from overhead, 100% effective)
    # 180° (sunset) -> -50° rotation (light from west, 64% effective)
    # This fixes the issue where horizontal light (±90°) didn't illuminate the ground
    var light_rotation = lerp(MAX_LIGHT_ANGLE, -MAX_LIGHT_ANGLE, display_angle / 180.0)
    
    # Apply rotation to directional light
    # Rotate around X axis for sun elevation
    directional_light.rotation_degrees.x = light_rotation
    
    # Adjust light intensity based on sun position
    # Brightest at noon (90°), dimmer at sunrise (0°) and sunset (180°)
    var noon_distance = abs(display_angle - 90.0) / 90.0  # 0 at noon, 1 at sunrise/sunset
    # Use quadratic curve for more realistic atmospheric brightness
    # This creates faster brightening in early morning and slower changes near noon
    var intensity_curve = 1.0 - (noon_distance * noon_distance)  # Quadratic: 1 at noon, 0 at edges
    directional_light.light_energy = lerp(MIN_LIGHT_ENERGY, MAX_LIGHT_ENERGY, intensity_curve)
    
    # Keep ambient light color white when using Sky as ambient source
    # This allows the PhysicalSkyMaterial's natural blue color to show through
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        # When using Sky (ambient_light_source = 3), keep color white to avoid tinting the blue sky
        if env.ambient_light_source == Environment.AMBIENT_SOURCE_SKY:
            env.ambient_light_color = Color(1.0, 1.0, 1.0)
        else:
            # Fallback for other ambient light sources (e.g., Color mode)
            var color_warmth = lerp(0.2, 0.0, intensity_curve)  # More orange at sunrise/sunset
            env.ambient_light_color = Color(1.0, 1.0 - color_warmth, 1.0 - color_warmth * 1.5)
    
    # Log sun degree and lighting data for debugging lighting issues
    # NOTE: This must be after ambient color is set to log the actual brightness values
    # Log more frequently to capture all states, not just when sun > 80°
    # Throttle to every 10 seconds to avoid spam but still capture enough data
    var should_log = (current_time - last_sun_log_time >= 10.0) or display_angle > 80.0
    if should_log:
        var ambient_brightness = _calculate_ambient_brightness()
        # Total brightness is a simplified debugging metric combining directional + ambient
        var total_brightness = directional_light.light_energy + ambient_brightness
        
        var log_msg = "Sun Position: %.2f° | Light Rotation: %.2f° | Light Energy: %.2f | Ambient: %.2f | Total Brightness: %.2f | Time: %.2f/%.2f" % [
            display_angle, light_rotation, directional_light.light_energy, ambient_brightness, total_brightness, current_time, DAY_CYCLE_DURATION
        ]
        LogExportManager.add_log(LogExportManager.LogType.SUN_LIGHTING_ISSUE, log_msg)
        last_sun_log_time = current_time  # Update throttle timer
    
    # Update moon position
    _update_moon_position()
    
    # Update sun position
    _update_sun_position()
    
    # Update stars visibility
    _update_stars_visibility()

# Calculate perceived brightness from ambient light color using standard luminance formula
# Note: This is a simplified metric for debugging/logging purposes that combines
# ambient color luminance with the ambient energy multiplier
func _calculate_ambient_brightness() -> float:
    if world_environment and world_environment.environment:
        var ambient_color = world_environment.environment.ambient_light_color
        # Calculate perceived luminance from RGB (using standard formula)
        var color_luminance = 0.299 * ambient_color.r + 0.587 * ambient_color.g + 0.114 * ambient_color.b
        # Multiply by ambient energy to get actual brightness contribution
        return color_luminance * world_environment.environment.ambient_light_energy
    return 0.0
#endregion

#region ===== SUNRISE & SUNSET TRANSITIONS =====
# These functions manage the sunrise (7:00 AM) and sunset (5:00 PM) animations.
# Each transition takes 60 seconds and smoothly animates:
#   - Light rotation (sun moving from/to below horizon)
#   - Light intensity (fading in/out)
#   - Ambient colors (warm colors at transitions)
#   - Celestial object visibility (sun/moon/stars)

func _animate_sunrise(progress: float) -> void:
    if not directional_light:
        return
    
    # Animate from night (below horizon) to day (at horizon, 0°)
    # During sunrise, sun goes from below horizon to 0° display angle
    # Light rotation: from below horizon (+70°) to sunrise position (+50°)
    # Using MAX_LIGHT_ANGLE ensures consistent lighting with daytime calculations
    var light_rotation = lerp(70.0, MAX_LIGHT_ANGLE, progress)
    directional_light.rotation_degrees.x = light_rotation
    
    # Fade in light to match the start-of-day intensity
    directional_light.light_energy = lerp(0.0, MIN_LIGHT_ENERGY, progress)
    
    # Keep sky blue during sunrise when using Sky as ambient source
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        if env.ambient_light_source == Environment.AMBIENT_SOURCE_SKY:
            env.ambient_light_color = Color(1.0, 1.0, 1.0)
        else:
            # Fallback for other ambient light sources
            var warmth = lerp(0.4, 0.2, progress)  # End with same warmth as day start
            env.ambient_light_color = Color(1.0, 1.0 - warmth, 1.0 - warmth * 1.5)
    
    # Log sunrise animation for debugging
    # NOTE: This must be after ambient color is set to log the actual brightness values
    var sun_position_deg = get_sun_position_degrees()
    var ambient_brightness = _calculate_ambient_brightness()
    # Total brightness is a simplified debugging metric combining directional + ambient
    var total_brightness = directional_light.light_energy + ambient_brightness
    
    var log_msg = "SUNRISE - Progress: %.2f | Sun Position: %.2f° | Light Rotation: %.2f° | Light Energy: %.2f | Ambient: %.2f | Total Brightness: %.2f" % [
        progress, sun_position_deg, light_rotation, directional_light.light_energy, ambient_brightness, total_brightness
    ]
    LogExportManager.add_log(LogExportManager.LogType.SUN_LIGHTING_ISSUE, log_msg)
    
    # Update moon (it should be setting during sunrise)
    _update_moon_position()
    
    # Update sun (it should be rising during sunrise)
    _update_sun_position()
    
    # Update stars (they should be fading out during sunrise)
    _update_stars_visibility()
    
    # Update UI sun position display
    if ui_manager and ui_manager.has_method("update_sun_position"):
        ui_manager.update_sun_position(get_sun_position_degrees())

func _animate_sunset(progress: float) -> void:
    if not directional_light:
        return
    
    # Animate from day to night (sun going below horizon)
    # During sunset, sun goes from 180° display angle to below horizon
    # Light rotation: from sunset position (-50°) to below horizon (-70°)
    # Using -MAX_LIGHT_ANGLE ensures consistent lighting with daytime calculations
    var light_rotation = lerp(-MAX_LIGHT_ANGLE, -70.0, progress)
    directional_light.rotation_degrees.x = light_rotation
    
    # Fade out light from end-of-day intensity to darkness
    directional_light.light_energy = lerp(MIN_LIGHT_ENERGY, 0.0, progress)
    
    # Keep sky blue during sunset when using Sky as ambient source
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        if env.ambient_light_source == Environment.AMBIENT_SOURCE_SKY:
            env.ambient_light_color = Color(1.0, 1.0, 1.0)
        else:
            # Fallback for other ambient light sources
            var warmth = lerp(0.2, 0.5, progress * SUNSET_WARMTH_FACTOR)  # Start from day-end warmth
            env.ambient_light_color = Color(1.0, 1.0 - warmth, 1.0 - warmth * SUNSET_COLOR_INTENSITY)
    
    # Log sunset animation for debugging
    # NOTE: This must be after ambient color is set to log the actual brightness values
    var sun_position_deg = get_sun_position_degrees()
    var ambient_brightness = _calculate_ambient_brightness()
    # Total brightness is a simplified debugging metric combining directional + ambient
    var total_brightness = directional_light.light_energy + ambient_brightness
    
    var log_msg = "SUNSET - Progress: %.2f | Sun Position: %.2f° | Light Rotation: %.2f° | Light Energy: %.2f | Ambient: %.2f | Total Brightness: %.2f" % [
        progress, sun_position_deg, light_rotation, directional_light.light_energy, ambient_brightness, total_brightness
    ]
    LogExportManager.add_log(LogExportManager.LogType.SUN_LIGHTING_ISSUE, log_msg)
    
    # Update moon (it should be rising during sunset)
    _update_moon_position()
    
    # Update sun (it should be setting during sunset)
    _update_sun_position()
    
    # Update stars (they should be appearing during sunset)
    _update_stars_visibility()
    
    # Update UI sun position display
    if ui_manager and ui_manager.has_method("update_sun_position"):
        ui_manager.update_sun_position(get_sun_position_degrees())

# Set lighting for night period (complete darkness with moon and stars).
func _set_night_lighting() -> void:
    if not directional_light:
        return
    
    # Set sun below horizon (below -90° or above +90°)
    directional_light.rotation_degrees.x = 120.0  # Below horizon on the east side
    directional_light.light_energy = 0.0
    
    # Dark blue ambient light for night
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.ambient_light_color = Color(0.1, 0.1, 0.2)
    
    # Show moon during night
    if moon:
        moon.visible = true
        # Position moon at zenith during night
        moon.position = Vector3(0, MOON_ZENITH_HEIGHT, 0)
    
    # Hide sun during night
    if sun:
        sun.visible = false
    
    # Show stars during night
    if stars:
        stars.visible = true
    
    # Update UI sun position display (sun not visible during night)
    if ui_manager and ui_manager.has_method("update_sun_position"):
        ui_manager.update_sun_position(get_sun_position_degrees())
#endregion

#region ===== UI & USER NOTIFICATIONS =====
func _show_warning(message: String) -> void:
    if ui_manager and ui_manager.has_method("show_message"):
        ui_manager.show_message(message, 5.0)

func _show_day_message() -> void:
    if ui_manager and ui_manager.has_method("show_message"):
        ui_manager.show_message("Day %d - Game loaded!" % day_count, 5.0)

func _show_night_screen() -> void:
    DebugLogOverlay.add_log("=== Showing night screen ===", "magenta")
    DebugLogOverlay.add_log("lockout_end_time: %.2f" % lockout_end_time, "magenta")
    if ui_manager and ui_manager.has_method("show_night_overlay"):
        DebugLogOverlay.add_log("Calling ui_manager.show_night_overlay", "magenta")
        ui_manager.show_night_overlay(lockout_end_time)
    else:
        DebugLogOverlay.add_log("ERROR: ui_manager not found or no show_night_overlay method!", "red")

func _hide_night_screen() -> void:
    if ui_manager and ui_manager.has_method("hide_night_overlay"):
        ui_manager.hide_night_overlay()

func _disable_player_input() -> void:
    if player and player.has_method("set_input_enabled"):
        player.set_input_enabled(false)

func _enable_player_input() -> void:
    if player and player.has_method("set_input_enabled"):
        player.set_input_enabled(true)
#endregion

#region ===== STATE MANAGEMENT & SAVE/LOAD =====
func _save_state() -> void:
    var config = ConfigFile.new()
    config.set_value("day_night", "is_locked_out", is_locked_out)
    config.set_value("day_night", "lockout_end_time", lockout_end_time)
    config.set_value("day_night", "current_time", current_time)
    config.set_value("day_night", "time_scale", time_scale)
    
    var error = config.save(SAVE_FILE_PATH)
    if error != OK:
        push_warning("Failed to save day/night state: " + str(error))

func _load_state() -> void:
    DebugLogOverlay.add_log("=== DayNightCycle: Loading State ===", "yellow")
    
    # Get day/night state from SaveGameManager (already loaded at startup)
    var loaded_from_manager = false
    if SaveGameManager.has_save_file() and SaveGameManager._data_loaded:
        print("DayNightCycle: Loading from SaveGameManager")
        DebugLogOverlay.add_log("DayNightCycle: Loading from SaveGameManager", "cyan")
        var day_night_data = SaveGameManager.get_day_night_data()
        is_locked_out = day_night_data.get("is_locked_out", false)
        lockout_end_time = day_night_data.get("lockout_end_time", 0.0)
        current_time = day_night_data.get("current_time", 0.0)
        # Load time_scale if available (with default of 2.0 for old saves to match fresh start)
        time_scale = day_night_data.get("time_scale", 2.0)
        # Load day count and night start time (defaults for old saves)
        day_count = day_night_data.get("day_count", 1)
        night_start_time = day_night_data.get("night_start_time", 0.0)
        loaded_from_manager = true
        print("DayNightCycle: Loaded state from SaveGameManager")
        DebugLogOverlay.add_log("Loaded: is_locked_out=%s, current_time=%.2f" % [is_locked_out, current_time], "cyan")
        DebugLogOverlay.add_log("Loaded: lockout_end_time=%.2f, time_scale=%.2f" % [lockout_end_time, time_scale], "cyan")
        
        # Log sleep state for debugging problematic state after load
        var log_msg = LogExportManager.format_sleep_state_log(
            "DayNightCycle LOAD",
            is_locked_out,
            lockout_end_time,
            current_time,
            day_count,
            night_start_time
        )
        LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
    
    # Fall back to legacy save file if SaveGameManager didn't have data
    if not loaded_from_manager:
        print("DayNightCycle: Trying to load from legacy file")
        DebugLogOverlay.add_log("DayNightCycle: Trying legacy file", "cyan")
        var config = ConfigFile.new()
        var error = config.load(SAVE_FILE_PATH)
        
        if error == OK:
            print("DayNightCycle: Legacy file loaded successfully")
            DebugLogOverlay.add_log("DayNightCycle: Legacy file loaded", "cyan")
            is_locked_out = config.get_value("day_night", "is_locked_out", false)
            lockout_end_time = config.get_value("day_night", "lockout_end_time", 0.0)
            current_time = config.get_value("day_night", "current_time", 0.0)
            time_scale = config.get_value("day_night", "time_scale", 2.0)  # Default 2.0 for old saves
            day_count = config.get_value("day_night", "day_count", 1)
            night_start_time = config.get_value("day_night", "night_start_time", 0.0)
            print("DayNightCycle: current_time from legacy file: ", current_time)
            DebugLogOverlay.add_log("Legacy: current_time=%.2f" % current_time, "cyan")
        else:
            # No save file or error loading, use defaults for first start
            print("DayNightCycle: No save file, using fresh start defaults")
            DebugLogOverlay.add_log("DayNightCycle: Fresh start, no save file", "green")
            is_locked_out = false
            lockout_end_time = 0.0
            # Start at sunrise (INITIAL_TIME_OFFSET_HOURS = 0.0)
            # Display will show 7:00 AM and sun will be at sunrise position
            current_time = DAY_CYCLE_DURATION * (INITIAL_TIME_OFFSET_HOURS / DAY_DURATION_HOURS)
            time_scale = 2.0  # Start with double speed time progression
            print("DayNightCycle: Set current_time to: ", current_time)
            DebugLogOverlay.add_log("Fresh: current_time=%.2f" % current_time, "green")
    
    # Initialize last_log_time to avoid immediate logging on first frame
    last_log_time = current_time
#endregion

#region ===== SUN POSITION CALCULATION =====
# Get sun position in 0-180 degree range for display.
# This is the core function that determines where the sun appears in the sky:
#   - 0° = Sunrise (7:00 AM) - Sun at eastern horizon
#   - 90° = Noon (12:00 PM) - Sun at zenith (highest point)
#   - 180° = Sunset (5:00 PM) - Sun at western horizon
#   - -1 = Night (not visible)
#
# The sun position drives:
#   - Light rotation (90° - sun_position for directional light)
#   - Brightness calculation (quadratic curve based on distance from 90°)
#   - UI display (shown to player as game time)

func get_sun_position_degrees() -> float:
    # During night, return -1 to indicate sun is not visible
    if is_night and not is_animating_sunrise:
        return -1.0
    
    # Calculate time ratio (0.0 = game start, 0.5 = noon, 1.0 = sunset)
    var time_ratio: float = 0.0
    
    if is_animating_sunrise:
        # During sunrise animation, sun position stays at 0° (horizon)
        # The day cycle (0° to 180°) starts after sunrise completes
        time_ratio = 0.0  # Stays at 0° during sunrise, then day starts
    elif is_animating_sunset:
        # During sunset animation, sun position stays at 180° (horizon)
        # After sunset completes, night begins
        time_ratio = 1.0  # At end of day (180°) during sunset
    else:
        # Normal day progression
        # Account for INITIAL_TIME_OFFSET_HOURS so that game start shows as 0°
        # The initial offset makes the sun start higher for better brightness,
        # but we want the display to show 0° at game start for intuitive UX
        var initial_offset_time = DAY_CYCLE_DURATION * (INITIAL_TIME_OFFSET_HOURS / DAY_DURATION_HOURS)
        var remaining_day_duration = DAY_CYCLE_DURATION - initial_offset_time
        
        # Prevent division by zero if offset equals full day duration
        if remaining_day_duration > 0.0:
            time_ratio = (current_time - initial_offset_time) / remaining_day_duration
        else:
            # Edge case: if offset >= day duration, just show end of day
            time_ratio = 1.0
        
        # Clamp to 0.0-1.0 range to handle edge cases
        # (e.g., current_time < initial_offset_time would give negative ratio, clamped to 0.0)
        time_ratio = clamp(time_ratio, 0.0, 1.0)
    
    # Map 0.0-1.0 ratio to 0-180 degrees
    # 0.0 (game start) -> 0°, 0.5 (midpoint of playable day) -> 90°, 1.0 (sunset) -> 180°
    return time_ratio * 180.0
#endregion

#region ===== CELESTIAL OBJECTS (SUN, MOON, STARS) =====
# These functions create and manage the visual celestial objects in the sky.
# The sun, moon, and stars are created as 3D meshes with emission materials.
# Their visibility and position changes based on the time of day.

# Create a moon that appears during night.
func _create_moon() -> void:
    # Don't create moon in headless mode (e.g., during tests or script validation)
    if DisplayServer.get_name() == "headless":
        return
    
    moon = Node3D.new()
    moon.name = "Moon"
    add_child(moon)
    
    # Create mesh instance for moon
    var mesh_instance = MeshInstance3D.new()
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = 50.0  # Large moon
    sphere_mesh.height = 100.0
    mesh_instance.mesh = sphere_mesh
    
    # Create moon material with emission
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.9, 0.9, 0.85)  # Slightly yellowish white
    material.emission_enabled = true
    material.emission = Color(0.8, 0.8, 0.7)  # Soft glow
    material.emission_energy_multiplier = 0.5
    mesh_instance.material_override = material
    
    moon.add_child(mesh_instance)
    moon.visible = false  # Start hidden

# Update moon position based on time of day.
func _update_moon_position() -> void:
    if not moon:
        return
    
    # During night or when sun is not visible, position moon at zenith
    if is_night:
        moon.visible = true
        moon.position = Vector3(0, MOON_ZENITH_HEIGHT, 0)
        return
    
    # Get sun display angle and moon moves opposite (180 degrees offset)
    var sun_display_angle = get_sun_position_degrees()
    
    # If sun is not visible (returns -1), position moon at zenith
    if sun_display_angle < 0:
        moon.visible = true
        moon.position = Vector3(0, MOON_ZENITH_HEIGHT, 0)
        return
    
    # Moon is on opposite side of sky from sun (180° offset)
    var moon_angle = sun_display_angle + 180.0
    
    # Normalize angle to -180° to +180° range for positioning
    # Since sun_display_angle is 0-180°, moon_angle is 180-360°
    # Subtract 360° to get -180° to 0° range (e.g., 270° -> -90°, 360° -> 0°)
    if moon_angle > 180.0:
        moon_angle -= 360.0
    
    # Position moon using its angle (same as sun positioning logic)
    var angle_rad = deg_to_rad(moon_angle)
    
    # Calculate position on arc
    moon.position.x = 0
    moon.position.y = sin(angle_rad) * CELESTIAL_DISTANCE
    moon.position.z = -cos(angle_rad) * CELESTIAL_DISTANCE
    
    # Show/hide moon based on whether it's above horizon
    # Moon is visible when it's above the horizon (y > 0)
    moon.visible = moon.position.y > 0

# Create a visible sun that moves across the sky.
func _create_sun() -> void:
    # Don't create sun in headless mode (e.g., during tests or script validation)
    if DisplayServer.get_name() == "headless":
        return
    
    sun = Node3D.new()
    sun.name = "Sun"
    add_child(sun)
    
    # Create mesh instance for sun
    var mesh_instance = MeshInstance3D.new()
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = 80.0  # Large sun
    sphere_mesh.height = 160.0
    mesh_instance.mesh = sphere_mesh
    
    # Create sun material with bright emission
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.95, 0.7)  # Warm yellow
    material.emission_enabled = true
    material.emission = Color(1.0, 0.9, 0.6)  # Bright warm glow
    material.emission_energy_multiplier = 2.0  # Very bright
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Always bright
    mesh_instance.material_override = material
    
    sun.add_child(mesh_instance)
    sun.visible = true  # Start visible

# Update sun position based on time of day.
func _update_sun_position():
    if not sun:
        return
    
    # Get display angle (0-180°) for visual positioning
    var display_angle = get_sun_position_degrees()
    
    # Handle night time (display_angle returns -1)
    if display_angle < 0:
        sun.visible = false
        return
    
    # Position sun in sky using display angle
    # 0° = horizon (sunrise), 90° = zenith (noon), 180° = horizon (sunset)
    # Convert to elevation angle for positioning
    var elevation_angle = display_angle
    var angle_rad = deg_to_rad(elevation_angle)
    
    # Calculate position on arc
    sun.position.x = 0
    sun.position.y = sin(angle_rad) * CELESTIAL_DISTANCE
    sun.position.z = -cos(angle_rad) * CELESTIAL_DISTANCE
    
    # Show/hide sun based on whether it's above horizon
    # Sun is visible when it's above the horizon (y > 0)
    sun.visible = sun.position.y > 0

# Create stars that appear during night.
func _create_stars():
    # Don't create stars in headless mode (e.g., during tests or script validation)
    if DisplayServer.get_name() == "headless":
        return
    
    stars = Node3D.new()
    stars.name = "Stars"
    add_child(stars)
    
    # Create multiple small stars at random positions in the night sky
    var star_count = 100
    
    for i in range(star_count):
        # Create star mesh
        var star_mesh_instance = MeshInstance3D.new()
        var star_sphere = SphereMesh.new()
        star_sphere.radius = randf_range(2.0, 5.0)  # Small stars with some variation
        star_sphere.height = star_sphere.radius * 2.0
        star_mesh_instance.mesh = star_sphere
        
        # Create star material with emission
        var star_material = StandardMaterial3D.new()
        var brightness = randf_range(0.7, 1.0)  # Vary brightness
        star_material.albedo_color = Color(brightness, brightness, brightness)
        star_material.emission_enabled = true
        star_material.emission = Color(brightness, brightness, brightness)
        star_material.emission_energy_multiplier = randf_range(0.5, 1.5)
        star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        star_mesh_instance.material_override = star_material
        
        # Random position in upper hemisphere (only visible at night)
        # Use spherical coordinates for even distribution
        var theta = randf() * TAU  # Azimuth angle (0 to 2π)
        var phi = randf_range(0, PI * 0.4)  # Elevation angle (0 to ~70° from zenith, avoiding horizon)
        
        var x = STAR_DISTANCE * sin(phi) * cos(theta)
        var y = STAR_DISTANCE * cos(phi)  # Height (positive = up)
        var z = STAR_DISTANCE * sin(phi) * sin(theta)
        
        star_mesh_instance.position = Vector3(x, y, z)
        stars.add_child(star_mesh_instance)
    
    stars.visible = false  # Start hidden

# Update stars visibility based on time of day.
func _update_stars_visibility():
    if not stars:
        return
    
    # Stars are visible at night and during sunset/sunrise transitions
    if is_night or is_animating_sunset or is_animating_sunrise:
        stars.visible = true
    else:
        stars.visible = false
#endregion

#region ===== DEBUGGING & LOGGING =====
# Log comprehensive environment state for debugging
func _log_environment_state(context: String) -> void:
    var sun_pos = get_sun_position_degrees()
    var ambient_brightness = _calculate_ambient_brightness()
    var light_energy = directional_light.light_energy if directional_light else 0.0
    var total_brightness = light_energy + ambient_brightness
    
    # Log sun/lighting state
    var sun_log = "%s | Sun: %.2f° | Light Energy: %.2f | Ambient: %.2f | Total: %.2f | Time: %.2f/%.2f | Day: %d" % [
        context,
        sun_pos,
        light_energy,
        ambient_brightness,
        total_brightness,
        current_time,
        DAY_CYCLE_DURATION,
        day_count
    ]
    LogExportManager.add_log(LogExportManager.LogType.SUN_LIGHTING_ISSUE, sun_log)
    
    # Log additional environment details
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        var env_log = "%s | Ambient Source: %d | Ambient Energy: %.2f | Sky Enabled: %s" % [
            context,
            env.ambient_light_source,
            env.ambient_light_energy,
            str(env.background_mode == Environment.BG_SKY)
        ]
        LogExportManager.add_log(LogExportManager.LogType.SUN_LIGHTING_ISSUE, env_log)
    
    # Log animation states
    var state_log = "%s | Night: %s | Sunrise Anim: %s | Sunset Anim: %s | Locked: %s" % [
        context,
        str(is_night),
        str(is_animating_sunrise),
        str(is_animating_sunset),
        str(is_locked_out)
    ]
    LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, state_log)

func _notification(what: int) -> void:
    # Handle app lifecycle events for debugging sleep/resume issues
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            # App is being paused (going to background on mobile)
            var log_msg = "APP_PAUSED | Time: %.2f | Night: %s | Locked: %s" % [
                current_time, str(is_night), str(is_locked_out)
            ]
            LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
            _log_environment_state("APP_PAUSED")
        
        NOTIFICATION_APPLICATION_RESUMED:
            # App is being resumed (coming back from background on mobile)
            var current_unix_time = Time.get_unix_time_from_system()
            var log_msg = LogExportManager.format_sleep_state_log(
                "APP_RESUMED",
                is_locked_out,
                lockout_end_time,
                current_time,
                day_count,
                night_start_time
            )
            LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, log_msg)
            _log_environment_state("APP_RESUMED")
            
            # Check if lockout should be ended
            if is_locked_out and current_unix_time >= lockout_end_time:
                var resume_log = "APP_RESUMED: Lockout expired during background, time_diff: %.2f" % (
                    current_unix_time - lockout_end_time
                )
                LogExportManager.add_log(LogExportManager.LogType.SLEEP_STATE_ISSUE, resume_log)
#endregion

#region ===== TIME SCALE CONTROL =====
# Increase time scale (speed up time)
func increase_time_scale() -> void:
    time_scale = min(time_scale * 2.0, 32.0)  # Double the speed, max 32x
    _notify_time_scale_changed()

# Decrease time scale (slow down time)
func decrease_time_scale() -> void:
    time_scale = max(time_scale / 2.0, 0.25)  # Half the speed, min 0.25x
    _notify_time_scale_changed()

# Notify UI of time scale change
func _notify_time_scale_changed():
    if ui_manager and ui_manager.has_method("update_time_scale"):
        ui_manager.update_time_scale(time_scale)
#endregion

#region ===== GAME STATE INTEGRATION =====
func _save_game_state():
    # Save the game state when bedtime/pause starts
    var player = get_tree().get_first_node_in_group("Player")
    var world_manager = get_tree().get_first_node_in_group("WorldManager")
    var pause_menu = get_tree().get_first_node_in_group("PauseMenu")
    var ruler = get_tree().get_first_node_in_group("RulerOverlay")
    
    if player:
        var inventory = player.crystal_inventory if "crystal_inventory" in player else {}
        SaveGameManager.update_player_data(
            player.global_position,
            player.rotation.y,
            player.is_first_person if "is_first_person" in player else false,
            inventory
        )
    
    if world_manager:
        SaveGameManager.update_world_data(
            world_manager.WORLD_SEED,
            world_manager.player_chunk
        )
    
    # Update day/night data
    SaveGameManager.update_day_night_data(
        current_time,
        is_locked_out,
        lockout_end_time,
        time_scale,
        day_count,
        night_start_time
    )
    
    # Save settings (volume and ruler visibility)
    # Get master volume from audio bus (the source of truth)
    var bus_index = AudioServer.get_bus_index("Master")
    var db_volume = AudioServer.get_bus_volume_db(bus_index)
    var master_volume = db_to_linear(db_volume) * 100.0
    
    # Get ruler visibility
    var ruler_visible = true  # Default
    if ruler and ruler.has_method("get_visible_state"):
        ruler_visible = ruler.get_visible_state()
    
    SaveGameManager.update_settings_data(master_volume, ruler_visible)
    
    SaveGameManager.save_game()
#endregion

