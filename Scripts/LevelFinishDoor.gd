extends Area2D

# Define the next scene to load in the inspector
@export_file("*.tscn") var next_scene_path: String

# Load next level scene when player collide with level finish door.
func _on_body_entered(body):
        if body.is_in_group("Player"):
                get_tree().call_group("Player", "death_tween") # death_tween is called here just to give the feeling of player entering the door.
                AudioManager.level_complete_sfx.play()

                if next_scene_path == "back":
                        if GameManager.previous_scene_path != null:
                                SceneTransition.load_scene(GameManager.previous_scene_path)
                        return

                GameManager.previous_scene_path = get_tree().current_scene.scene_file_path
                GameManager.previous_player_position = body.global_position
                GameManager.has_saved_position = true

                SceneTransition.load_scene(next_scene_path)
