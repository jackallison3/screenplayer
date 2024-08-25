@tool
@icon("res://icon.svg")
extends Node

#TODO: Parse bold and italic into bbcode

var script_file : set = _set_script_file
var script_file_loaded: bool = false
var use_scene_number: bool = false : set = _set_use_scene_number
var scene_number: String = "0" : set = _set_scene_number
var raw_scene: Array[Dictionary] = []
var processing_scene: bool = false
var script_locked: bool = false : set = _set_script_locked
var characters: Dictionary = {}

func _set_script_file(file) -> void:
	script_file = file
	if script_file != "":
		load_script_file()
		script_file_loaded = true
	else:
		script_file_loaded = false
	notify_property_list_changed()

func _set_use_scene_number(value) -> void:
	use_scene_number = value
	notify_property_list_changed()
	load_script_file()

func _set_scene_number(value) -> void:
	scene_number = value
	load_script_file()

func _set_script_locked(value) -> void:
	if value == true:
		script_post_process()
	script_locked = value
	notify_property_list_changed()

func _get_property_list() -> Array:
	var properties = []
	properties.append({
		"name": "Script Settings",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	if !script_locked:
		properties.append({
			"name": "script_file",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.xml",
			"usage": PROPERTY_USAGE_DEFAULT
		})
		if script_file_loaded:
			properties.append({
				"name": "use_scene_number",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			if use_scene_number:
				properties.append({
					"name": "scene_number",
					"type": TYPE_STRING,
					"usage": PROPERTY_USAGE_DEFAULT
				})
			properties.append({
				"name": "raw_scene",
				"type": TYPE_ARRAY,
				"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
			})
	if script_file_loaded:
		properties.append({
			"name": "script_locked",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT
	})
	if script_locked:
		properties.append({
		"name": "Scene Information",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
		})
		properties.append({
			"name": "scene_data",
			"type": TYPE_ARRAY,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
		properties.append({
			"name": "locations",
			"type": TYPE_DICTIONARY,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
		properties.append({
			"name": "characters",
			"type": TYPE_DICTIONARY,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		})
	return properties

func load_script_file() -> void:
	
	raw_scene.clear()
	if script_file == "":
		return
	var parser = XMLParser.new()
	parser.open(script_file)
	
	var found_scene_number = false
	
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if use_scene_number:
				if parser.get_node_name() == "para" and parser.has_attribute("number"):
					var para_number = String(parser.get_named_attribute_value("number"))
					
					if para_number == scene_number:
						found_scene_number = true
						processing_scene = true
					elif para_number > scene_number and found_scene_number:
						break
					else:
						processing_scene = false
			else:
				processing_scene = true
			
			if processing_scene and (not use_scene_number or found_scene_number):
				if parser.get_node_name() == "style":
					var attributes_dict = {}
					for idx in range(parser.get_attribute_count()):
						attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
					if attributes_dict.size() == 1 and attributes_dict.has("basestyle") and attributes_dict["basestyle"]:
						match attributes_dict["basestyle"]:
							"Action":
								var action = {}
								var action_text = parse_text(parser)
								if action_text != "":
									action["action"] = action_text
									raw_scene.append(action)
							"Character":
								var dialogue = {}
								while parser.read() != ERR_FILE_EOF:
									if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "text":
										if parser.read() == OK and parser.get_node_type() == XMLParser.NODE_TEXT:
											var raw_name = parser.get_node_data()
											
											# Remove anything inside parentheses
											var paren_index = raw_name.find("(")
											if paren_index != -1:
												raw_name = raw_name.substr(0, paren_index)

											# Trim leading and trailing whitespace
											var clean_name = raw_name.strip_edges()

											dialogue["character"] = clean_name.to_upper().validate_node_name()
											raw_scene.append(dialogue)
										break
									elif parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() != "text":
										break
							"Dialogue":
								var dialogue = {}
								var dialogue_text = parse_text(parser)
								if dialogue_text != "":
									raw_scene[raw_scene.size()-1]["dialogue"] = dialogue_text
							"Parenthetical":
								while parser.read() != ERR_FILE_EOF:
									if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "text":
										if parser.read() == OK and parser.get_node_type() == XMLParser.NODE_TEXT:
											raw_scene[raw_scene.size()-1]["state"] = parser.get_node_data()
										break
									elif parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() != "text":
										break
							"Scene Heading":
								var location = {}
								while parser.read() != ERR_FILE_EOF:
									if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "text":
										if parser.read() == OK and parser.get_node_type() == XMLParser.NODE_TEXT:
											var location_text = parser.get_node_data()
											location_text = location_text.validate_node_name()
											location["location"] = location_text
											raw_scene.append(location)
										break
									elif parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() != "text":
										break
				notify_property_list_changed()

func script_post_process() -> void:
	setup_locations_node()
	setup_characters_node()
	add_sceneplayer_node()

	for line in raw_scene:
		if line.has("location"):
			process_location(line["location"])
		if line.has("character"):
			process_character(line["character"])
		if line.has("state"):
			process_state(line)

	queue_free()

func parse_text(parser: XMLParser) -> String:
	var text_to_add = ""
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "text":
			if parser.read() == OK and parser.get_node_type() == XMLParser.NODE_TEXT:
				if parser.has_attribute("bold"):
					text_to_add += "[b]"
				if parser.has_attribute("italic"):
					text_to_add += "[i]"
				if parser.has_attribute("strikethrough"):
					text_to_add += "[s]"
				if parser.has_attribute("underline"):
					text_to_add += "[u]"

				text_to_add += parser.get_node_data()

				if parser.has_attribute("underline"):
					text_to_add += "[/u]"
				if parser.has_attribute("strikethrough"):
					text_to_add += "[/s]"
				if parser.has_attribute("italic"):
					text_to_add += "[/i]"
				if parser.has_attribute("bold"):
					text_to_add += "[/b]"

		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "para":
			break
	return text_to_add


func setup_locations_node() -> void:
	if Engine.is_editor_hint():
		var locations_node = get_parent().get_node_or_null("Locations")
		
		if locations_node == null:
			locations_node = Node.new()
			locations_node.name = "Locations"
			get_parent().add_child(locations_node)
			locations_node.owner = get_tree().edited_scene_root
			var bg_color_node = ColorRect.new()
			bg_color_node.color = Color(0,0,0,1)
			bg_color_node.name = "BackgroundColor"
			bg_color_node.anchor_left = 0
			bg_color_node.anchor_right = 1
			bg_color_node.anchor_top = 0
			bg_color_node.anchor_bottom = 1
			locations_node.add_child(bg_color_node)
			bg_color_node.owner = get_tree().edited_scene_root
			print("Locations node added")

func setup_characters_node() -> void:
	if Engine.is_editor_hint():
		var characters_node = get_parent().get_node_or_null("Characters")

		if characters_node == null:
			characters_node = CanvasLayer.new()
			characters_node.name = "Characters"
			get_parent().add_child(characters_node)
			print("Characters node added")
			characters_node.owner = get_tree().edited_scene_root

func process_location(location_name: String) -> void:
	var locations_node = get_parent().get_node_or_null("Locations")
	if locations_node == null:
		setup_locations_node()  # Ensure the node is created
		locations_node = get_parent().get_node("Locations")
	
	if not locations_node.has_node(location_name):
		var location_node = CanvasLayer.new()
		location_node.name = location_name
		locations_node.add_child(location_node)
		print("Location node added: " + location_name)
		location_node.owner = get_tree().edited_scene_root
		var canvas_modulate = CanvasModulate.new()
		canvas_modulate.name = "LocationCanvasModulate"
		location_node.add_child(canvas_modulate)
		canvas_modulate.owner = get_tree().edited_scene_root

func process_character(character_name: String) -> void:
	var characters_node = get_parent().get_node_or_null("Characters")
	if characters_node == null:
		setup_characters_node()  # Ensure the node is created
		characters_node = get_parent().get_node("Characters")
	
	if not characters_node.has_node(character_name):
		var character_sprite = AnimatedSprite2D.new()
		var sprite_frames = SpriteFrames.new()
		character_sprite.frames = sprite_frames
		character_sprite.name = character_name
		characters_node.add_child(character_sprite)
		character_sprite.owner = get_tree().edited_scene_root
		
		var animation_player = AnimationPlayer.new()
		var animation_library = AnimationLibrary.new()
		var animation = Animation.new()
		animation.length = 0.5
		animation_library.add_animation("transition", animation)
		animation_player.add_animation_library("", animation_library)
		animation_player.name = "CharacterAnimationPlayer"
		character_sprite.add_child(animation_player)
		animation_player.owner = get_tree().edited_scene_root
		print("Character node added: " + character_name)

	if !characters.has(character_name):
		characters[character_name] = {
			"name" : character_name
		}

func process_state(script_line) -> void:
	var characters_node = get_parent().get_node("Characters")
	var character_sprite = characters_node.get_node(script_line["character"])
	if not character_sprite.sprite_frames.has_animation(script_line["state"]):
		character_sprite.sprite_frames.add_animation(script_line["state"])
	var animation_library: AnimationLibrary = character_sprite.get_node("CharacterAnimationPlayer").get_animation_library("")
	if !animation_library.has_animation(script_line["state"]):
		var new_animation = Animation.new()
		new_animation.length = 0.5
		animation_library.add_animation(script_line["state"], new_animation)

func add_sceneplayer_node() -> void:
	if get_parent().get_node_or_null("ScenePlayer") == null:
		var sceneplayer_node = load("addons/screenplayer/nodes/scene_player.gd").new() as Node
		sceneplayer_node.name = "ScenePlayer"
		sceneplayer_node.scene_data = raw_scene
		sceneplayer_node.characters = characters
		get_parent().add_child(sceneplayer_node)
		get_parent().move_child(sceneplayer_node, 0)
		sceneplayer_node.owner = get_tree().edited_scene_root