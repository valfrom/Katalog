extends Control

@onready var backdrop: ColorRect = %Backdrop
@onready var title_label: Label = %Title
@onready var hero_name_label: Label = %HeroName
@onready var portrait: TextureRect = %Portrait
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var continue_button: Button = %ContinueButton

var _return_scene: String = ""

func _ready() -> void:
    _return_scene = GameManager.consume_hero_unlock_return_scene()
    var hero_id := GameManager.consume_unlocked_hero()

    if hero_id == "":
        _go_to_return_scene()
        return

    var hero := GameManager.get_hero_definition(hero_id)
    title_label.text = "New Hero Found!"
    hero_name_label.text = hero.get("name", "Unknown Hero")
    backdrop.color = hero.get("color", Color.DIM_GRAY)

    var portrait_path: String = hero.get("portrait_path", "")
    if portrait_path != "":
        var texture: Texture2D = load(portrait_path)
        if texture:
            portrait.texture = texture

    animation_player.play("reveal")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        _go_to_return_scene()

func _on_continue_button_pressed() -> void:
    _go_to_return_scene()

func _go_to_return_scene() -> void:
    if _return_scene == "" and GameManager.saved_scene_path != "":
        _return_scene = GameManager.saved_scene_path
    if _return_scene != "":
        SceneTransition.load_scene(_return_scene)
