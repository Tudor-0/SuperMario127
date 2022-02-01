extends GameObject

class_name Block

var hit_sound_player = AudioStreamPlayer2D.new()

var hit_sound = preload("res://scenes/actors/objects/block/block_hit.wav")

var hit_bounce_enabled : bool = true

func init():
	hit_sound_player.stream = hit_sound
	hit_sound_player.volume_db = 2.5
	add_child(hit_sound_player)

func block_hit(var hit_direction : Vector2):
	hit_sound_player.play()
	if hit_bounce_enabled:
		_start_hit_anim(hit_direction)
	_on_hit()
	
func _on_hit():
	pass
	
func _on_hit_body_entered(body):
	var hit_direction = Vector2(position - body.position).normalized()
	hit_direction = Vector2(clamp(hit_direction.x, -1.0, 1.0), clamp(hit_direction.y, -1.0, 1.0))
	print(Vector2(stepify(hit_direction.x, 1), stepify(hit_direction.y, 1)), body.name)
	if body.name.begins_with("Character"):
		if hit_direction.y <= 0 and (hit_direction.x <= 0.708 and hit_direction.x >= -0.708): #0.708 is the approximate value of a diagonal normal
			block_hit(Vector2.UP)
		elif body.state != null && body.state.name == "GroundPoundEndState" and hit_direction.y >= 0 and (hit_direction.x <= 0.708 and hit_direction.x >= -0.708):
			block_hit(Vector2.DOWN)

	elif body.name.begins_with("Shell"):
		if hit_direction.y >= 0 and (hit_direction.x <= 0.708 and hit_direction.x >= -0.708): #0.708 is the approximate value of a diagonal normal
			block_hit(Vector2(stepify(hit_direction.x, 1), clamp(stepify(hit_direction.y, 1), 0, 1)))
			
func _start_hit_anim(direction):
	pass
	
func _on_hit_area_entered(body):
	var hit_direction = Vector2(position - body.position).normalized()
	hit_direction = Vector2(clamp(hit_direction.x, -1.0, 1.0), clamp(hit_direction.y, -1.0, 1.0))
	if body.name == "SpinSwimArea":
			block_hit(Vector2(stepify(hit_direction.x, 1), stepify(hit_direction.y, 1)))