extends GameObject


#-------------------------------- GameObject logic -----------------------

var parts := 1
var last_parts := 1

var start_offset := 0
var start_percentage := 0
var last_start_percentage := 0

const MT_BACK_FORTH = 0
const MT_RESET = 1
const MT_ONCE = 2
const MT_LOOP = 3


var move_type := MT_BACK_FORTH
var touch_start := false

var end_position : Vector2
var last_end_position : Vector2

var max_speed := 1.0
onready var blend := pow(0.95, 120 * fps_util.PHYSICS_DELTA)

var curve = null

var inverted : bool = false
var frozen = false
var disappears = true

func _set_properties():
	savable_properties = ["parts", "max_speed", "curve", "move_type", "touch_start",  "start_offset", "inverted", "disappears"]
	editable_properties = ["parts", "max_speed", "end_position", "move_type", "touch_start",  "start_offset", "inverted", "disappears"]
	
func _set_property_values():
	set_property("parts", parts)
	set_property("max_speed", max_speed)
	set_property("curve", curve)
	set_property("end_position", end_position)
	set_property("move_type", move_type)
	set_property("touch_start", touch_start)
	set_property("start_offset", start_offset)
	set_property("inverted", inverted, true)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and hovered:
		if event.button_index == 5: # Mouse wheel down
			parts -= 1
			if parts < 1:
				parts = 1
			set_property("parts", parts)
		elif event.button_index == 4: # Mouse wheel up
			parts += 1
			set_property("parts", parts)

func _process(_delta):
	if parts != last_parts:
		platform.set_parts(parts)
		if(mode==1):
			set_sprite_parts(start_sprite_node.get_child(0))
			set_sprite_parts(start_sprite_node.get_child(1))
			set_sprite_parts(end_sprite_node.get_child(0))
			set_sprite_parts(end_sprite_node.get_child(1))
		last_parts = parts
	if curve != path.curve:
		path.curve = curve
		
	if end_position != last_end_position:
		var last_index = path.curve.get_point_count()-1
		
		path.curve.set_point_position(last_index, end_position*32)
		update()
		end_sprite_node.position = path.curve.get_point_position(last_index)
		
		last_end_position = end_position


#-------------------------------- platform logic -----------------------

onready var platform = $OnOffTouchLiftPlatform
onready var path_follower = $Path2D/PathFollow2D
onready var path = $Path2D
onready var platform_sprite = $OnOffTouchLiftPlatform/Sprite

export var circle_texture : Texture

var speed := 1.0
var loop_offset := 0.0
var linear_offset := 0.0
var time_alive = 0

var activated = false

onready var start_sprite_node : Node2D
onready var end_sprite_node : Node2D

const line_color = Color(1, 1, 1, 0.5)
const transparent_color : Color = Color(1, 1, 1, 0.5)

onready var left_width = platform_sprite.patch_margin_left
onready var right_width = platform_sprite.patch_margin_right
onready var part_width = platform_sprite.texture.get_width() - left_width - right_width

func _ready():
	activated = !touch_start
	
	platform.collision_shape.disabled = !enabled
	platform.platform_area_collision_shape.disabled = !enabled
	
	platform.platform_area_collision_shape.get_parent().connect("body_entered", self, "_on_touch_area_entered")
	platform_sprite.region_rect.position.y = palette * 14
	if curve == null and path.curve == null:
		path.curve = Curve2D.new()
		path.curve.add_point(Vector2())
		path.curve.add_point(Vector2(0,-64))
		
		set_property("curve", path.curve)
	elif path.curve == null:
		path.curve = curve
	elif curve == null:
		set_property("curve", path.curve)
	
	platform.set_parts(parts)
	
	linear_offset = start_offset
	loop_offset = start_offset
	path_follower.offset = start_offset
	
	if(mode==1):
		platform.modulate = transparent_color
		start_sprite_node = Node2D.new()
		start_sprite_node.add_child(platform_sprite.duplicate())
		#end_sprite.add_child(platform_sprite)
		add_child(start_sprite_node)
		
		end_sprite_node = Node2D.new()
		end_sprite_node.add_child(platform_sprite.duplicate())
		end_sprite_node.modulate = transparent_color
		add_child(end_sprite_node)
		
		set_property("end_position", path.curve.get_point_position(path.curve.get_point_count()-1)/32)
	frozen = inverted
	set_state(Singleton.CurrentLevelData.level_data.vars.switch_state[palette])
	Singleton.CurrentLevelData.level_data.vars.connect("switch_state_changed", self, "_on_switch_state_changed")

func set_state(state : bool):
	if inverted:
		frozen = state
		if(disappears):
				platform_sprite.region_rect.position.x = int(state) * 22
		platform.momentum = Vector2(0,0) 
	else:
		frozen = !state
		if(disappears):
				platform_sprite.region_rect.position.x = int(!state) * 22
		platform.momentum = Vector2(0,0) 

func _on_switch_state_changed(new_state, channel):
	if palette == channel:
		print("State changed")
		set_state(new_state)

func set_sprite_parts(sprite):
	sprite.rect_position.x = -(left_width + (part_width * parts) + right_width) / 2
	sprite.rect_size.x = left_width + right_width + part_width * parts

func draw_circle_custom(position, radius, color, maxerror = 0.25):
	if radius <= 0.0:
		return

	var maxpoints = 1024 # I think this is renderer limit

	var numpoints = ceil(PI / acos(1.0 - maxerror / radius))
	numpoints = clamp(numpoints, 3, maxpoints)

	var points = PoolVector2Array([])

	for i in numpoints:
		var phi = i * PI * 2.0 / numpoints
		var v = position + Vector2(sin(phi), cos(phi))
		points.push_back(v * radius)

	draw_colored_polygon(points, color)

func _draw():
	if mode == 1:
		draw_polyline(path.curve.get_baked_points(), line_color, 2.0)
	else:
		for offset in range(0,path.curve.get_baked_length(), 10.0):
			var pos : Vector2 = path.curve.interpolate_baked(offset)
			draw_texture_rect(circle_texture, Rect2(pos - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), false, Color.darkgray)

func _physics_process(delta):
	if(disappears):
		platform.collision_shape.disabled = frozen
		platform.platform_area_collision_shape.disabled = frozen
	if(!activated || frozen):
		platform.momentum = Vector2(0,0)
		platform.set_position(Vector2(stepify(position.x, 1), stepify(position.y, 1)))
		return

	
	linear_offset += speed * max_speed * 120 * fps_util.PHYSICS_DELTA

	if move_type != MT_LOOP:
		linear_offset = clamp(linear_offset, 0.0, path.curve.get_baked_length()-0.01) #so the 

	loop_offset = lerp(linear_offset, loop_offset, blend) #loop_offset * blend + linear_offset * (1 - blend)
	
	path_follower.offset = fmod(loop_offset, path.curve.get_baked_length())
	
	if speed < 0.0 and path_follower.offset <= 2.0:
		linear_offset = 0.0
		speed = -speed
	
	elif move_type != MT_LOOP and speed > 0.0 and path_follower.offset >= path.curve.get_baked_length() - 2.0:
		linear_offset = path.curve.get_baked_length()
		reached_end()
		
		if !activated:
			return
	
	if mode != 1:
		platform.set_position(path_follower.position)
	else:
		platform.position = path_follower.position

func reached_end() -> void:
	if(frozen):
		return
	match move_type:
		MT_BACK_FORTH:
			speed = -speed
		MT_RESET:
			$AnimationPlayer.play("Reset")
		MT_ONCE:
			activated = false

func _on_touch_area_entered(body):
	if body is Character:
		activated = true

func reset_platform():
	if(frozen):
		return
	linear_offset = 0.0
	loop_offset = 0.0
	path_follower.offset = 0.0
	
	platform.position = path_follower.position
	
	activated = !touch_start