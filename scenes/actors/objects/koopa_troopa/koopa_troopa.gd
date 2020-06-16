extends GameObject

onready var sprite = $Koopa/Sprite
onready var sprite_color = $Koopa/Sprite/Color
onready var body = $Koopa
onready var attack_area = $Koopa/AttackArea
onready var stomp_area = $Koopa/StompArea
onready var left_check = $Koopa/Left
onready var right_check = $Koopa/Right
onready var koopa_sound = $Koopa/AudioStreamPlayer
var dead = false

var gravity : float
var velocity := Vector2()

var delete_timer = 0.0
var speed = 30
var shell_max_speed = 560
var accel = 5

var facing_direction := -1
var time_alive = 0.0

var hit = false
var snap := Vector2(0, 12)

var shell
var shell_sprite
var shell_sprite_color
var shell_attack_area
var shell_stomp_area
var shell_destroy_area
var shell_sound
onready var shell_scene = load("res://scenes/actors/objects/koopa_troopa/shell.tscn")

var color := Color(0, 1, 0)
var rainbow := false

func _set_properties():
	savable_properties = ["color", "rainbow"]
	editable_properties = ["color", "rainbow"]
	
func _set_property_values():
	set_property("color", color, true)
	set_property("rainbow", rainbow, true)

func _ready():
	CurrentLevelData.enemies_instanced += 1
	time_alive += float(CurrentLevelData.enemies_instanced) / 2.0
	gravity = CurrentLevelData.level_data.areas[CurrentLevelData.area].settings.gravity

func retract_into_shell():
	shell = shell_scene.instance()
	shell_sprite = shell.get_node("Sprite")
	shell_sprite_color = shell.get_node("Sprite/Color")
	shell_stomp_area = shell.get_node("StompArea")
	shell_destroy_area = shell.get_node("DestroyArea")
	shell_attack_area = shell.get_node("AttackArea")
	shell_sound = shell.get_node("AudioStreamPlayer")
	add_child(shell)
	shell.global_position = body.global_position
	velocity = Vector2()
	snap = Vector2(0, 6)
	body.queue_free()
	
func shell_hit(shell_pos : Vector2):
	if is_instance_valid(body):
		kill(shell_pos)
		
func exploded(explosion_pos : Vector2):
	kill(explosion_pos)
		
func kill(hit_pos : Vector2):
	if !hit:
		if is_instance_valid(shell):
			hit = true
			shell.set_collision_layer_bit(2, false)
			shell.set_collision_mask_bit(2, false)
			velocity.x = int((shell.global_position - hit_pos).normalized().x) * 50
			velocity.y = -120
			z_index = 10
			shell_sound.play()
			shell_sprite.playing = false
			delete_timer = 3.0
		elif is_instance_valid(body):
			hit = true
			body.set_collision_layer_bit(2, false)
			body.set_collision_mask_bit(2, false)
			velocity.x = int((body.global_position - hit_pos).normalized().x) * 50
			velocity.y = -120
			z_index = 10
			koopa_sound.play()
			delete_timer = 3.0
			
func _process(delta):
	if rainbow:
		color.h = float(wrapi(OS.get_ticks_msec(), 0, 500)) / 500
	if is_instance_valid(body):
		sprite_color.animation = sprite.animation
		sprite_color.frame = sprite.frame
		sprite_color.modulate = color
	elif is_instance_valid(shell):
		shell_sprite_color.frame = shell_sprite.frame
		shell_sprite_color.modulate = color

func _physics_process(delta):
	time_alive += delta
	if delete_timer > 0 and dead:
		delete_timer -= delta
		if delete_timer <= 0:
			delete_timer = 0
			queue_free()
	
	if mode != 1 and enabled and !dead:
		if !hit:
			if is_instance_valid(body):
				var level_size = CurrentLevelData.level_data.areas[CurrentLevelData.area].settings.size
				if body.global_position.y > (level_size.y * 32) + 128:
					queue_free()
					
				for hit_body in attack_area.get_overlapping_bodies():
					if hit_body.name.begins_with("Character"):
						if hit_body.attacking:
							retract_into_shell()
							shell_sound.play()
							velocity.x = (shell.global_position - hit_body.global_position).normalized().x * (shell_max_speed)
							velocity.y = -275
						else:
							hit_body.damage_with_knockback(body.global_position)
			
				for hit_body in stomp_area.get_overlapping_bodies():
					if hit_body.name.begins_with("Character"):
						if hit_body.velocity.y > 0:
							if !hit_body.big_attack:
								if hit_body.state != hit_body.get_state_node("DiveState"):
									hit_body.set_state_by_name("BounceState", 0)
								hit_body.velocity.y = -330
								retract_into_shell()
								shell_sound.play()
							else:
								shell_hit(hit_body.global_position)
		
				sprite.flip_h = true if facing_direction == 1 else false
				sprite.animation = "walking"
				velocity.x = lerp(velocity.x, facing_direction * speed, delta * accel)
				velocity.y += gravity
				velocity = body.move_and_slide_with_snap(velocity, snap, Vector2.UP.normalized(), true, 4, deg2rad(46))
				
				if !left_check.is_colliding() or body.global_position.x < 0 or body.test_move(body.global_transform, Vector2(-0.1, 0)):
					facing_direction = 1
				if !right_check.is_colliding() or body.global_position.x > (level_size.x * 32) or body.test_move(body.global_transform, Vector2(0.1, 0)):
					facing_direction = -1
			elif is_instance_valid(shell):
				var level_size = CurrentLevelData.level_data.areas[CurrentLevelData.area].settings.size
				if shell.global_position.y > (level_size.y * 32) + 128:
					queue_free()
	
				for hit_body in shell_attack_area.get_overlapping_bodies():
					if hit_body.name.begins_with("Character"):
						var hit_speed = shell_max_speed
						if hit_body.attacking:
							velocity.x = (shell.global_position - hit_body.global_position).normalized().x * (shell_max_speed)
							velocity.y = -275
						else:
							velocity.x = (shell.global_position - hit_body.global_position).normalized().x * hit_speed
						shell_sound.play()
					
				for hit_area in shell_destroy_area.get_overlapping_areas():
					if hit_area.get_parent().get_parent().has_method("shell_hit") and hit_area.get_parent().get_parent() != self:
						hit_area.get_parent().get_parent().shell_hit(shell.global_position)
			
				for hit_body in shell_stomp_area.get_overlapping_bodies():
					if hit_body.name.begins_with("Character"):
						if hit_body.velocity.y > 0:
							if !hit_body.big_attack:
								if hit_body.state != hit_body.get_state_node("DiveState"):
									hit_body.set_state_by_name("BounceState", 0)
								hit_body.velocity.y = -330
								velocity.x = 0
								shell_sound.play()
							else:
								shell_hit(hit_body.global_position)
							
				if (
					shell.test_move(shell.global_transform, Vector2(velocity.x * delta, 0))
				):
					velocity.x = -velocity.x
				
				if (
					shell.global_position.x < -64 or 
					shell.global_position.x > (level_size.x * 32) + 64
				):
					queue_free()
	
				velocity.x = lerp(velocity.x, 0, delta / 2.5)
				shell_sprite.speed_scale = abs(velocity.x) / shell_max_speed
				shell_sprite.flip_h = true if velocity.x < 0 else false
				velocity.y += gravity
				velocity = shell.move_and_slide_with_snap(velocity, snap, Vector2.UP.normalized(), true, 4, deg2rad(46))
		else:
			if is_instance_valid(shell):
				shell_sprite.rotation_degrees += 2
				velocity.y += gravity
				shell.position += velocity * delta
			elif is_instance_valid(body):
				velocity.y += gravity
				body.position += velocity * delta