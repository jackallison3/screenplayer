@icon("res://icon.svg")
extends Node

signal scene_complete

@export_category("Scene Data")
@export var scene_data: Array[Dictionary] = []
@export var characters: Dictionary = {}

@export_category("ScenePlayer Settings")
@export var dialogue_box_scene: PackedScene
@export var play_on_ready: bool = true
@export var next_button_mapping: String = "ui_accept"
@export var transition_characters_offstage_when_inactive: bool = true
@export var fade_speed: float = 1.0
@export var dialogue_box_fade_speed: float = 2.0
@export var text_speed: float = 100
@export var last_press_interval: float = 0.2
@export var characters_start_onstage: bool = false
@export var free_screen_player_on_scene_end: bool = false

var current_location: CanvasLayer
var characters_onstage: Array[AnimatedSprite2D] = []
var current_scene_index: int = 0
var current_scene_moment: Dictionary = {}

var dialogue_box: Control
var dialogue_box_visible: bool = false
var name_label_visible: bool = false
var last_press_timer: Timer

@onready var locations_node: Node = get_parent().get_node("Locations")
@onready var characters_node: CanvasLayer = get_parent().get_node("Characters")

var fade_in: bool
var fade_out: bool

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Set all Scene Backgrounds Transparent
	for location in locations_node.get_children():
		if location.name != "BackgroundColor":
			var location_canvas_modulate = location.get_node_or_null("LocationCanvasModulate")
			if location_canvas_modulate != null:
				location_canvas_modulate.color.a = 0.0

	# Set all characters to start of transition anim and transparent
	for character in characters_node.get_children():
		character.modulate.a = 0.0
		var animation_player = character.get_node_or_null("CharacterAnimationPlayer")
		if animation_player != null:
			if characters_start_onstage:
				animation_player.play("transition")
				animation_player.seek(animation_player.get_animation("transition").length, true)
				animation_player.pause()
				characters_onstage.append(character)
			else:
				animation_player.play("transition")
				animation_player.seek(0, true)
				animation_player.pause()

	# Instantiate Dialogue Box scene and set transparent
	var dialogue_box_canvas_layer = CanvasLayer.new()
	get_parent().add_child.call_deferred(dialogue_box_canvas_layer)
	if dialogue_box_scene == null:
		dialogue_box_scene = preload("res://addons/screenplayer/dialogue_box/dialogue_box.tscn")
	dialogue_box = dialogue_box_scene.instantiate()
	dialogue_box.modulate.a = 0.0
	dialogue_box_canvas_layer.add_child.call_deferred(dialogue_box)

	# Create last_press timer

	last_press_timer = Timer.new()
	last_press_timer.wait_time = last_press_interval
	last_press_timer.one_shot = true
	add_child(last_press_timer)
	last_press_timer.start()


	if play_on_ready:
		play_scene()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return


	if Input.is_action_just_released(next_button_mapping):
		next_button_press()

	if fade_in:
		var current_location_canvas_modulate = current_location.get_node("LocationCanvasModulate")
		if current_location_canvas_modulate.color.a == 1.0:
			fade_in = false
			current_scene_index += 1
			play_scene()
		else:
			current_location_canvas_modulate.color.a = clamp(
				current_location_canvas_modulate.color.a + (delta * fade_speed), 0.0, 1.0
			)
			for character in characters_node.get_children():
				character.modulate.a = clamp(
					character.modulate.a + (delta * fade_speed), 0.0, 1.0
				)

	if fade_out:
		if dialogue_box_visible:
			dialogue_box_visible = false
		var current_location_canvas_modulate = current_location.get_node("LocationCanvasModulate")
		if current_location_canvas_modulate.color.a == 0.0:
			fade_out = false
			scene_complete.emit()
			print("End Scene")
			if free_screen_player_on_scene_end:
				get_parent().queue_free()
		else:
			current_location_canvas_modulate.color.a = clamp(
				current_location_canvas_modulate.color.a - (delta * fade_speed), 0.0, 1.0
			)
			for character in characters_node.get_children():
				character.modulate.a = clamp(
					character.modulate.a - (delta * fade_speed), 0.0, 1.0
				)

	if dialogue_box_visible:
		if dialogue_box.modulate.a != 1.0:
			dialogue_box.modulate.a = clamp(
				dialogue_box.modulate.a + (delta * dialogue_box_fade_speed), 0.0, 1.0
			)

	if !dialogue_box_visible:
		if dialogue_box.modulate.a != 0.0:
			dialogue_box.modulate.a = clamp(
				dialogue_box.modulate.a - (delta * dialogue_box_fade_speed), 0.0, 1.0
			)
	
	if name_label_visible:
		if dialogue_box.name_panel_container.modulate.a != 1.0:
			dialogue_box.name_panel_container.modulate.a = clamp(
				dialogue_box.name_panel_container.modulate.a + (delta * dialogue_box_fade_speed), 0.0, 1.0
			)

	if !name_label_visible:
		if dialogue_box.name_panel_container.modulate.a != 0.0:
			dialogue_box.name_panel_container.modulate.a = clamp (
				dialogue_box.name_panel_container.modulate.a - (delta * dialogue_box_fade_speed), 0.0, 1.0
			)

	if current_scene_moment.has("action"):
		if dialogue_box.modulate.a == 1.0 and dialogue_box.name_panel_container.modulate.a == 0:
			write_text(delta)

	if current_scene_moment.has("character"):
		if dialogue_box.modulate.a == 1.0 and dialogue_box.name_panel_container.modulate.a == 1.0:
			write_text(delta)

	if dialogue_box_visible and dialogue_box.dialogue_label.visible_ratio == 1.0 and dialogue_box.modulate.a == 1:
		if !dialogue_box.next_icon.visible:
			dialogue_box.next_icon.visible = true

	if dialogue_box_visible and dialogue_box.dialogue_label.visible_ratio != 1.0:
		if dialogue_box.next_icon.visible:
			dialogue_box.next_icon.visible = false

func play_scene() -> void:
	if current_scene_index < scene_data.size():
		current_scene_moment = scene_data[current_scene_index]
		match current_scene_moment.keys()[0]:
			"location":
				var new_location_string = current_scene_moment["location"]
				if current_location == null:
					current_location = locations_node.get_node(new_location_string)
					fade_in = true
			"action":
				dialogue_box.dialogue_label.visible_characters = 0
				dialogue_box_visible = true
				name_label_visible = false
				dialogue_box.dialogue_label.text = current_scene_moment["action"]
			"character":
				dialogue_box.dialogue_label.visible_characters = 0
				dialogue_box.name_label.text = characters[current_scene_moment["character"]]["name"]
				dialogue_box_visible = true
				name_label_visible = true
				dialogue_box.dialogue_label.text = current_scene_moment["dialogue"]
		handle_character_transitions()
		handle_character_states()
	else:
		fade_out = true

func next_button_press():
	if last_press_timer.time_left == 0.0:
		if dialogue_box_visible and dialogue_box.modulate.a != 1.0:
			return
		if name_label_visible and dialogue_box.name_label.modulate.a != 1.0:
			return
		if dialogue_box.next_icon.visible and dialogue_box.dialogue_label.visible_ratio == 1.0:
			last_press_timer.start()
			current_scene_index += 1
			play_scene()
			return
		if !dialogue_box.next_icon.visible and dialogue_box.dialogue_label.visible_ratio != 1.0:
			last_press_timer.start()
			dialogue_box.dialogue_label.visible_characters = dialogue_box.dialogue_label.get_total_character_count()
			return

func write_text(delta: float) -> void:
	if dialogue_box.dialogue_label.visible_characters < dialogue_box.dialogue_label.get_total_character_count():
				dialogue_box.dialogue_label.visible_characters += int(delta * text_speed)

func handle_character_transitions() -> void:
	if current_scene_moment.has("character"):
		var character = current_scene_moment["character"]
		var character_sprite = characters_node.get_node(character)
		if transition_characters_offstage_when_inactive:
			var characters_to_remove = []
			for character_onstage in characters_onstage:
				if character_onstage != character_sprite:
					var animation_player = character_onstage.get_node("CharacterAnimationPlayer")
					animation_player.play_backwards("transition")
					characters_to_remove.append(character_onstage)
			for character_to_remove in characters_to_remove:
				characters_onstage.erase(character_to_remove)
		if !characters_onstage.has(character_sprite):
			var animation_player = character_sprite.get_node("CharacterAnimationPlayer")
			animation_player.play("transition")
			characters_onstage.append(character_sprite)

	if current_scene_moment.has("action") and !current_scene_moment.has("character"):
		if transition_characters_offstage_when_inactive:
			var characters_to_remove = []
			for character_onstage in characters_onstage:
				var animation_player = character_onstage.get_node("CharacterAnimationPlayer")
				animation_player.play_backwards("transition")
				characters_to_remove.append(character_onstage)
			for character_to_remove in characters_to_remove:
				characters_onstage.erase(character_to_remove)

func handle_character_states() -> void:
	if current_scene_moment.has("character"):
		var character = characters_node.get_node(current_scene_moment["character"])
		if current_scene_moment.has("state"):
			character.play(current_scene_moment["state"])
			print("Playing new state: ", current_scene_moment["state"])
		else:
			character.play("default")