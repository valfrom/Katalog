extends CharacterBody2D

@export_category("Player Properties")
@export var move_speed: float = 200.0
@export var walk_speed: float = 110.0
@export var acceleration: float = 1400.0
@export var deceleration: float = 1800.0
@export var jump_force: float = 500.0
@export var gravity: float = 1800.0
@export var max_jump_count: int = 2
var jump_count: int = 2

@export_category("Slopes")
@export var slope_snap_length: float = 10.0
@export var slide_speed: float = 220.0
@export var slide_acceleration: float = 1800.0
@export var min_slope_x: float = 0.05

@export_category("Toggle Functions")
@export var double_jump := false

@export_category("Jump Buffer")
@export var jump_buffer_ms: int = 100

@export_category("Coyote Time")
@export var coyote_ms: int = 100

@export_category("Animation Speed")
@export var walk_anim_min_speed: float = 0.8
@export var walk_anim_max_speed: float = 1.2
@export var run_anim_min_speed: float = 1.0
@export var run_anim_max_speed: float = 1.8

@export_category("Idle Variations")
@export var idle_variant_delay_s: float = 3.0

var _jump_buffered := false
var _is_walking := false
var _is_sliding := false
var _coyote_left := 0.0
var _idle_time := 0.0
var _jumped_this_frame := false
var hero_id: String = ""

@onready var player_sprite = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles
@onready var _jump_buffer_timer: Timer = Timer.new()
@onready var originalScale = self.scale

func _ready() -> void:
    randomize()
    floor_snap_length = slope_snap_length

    _jump_buffer_timer.one_shot = true
    _jump_buffer_timer.wait_time = float(jump_buffer_ms) / 1000.0
    add_child(_jump_buffer_timer)
    _jump_buffer_timer.timeout.connect(_on_jump_buffer_timeout)
    GameManager.register_level_player(self)
    if hero_id == "":
        hero_id = GameManager.current_hero_id

func _physics_process(delta: float) -> void:
    movement(delta)
    player_animations(delta)
    flip_player()

func movement(delta: float) -> void:
    _jumped_this_frame = false
    _is_walking = Input.is_action_pressed("Walk")

    if is_on_floor():
        _coyote_left = float(coyote_ms) / 1000.0
        jump_count = max_jump_count
        _try_consume_buffered_jump()
    else:
        _coyote_left = max(0.0, _coyote_left - delta)
        velocity.y += gravity * delta

    _handle_jump_input()

    _is_sliding = Input.is_action_pressed("Down") && is_on_floor() && _is_on_slope() && slide_speed > 0.0

    if _is_sliding:
        var target := _downhill_dir() * slide_speed
        velocity = velocity.move_toward(target, slide_acceleration * delta)
        if !_jumped_this_frame:
            apply_floor_snap()
        move_and_slide()
        return

    var input_axis := Input.get_axis("Left", "Right")
    var speed := walk_speed if _is_walking else move_speed
    var target_vx := input_axis * speed

    if absf(target_vx) > 0.0:
        velocity.x = move_toward(velocity.x, target_vx, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

    if is_on_floor() && !_jumped_this_frame:
        velocity.y = 0.0
        apply_floor_snap()

    move_and_slide()

func _is_on_slope() -> bool:
    var n := get_floor_normal()
    return absf(n.x) > min_slope_x

func _downhill_dir() -> Vector2:
    var n := get_floor_normal().normalized()
    var t := Vector2(n.y, -n.x).normalized()
    if t.y > 0.0:
        return t
    return -t

func _handle_jump_input() -> void:
    if !Input.is_action_just_pressed("Jump"):
        return

    if _can_jump_now():
        _do_jump_now()
        return

    _buffer_jump()

func _buffer_jump() -> void:
    _jump_buffered = true
    _jump_buffer_timer.start()

func _try_consume_buffered_jump() -> void:
    if !_jump_buffered:
        return
    if !_can_jump_now():
        return

    _jump_buffered = false
    _jump_buffer_timer.stop()
    _do_jump_now()

func _can_jump_now() -> bool:
    var grounded_like := is_on_floor() || _coyote_left > 0.0

    if grounded_like && !double_jump:
        return true
    if double_jump:
        if grounded_like:
            return true
        if jump_count > 0:
            return true

    return false

func _do_jump_now() -> void:
    var grounded_like := is_on_floor() || _coyote_left > 0.0

    if double_jump && !grounded_like:
        jump_count -= 1

    _coyote_left = 0.0
    _jumped_this_frame = true
    _is_sliding = false
    jump()

func _on_jump_buffer_timeout() -> void:
    _jump_buffered = false

func jump() -> void:
    AudioManager.jump_sfx.play()
    velocity.y = -jump_force

func player_animations(delta: float) -> void:
    particle_trails.emitting = false

    if is_on_floor() && _is_sliding:
        _idle_time = 0.0
        player_sprite.speed_scale = 1.0
        player_sprite.play("slide")
        return

    var speed_x = abs(velocity.x)

    if is_on_floor():
        if speed_x > 0.0:
            _idle_time = 0.0
            if _is_walking:
                var t = clamp(speed_x / walk_speed, 0.0, 1.0)
                player_sprite.speed_scale = lerp(walk_anim_min_speed, walk_anim_max_speed, t)
                player_sprite.play("walk")
            else:
                var t = clamp(speed_x / move_speed, 0.0, 1.0)
                player_sprite.speed_scale = lerp(run_anim_min_speed, run_anim_max_speed, t)
                particle_trails.emitting = true
                player_sprite.play("run", 1.5)
        else:
            player_sprite.speed_scale = 1.0
            _idle_time += delta

            if _idle_time >= idle_variant_delay_s:
                if player_sprite.animation != "idle_1" && player_sprite.animation != "idle_2":
                    player_sprite.play("idle_1" if randi() % 2 == 0 else "idle_2")
            else:
                player_sprite.play("idle")
    else:
        _idle_time = 0.0
        player_sprite.speed_scale = 1.0
        if velocity.y > 0.0:
            player_sprite.play("jump_down")
        else:
            player_sprite.play("jump_up")

func flip_player() -> void:
    if velocity.x < 0.0:
        player_sprite.flip_h = false
    elif velocity.x > 0.0:
        player_sprite.flip_h = true

func _reset_motion_state() -> void:
    velocity = Vector2.ZERO
    jump_count = max_jump_count
    _jump_buffered = false
    _is_sliding = false
    _jumped_this_frame = false
    _coyote_left = 0.0
    _is_walking = false

func death_tween() -> void:
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
    await tween.finished
    global_position = spawn_point.global_position
    _reset_motion_state()

func play_respawn() -> void:
    global_position = spawn_point.global_position
    _reset_motion_state()
    scale = Vector2.ZERO
    await get_tree().create_timer(0.3).timeout
    AudioManager.respawn_sfx.play()
    var tween = create_tween()
    tween.tween_property(self, "scale", originalScale, 0.15)

func apply_hero(hero: Dictionary) -> void:
    hero_id = hero.get("id", "")
    if hero.has("color"):
        player_sprite.modulate = hero["color"]

func _on_collision_body_entered(_body) -> void:
    if _body.is_in_group("Traps"):
        AudioManager.death_sfx.play()
        death_particles.emitting = true
