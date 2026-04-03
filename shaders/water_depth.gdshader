shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert, specular_schlick_ggx;

// Three-stop depth gradient: shallow → mid → deep
uniform vec4 color_shallow : source_color = vec4(0.12, 0.55, 0.65, 0.2);
uniform vec4 color_mid     : source_color = vec4(0.08, 0.35, 0.55, 0.6);
uniform vec4 color_deep    : source_color = vec4(0.04, 0.18, 0.45, 0.92);

// Depth (world metres) at which each transition completes
uniform float depth_mid  : hint_range(0.1, 10.0) = 1.0;
uniform float depth_deep : hint_range(0.1, 10.0) = 2.0;

uniform float metallic  : hint_range(0.0, 1.0) = 0.2;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void fragment() {
	// Reconstruct view-space Z of the opaque geometry behind the water surface.
	// Godot 4 Forward+ (Vulkan): depth NDC z is [0,1] — no * 2.0 - 1.0 remapping on z.
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 clip = vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	vec4 view_behind = INV_PROJECTION_MATRIX * clip;
	view_behind /= view_behind.w;

	// Convert both to world space and compare Y — gives true vertical depth
	// regardless of viewing angle, so distant water looks the same as close water.
	vec4 world_behind = INV_VIEW_MATRIX * view_behind;
	vec4 world_surface = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	float water_depth = max(world_surface.y - world_behind.y, 0.0);

	float t1 = clamp(water_depth / depth_mid, 0.0, 1.0);
	float t2 = clamp((water_depth - depth_mid) / (depth_deep - depth_mid), 0.0, 1.0);
	vec4 col = mix(mix(color_shallow, color_mid, t1), color_deep, t2);

	ALBEDO    = col.rgb;
	ALPHA     = col.a;
	METALLIC  = metallic;
	ROUGHNESS = roughness;
}
