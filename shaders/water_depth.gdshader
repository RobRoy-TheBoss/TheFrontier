shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert, specular_schlick_ggx;

// Shallow = clear turquoise, deep = dark opaque blue
uniform vec4 color_shallow : source_color = vec4(0.12, 0.55, 0.65, 0.45);
uniform vec4 color_deep    : source_color = vec4(0.04, 0.18, 0.45, 0.92);

// World units of water depth that maps to fully "deep" colour
uniform float depth_scale : hint_range(0.5, 30.0) = 6.0;

uniform float metallic  : hint_range(0.0, 1.0) = 0.2;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void fragment() {
	// Reconstruct view-space Z of the opaque geometry behind the water surface.
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 clip = vec4(SCREEN_UV * 2.0 - 1.0, raw_depth * 2.0 - 1.0, 1.0);
	vec4 view_behind = INV_PROJECTION_MATRIX * clip;
	view_behind /= view_behind.w;

	// VERTEX.z in fragment() is view-space Z of the water surface (negative).
	// Terrain is farther (more negative), so the difference is positive depth.
	float water_depth = max(VERTEX.z - view_behind.z, 0.0);

	float t = clamp(water_depth / depth_scale, 0.0, 1.0);
	vec4 col = mix(color_shallow, color_deep, t);

	ALBEDO    = col.rgb;
	ALPHA     = col.a;
	METALLIC  = metallic;
	ROUGHNESS = roughness;
}
