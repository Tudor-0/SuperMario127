extends Area2D


export var scroll_path: NodePath
onready var scroll: ScrollContainer = get_node(scroll_path)


export var direction: int = -1
export var speed: float = 3.5

var is_hovered: bool


func _ready():
	connect("area_entered", self, "area_entered")
	connect("area_exited", self, "area_exited")


func area_entered(_area: Area2D):
	is_hovered = true


func area_exited(_area: Area2D):
	is_hovered = false


func _physics_process(_delta):
	if not is_visible_in_tree(): return
	if not is_hovered: return
	
	scroll.get_v_scrollbar().value += direction * speed