extends Sprite2D

func _ready():
	# Create a Gradient resource
	var grad := Gradient.new()
	grad.add_point(0.0, Color.WHITE)     # Inside (center)
	grad.add_point(1.0, Color.BLUE)      # Outside (edge)

	# Create a GradientTexture2D
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)    # Center
	tex.fill_to   = Vector2(1.0, 0.5)    # Radius
	tex.repeat = GradientTexture2D.REPEAT_NONE

	# Apply the texture to the Polygon2D
	$Circle.texture = tex
