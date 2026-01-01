extends Area2D

# Define the next scene to load in the inspector
@export_file("*.tscn") var next_scene_path: String

# Load next level scene when player collide with level finish door.
func _on_body_entered(body):
        if body.is_in_group("Player"):
                var target_scene := next_scene_path

                if next_scene_path == "back":
                        if GameManager.saved_scene_path == "":
                                return
                        GameManager.mark_restore_player_position()
                        target_scene = GameManager.saved_scene_path
                else:
                        var return_position := body.global_position + Vector2(0, 16)
                        GameManager.save_player_state(get_tree().current_scene.scene_file_path, return_position)

                get_tree().call_group("Player", "death_tween") # death_tween is called here just to give the feeling of player entering the door.
                AudioManager.level_complete_sfx.play()
                SceneTransition.load_scene(target_scene)
