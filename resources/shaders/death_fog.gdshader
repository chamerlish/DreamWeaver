shader_type spatial;

uniform vec3 top_color : source_color = vec3(0.4, 0.4, 0.4);
uniform vec3 bottom_color : source_color = vec3(0.0, 0.0, 0.0);

varying float height_factor;

void vertex() {
	// local space height (works on meshes like cylinders/cones)
	height_factor = VERTEX.y;
}

void fragment() {
	// NON-linear curve (important for fog feel)
	float t = pow(clamp(height_factor * 0.2, 0.0, 1.0), 2.2);

	ALBEDO = mix(bottom_color, top_color, t);
}