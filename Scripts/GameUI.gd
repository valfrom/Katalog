extends Control

@onready var score_texture = %Score/ScoreTexture
@onready var score_label = %Score/ScoreLabel
@onready var current_hero_label = %HeroHUD/CurrentHeroLabel
@onready var available_heroes_label = %HeroHUD/AvailableHeroesLabel
@onready var hero_lives_label = %HeroHUD/HeroLivesLabel

func _ready():
    _update_hero_display()

func _process(_delta):
    score_label.text = "x %d" % GameManager.score
    _update_hero_display()

func _update_hero_display() -> void:
    var hero_definition := GameManager.get_hero_definition(GameManager.current_hero_id)
    var hero_name := "None"
    if not hero_definition.is_empty():
        hero_name = hero_definition.get("name", GameManager.current_hero_id.capitalize())
    current_hero_label.text = "Hero: %s" % hero_name

    var available_names: Array[String] = []
    for hero_id in GameManager.unlocked_heroes:
        var definition := GameManager.get_hero_definition(hero_id)
        if definition.is_empty():
            available_names.append(hero_id.capitalize())
        else:
            available_names.append(definition.get("name", hero_id.capitalize()))

    if available_names.is_empty():
        available_heroes_label.text = "Available: None"
    else:
        available_heroes_label.text = "Available: %s" % ", ".join(available_names)

    var lives := GameManager.get_hero_lives(GameManager.current_hero_id)
    hero_lives_label.text = "Lives: %d" % lives
