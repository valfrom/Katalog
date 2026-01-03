extends Camera2D

@export var base_size := Vector2i(1000, 600)

@export var fps_focus_delay_seconds := 10.0
@export var fps_sample_window_seconds := 3.0
@export var fps_min_samples := 60
@export var fps_apply_engine_limit := true

@export var fps_over_limit_restart_delay_seconds := 20.0
@export var fps_over_limit_tolerance := 1.0
@export var fps_over_limit_required_seconds := 1.0

var _focus_generation := 0
var _sampling := false
var _sample_time := 0.0
var _fps_samples: Array[float] = []

var _limit_set_at_seconds := -1.0
var _over_limit_time := 0.0

func _ready() -> void:
    _update_zoom()
    get_viewport().size_changed.connect(_update_zoom)
    if DisplayServer.window_is_focused():
        _on_focus_in()

func _process(delta: float) -> void:
    if _sampling:
        _sample_time += delta
        _fps_samples.append(float(Engine.get_frames_per_second()))

        if _sample_time < fps_sample_window_seconds:
            return
        if _fps_samples.size() < fps_min_samples:
            return

        _sampling = false
        _apply_detected_fps(_median(_fps_samples))
        return

    _check_over_limit_restart(delta)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_IN || what == NOTIFICATION_APPLICATION_RESUMED:
        _on_focus_in()
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT || what == NOTIFICATION_APPLICATION_PAUSED:
        _on_focus_out()

func _on_focus_in() -> void:
    Engine.max_fps = 0
    _focus_generation += 1
    _sampling = false
    _sample_time = 0.0
    _fps_samples.clear()
    _limit_set_at_seconds = -1.0
    _over_limit_time = 0.0
    _start_after_delay(_focus_generation)

func _on_focus_out() -> void:
    _focus_generation += 1
    _sampling = false
    _sample_time = 0.0
    _fps_samples.clear()
    _limit_set_at_seconds = -1.0
    _over_limit_time = 0.0

func _start_after_delay(gen: int) -> void:
    await get_tree().create_timer(fps_focus_delay_seconds).timeout
    if gen != _focus_generation:
        return
    if !DisplayServer.window_is_focused():
        return
    _begin_sampling()

func _begin_sampling() -> void:
    _sampling = true
    _sample_time = 0.0
    _fps_samples.clear()

func _apply_detected_fps(measured_fps: float) -> void:
    var target := _common_cap_from(measured_fps)
    if !fps_apply_engine_limit:
        return

    if target <= 0:
        Engine.max_fps = 0
        _limit_set_at_seconds = -1.0
        _over_limit_time = 0.0
        return

    Engine.max_fps = target
    _limit_set_at_seconds = _now_seconds()
    _over_limit_time = 0.0

func _check_over_limit_restart(delta: float) -> void:
    if !fps_apply_engine_limit:
        return
    if !DisplayServer.window_is_focused():
        return
    if Engine.max_fps <= 0:
        return
    if _limit_set_at_seconds < 0.0:
        return

    var elapsed := _now_seconds() - _limit_set_at_seconds
    if elapsed < fps_over_limit_restart_delay_seconds:
        return

    var fps := float(Engine.get_frames_per_second())
    if fps > float(Engine.max_fps) + fps_over_limit_tolerance:
        _over_limit_time += delta
    else:
        _over_limit_time = 0.0

    if _over_limit_time < fps_over_limit_required_seconds:
        return

    _restart_detection()

func _restart_detection() -> void:
    _focus_generation += 1
    _sampling = false
    _sample_time = 0.0
    _fps_samples.clear()
    _limit_set_at_seconds = -1.0
    _over_limit_time = 0.0
    Engine.max_fps = 0
    _begin_sampling()

func _common_cap_from(fps: float) -> int:
    if fps > 90.0:
        return 0

    var candidates := [30, 40, 60, 90]
    var best = candidates[0]
    var best_diff = abs(fps - float(best))

    for c in candidates:
        var d = abs(fps - float(c))
        if d < best_diff:
            best_diff = d
            best = c

    return best

func _median(values: Array[float]) -> float:
    if values.is_empty():
        return 0.0

    var sorted := values.duplicate()
    sorted.sort()

    var mid := sorted.size() / 2
    if (sorted.size() % 2) == 1:
        return sorted[mid]

    return (sorted[mid - 1] + sorted[mid]) * 0.5

func _now_seconds() -> float:
    return float(Time.get_ticks_msec()) / 1000.0

func _update_zoom() -> void:
    var vp := get_viewport_rect().size
    if vp.x <= 0.0 || vp.y <= 0.0:
        return

    var sx := vp.x / float(base_size.x)
    var sy := vp.y / float(base_size.y)
    var s = min(sx, sy)
    zoom = Vector2(s, s)
