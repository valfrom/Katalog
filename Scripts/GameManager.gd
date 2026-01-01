# This script is an autoload, that can be accessed from any other script!

extends Node2D

var score : int = 0
var saved_scene_path: String = ""
var saved_player_position: Vector2 = Vector2.ZERO
var restore_player_position: bool = false

# Adds 1 to score variable
func add_score():
		score += 1

# Loads next level
func load_next_level(next_scene : PackedScene):
		get_tree().change_scene_to_packed(next_scene)

func save_player_state(scene_path: String, player_position: Vector2):
		saved_scene_path = scene_path
		saved_player_position = player_position
		restore_player_position = false

func mark_restore_player_position():
		restore_player_position = true

func consume_restore_flag() -> bool:
		var should_restore := restore_player_position
		restore_player_position = false
		return should_restore
