shader_type canvas_item;

uniform vec4 base_dark : source_color = vec4(0.004, 0.008, 0.018, 1.0);   // Deep cyber void
uniform vec4 ring_color : source_color = vec4(0.0, 0.85, 1.0, 1.0);      // Cyan ping rings
uniform float ring_speed : hint_range(0.05, 0.4) = 0.14;
uniform int ring_count : hint_range(1, 6) = 3;

void fragment() {
    vec2 uv = UV;
    float dist_center = distance(uv, vec2(0.5));

    // Soft radial gradient with gentle vignette
    vec4 col = mix(base_dark * 1.5, base_dark * 0.7, dist_center);

    // Expanding sonar ping rings from the center
    float rings = 0.0;
    for (int i = 0; i < ring_count; i++) {
        float offset = float(i) / float(ring_count);
        float progress = fract(TIME * ring_speed + offset);
        float radius = progress * 0.7;
        float ring = smoothstep(0.012, 0.0, abs(dist_center - radius));
        ring *= (1.0 - progress); // fade as it expands outward
        rings = max(rings, ring);
    }

    col += ring_color * rings * 0.5;
    COLOR = col;
}
