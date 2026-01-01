extends CharacterBody2D

@export_category("Player Properties")
@export var move_speed: float = 100.0
@export var acceleration: float = 900.0
@export var deceleration: float = 1100.0

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_point: Marker2D = %SpawnPoint
@onready var particle_trails: CPUParticles2D = $ParticleTrails
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var original_scale: Vector2 = self.scale

func _ready() -> void:
		randomize()
		if GameManager.consume_restore_flag():
				global_position = GameManager.saved_player_position
		else:
				global_position = spawn_point.global_position

func _physics_process(delta: float) -> void:
		var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
		var target_velocity := input_dir.normalized() * move_speed
		var accel := acceleration if input_dir != Vector2.ZERO else deceleration
		velocity = velocity.move_toward(target_velocity, accel * delta)
		move_and_slide()
		_update_animation()
		_flip_player()

func _update_animation() -> void:
		var speed := velocity.length()
		var moving := speed > 5.0
		particle_trails.emitting = false
		if moving:
				player_sprite.play("walk")
		else:
				player_sprite.play("idle")

func _flip_player() -> void:
		if velocity.x < -1.0:
				player_sprite.flip_h = false
		elif velocity.x > 1.0:
				player_sprite.flip_h = true

func death_tween() -> void:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
		await tween.finished
		global_position = spawn_point.global_position
		await get_tree().create_timer(0.3).timeout
		AudioManager.respawn_sfx.play()
		respawn_tween()

func respawn_tween() -> void:
		global_position = spawn_point.global_position
		var tween = create_tween()
		tween.stop()
		tween.play()
		tween.tween_property(self, "scale", original_scale, 0.15)

func _on_collision_body_entered(_body) -> void:
		if _body.is_in_group("Traps"):
				AudioManager.death_sfx.play()
				death_particles.emitting = true
				death_tween()
