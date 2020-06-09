extends Control

onready var label = $Label
onready var label_shadow = $LabelShadow
onready var tween = $Tween

var last_coin_amount := 0

export var collected_height : float
var normal_height : float

var time_until_fall = 0.0

func _ready():
	normal_height = label.rect_position.y

func _process(delta):
	var coin_amount = CurrentLevelData.level_data.vars.coins_collected
	if coin_amount != last_coin_amount:
		label.text = str(coin_amount).pad_zeros(2)
		label_shadow.text = label.text
		
		tween.interpolate_property(label, "rect_position",
			label.rect_position, Vector2(label.rect_position.x, collected_height), 0.075,
			Tween.TRANS_CIRC, Tween.EASE_OUT)
		tween.start()
		time_until_fall = 0.1
	last_coin_amount = coin_amount
	
	label_shadow.rect_position = label.rect_position + Vector2(3, 4)

	if time_until_fall > 0:
		time_until_fall -= delta
		if time_until_fall <= 0:
			time_until_fall = 0
			tween.interpolate_property(label, "rect_position",
				label.rect_position, Vector2(label.rect_position.x, normal_height), 0.15,
				Tween.TRANS_BOUNCE, Tween.EASE_IN)
			tween.start()