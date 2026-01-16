extends Node
class_name NarrativeDemo

# Preload dependencies
const QuestHookSystem = preload("res://scripts/quest_hook_system.gd")
const WorldManager = preload("res://scripts/world_manager.gd")

# Demo script to showcase the narrative marker and quest hook system
# This script demonstrates how to use the system to generate and manage quests

var quest_hook_system
var world_manager
var player: Node3D

# Demo state
var demo_active: bool = false
var current_demo_quest: Dictionary = {}
var check_timer: Timer

func _ready() -> void:
    # Find required nodes using current scene as root
    var root = get_tree().current_scene
    if not root:
        # Fallback to traditional method
        root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
    
    quest_hook_system = root.get_node_or_null("QuestHookSystem")
    world_manager = root.get_node_or_null("WorldManager")
    player = root.get_node_or_null("Player")
    
    if not quest_hook_system or not world_manager:
        print("NarrativeDemo: Required nodes not found")
        return
    
    # Setup timer to periodically check for quest completion
    check_timer = Timer.new()
    check_timer.wait_time = 2.0
    check_timer.timeout.connect(_check_quest_progress)
    add_child(check_timer)
    
    # Wait a bit for chunks to generate before starting demo
    await get_tree().create_timer(2.0).timeout
    start_demo()

func start_demo() -> void:
    if demo_active:
        return
    
    print("\n========================================")
    print("NARRATIVE MARKER DEMO MODE ACTIVATED")
    print("========================================\n")
    
    # Enable demo mode in quest hook system
    quest_hook_system.enable_demo_mode()
    demo_active = true
    
    # Print marker summary
    quest_hook_system.print_marker_summary()
    
    # Wait a moment then create demo quest
    await get_tree().create_timer(1.0).timeout
    create_new_demo_quest()
    
    # Start checking quest progress
    check_timer.start()

func create_new_demo_quest() -> void:
    print("\n--- Creating new demo quest ---")
    current_demo_quest = quest_hook_system.create_demo_quest()
    
    if current_demo_quest.is_empty():
        print("Failed to create demo quest - no markers available")
        return
    
    print("\nQuest created successfully!")
    print("Quest ID: %s" % current_demo_quest.id)
    print("Title: %s" % current_demo_quest.title)
    print("Number of objectives: %d\n" % current_demo_quest.objectives.size())

func _check_quest_progress() -> void:
    if current_demo_quest.is_empty():
        return
    
    if not player:
        return
    
    var player_pos = player.global_position
    var current_index = current_demo_quest.current_marker_index
    
    # Check if current objective is completed
    if current_index < current_demo_quest.objectives.size():
        var objective = current_demo_quest.objectives[current_index]
        
        if not objective.completed:
            var distance = player_pos.distance_to(objective.target)
            
            # Consider objective completed if player is within 10 units
            if distance < 10.0:
                objective.completed = true
                current_demo_quest.current_marker_index += 1
                
                print("\n✓ Objective completed: %s" % objective.description)
                print("  Distance traveled: %.1f units" % distance)
                
                # Check if quest is complete
                if current_demo_quest.current_marker_index >= current_demo_quest.objectives.size():
                    complete_quest()
                else:
                    print("\nNext objective: %s" % current_demo_quest.objectives[current_demo_quest.current_marker_index].description)

func complete_quest() -> void:
    print("\n========================================")
    print("QUEST COMPLETED!")
    print("========================================")
    print("Quest: %s" % current_demo_quest.title)
    print("All %d objectives completed!\n" % current_demo_quest.objectives.size())
    
    # Mark quest as completed
    current_demo_quest.status = "completed"
    
    # Wait a bit then create a new quest
    await get_tree().create_timer(3.0).timeout
    create_new_demo_quest()

func get_quest_status() -> String:
    if current_demo_quest.is_empty():
        return "No active quest"
    
    var status_lines = []
    status_lines.append("Quest: %s" % current_demo_quest.title)
    status_lines.append("Progress: %d/%d objectives" % [
        current_demo_quest.current_marker_index,
        current_demo_quest.objectives.size()
    ])
    
    if current_demo_quest.current_marker_index < current_demo_quest.objectives.size():
        var current_obj = current_demo_quest.objectives[current_demo_quest.current_marker_index]
        status_lines.append("Current: %s" % current_obj.description)
        
        if player:
            var distance = player.global_position.distance_to(current_obj.target)
            status_lines.append("Distance: %.1f units" % distance)
    
    return "\n".join(status_lines)
