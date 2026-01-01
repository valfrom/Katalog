extends Area2D

# Define the next scene to load in the inspector
@export_file("*.tscn") var next_scene_path: String
@export var use_hero_select: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _closed: bool = false

func _ready() -> void:
        var should_close := next_scene_path != "back" and GameManager.is_level_discovered(next_scene_path)
        _set_closed_state(should_close)

# Load next level scene when player collide with level finish door.
func _on_body_entered(body):
        if _closed:
                return

        if !body.is_in_group("Player"):
                return

	var target_scene := next_scene_path

        if next_scene_path == "back":
                if GameManager.saved_scene_path == "":
                        return
                var unlocked_hero := GameManager.unlock_random_locked_hero()
                if unlocked_hero != "":
                        GameManager.mark_level_discovered(get_tree().current_scene.scene_file_path)
                GameManager.pending_level_scene = ""
                GameManager.mark_restore_player_position()
                target_scene = GameManager.saved_scene_path

		if unlocked_hero != "":
			GameManager.prepare_hero_unlock(unlocked_hero, target_scene)
			get_tree().call_group("Player", "death_tween")
			AudioManager.level_complete_sfx.play()
			SceneTransition.load_scene(GameManager.HERO_FOUND_SCENE_PATH)
			return
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

func _set_closed_state(closed: bool) -> void:
        _closed = closed
        if sprite:
                var modulate_color := sprite.modulate
                modulate_color.a = 0.5 if closed else 1.0
                sprite.modulate = modulate_color

        monitoring = !closed
        monitorable = !closed

        if collision_shape:
                collision_shape.disabled = closed
