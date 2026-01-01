extends Area2D

# Define the next scene to load in the inspector
@export_file("*.tscn") var next_scene_path: String
@export var use_hero_select: bool = false

# Load next level scene when player collide with level finish door.
func _on_body_entered(body):
		if body.is_in_group("Player"):
								var target_scene := next_scene_path

								if next_scene_path == "back":
												if GameManager.saved_scene_path == "":
																return
												GameManager.unlock_random_locked_hero()
												GameManager.pending_level_scene = ""
												GameManager.mark_restore_player_position()
												target_scene = GameManager.saved_scene_path
								else:
												var return_position = self.global_position + Vector2(0, 45)
												GameManager.save_player_state(get_tree().current_scene.scene_file_path, return_position)

												if use_hero_select:
																GameManager.pending_level_scene = next_scene_path
																get_tree().call_group("Player", "death_tween")
																AudioManager.level_complete_sfx.play()
																SceneTransition.load_scene(GameManager.HERO_SELECT_SCENE_PATH)
																return

								get_tree().call_group("Player", "death_tween") # death_tween is called here just to give the feeling of player entering the door.
								AudioManager.level_complete_sfx.play()
								SceneTransition.load_scene(target_scene)
