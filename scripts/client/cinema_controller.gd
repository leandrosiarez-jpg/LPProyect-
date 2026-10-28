extends CanvasLayer
## Grading de color de la imagen ("GummyGrade"). Solo afecta al mundo, no a la UI.

const GRADE := {
	"saturation": -0.22,
	"contrast": 0.12,
	"brightness": -0.02,
	"tint": Color8(255, 236, 218),
}

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float saturation = 0.0;
uniform float contrast = 0.0;
uniform float brightness = 0.0;
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	c = c * tint.rgb + brightness;
	c = (c - 0.5) * (1.0 + contrast) + 0.5;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, 1.0 + saturation);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""

var _mat: ShaderMaterial


func _ready() -> void:
	layer = 1
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	for k in GRADE:
		_mat.set_shader_parameter(k, GRADE[k])
	rect.material = _mat
	add_child(rect)


## Equivale a tweenear grade.Saturation (p. ej. -0.5 al morir).
func set_saturation(value: float, seconds: float = 1.0) -> void:
	var tw := create_tween()
	tw.tween_method(func(v): _mat.set_shader_parameter("saturation", v),
		float(_mat.get_shader_parameter("saturation")), value, seconds)
