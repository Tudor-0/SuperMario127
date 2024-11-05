extends Node2D

onready var parent = get_parent()

onready var label = $Dialogue/RichTextLabel
onready var animation_player = $AnimationPlayer
onready var message_appear = $"%MessageAppear"
onready var message_disappear = $"%MessageDisappear"

var is_shown: bool


func _ready():
	assert("bubble_text" in parent, "Improper use of Bubble prefab! Must have a bubble_text variable")


func body_entered(body):
	if is_visible_in_tree() and body is Character:
		set_text(text_replace_util.parse_text(parent.bubble_text, body))
		appear()


func body_exited(body):
	if is_visible_in_tree() and body is Character:
		disappear()


func set_text(text: String):
	label.bbcode_text = "[center]" + text + "[/center]"
	label.call_deferred("update_sizing")


func appear():
	if is_shown: return
	is_shown = true
	
	animation_player.play_backwards("transition")
	if is_visible_in_tree():
		message_appear.play()


func disappear():
	if not is_shown: return
	is_shown = false
	
	animation_player.play("transition")
	if is_visible_in_tree():
		message_disappear.play()