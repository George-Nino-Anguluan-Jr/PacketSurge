shader_type canvas_item;

uniform float neon_intensity : hint_range(0.0, 2.0) = 1.2;

void fragment() {
    vec4 c = texture(TEXTURE, UV);
    
    // Convert to grayscale for brightness
    float bright = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    
    // Dark areas stay dark (background)
    if (bright < 0.15) {
        COLOR.rgb = mix(c.rgb, vec3(0.02, 0.04, 0.10), 0.8);
        COLOR.a = c.a;
        return;
    }
    
    // For non-dark pixels, shift toward neon palette
    // Detect green/teal pixels (grass, nature)
    float is_green = c.g > c.r * 1.3 && c.g > c.b * 1.2 ? 1.0 : 0.0;
    // Detect warm/brown pixels (paths, roads)
    float is_warm = c.r > c.b * 1.3 && c.g > c.b * 0.7 ? 1.0 : 0.0;
    // Detect bright/beige pixels (UI, highlights)
    float is_bright = bright > 0.6 ? 1.0 : 0.0;
    
    vec3 neon;
    if (is_green > 0.5) {
        // Grass/nature -> dark teal / neon green
        neon = mix(vec3(0.0, 0.3, 0.25), vec3(0.0, 1.0, 0.5), bright * 1.5);
    } else if (is_warm > 0.5) {
        // Paths/roads -> dark blue-gray with cyan edge
        neon = mix(vec3(0.05, 0.08, 0.15), vec3(0.0, 0.8, 1.0), pow(bright, 2.0) * 1.2);
    } else if (is_bright > 0.5) {
        // Bright elements -> magenta/pink glow
        neon = mix(vec3(0.1, 0.0, 0.15), vec3(1.0, 0.2, 0.6), bright);
    } else {
        // Default -> dark with subtle color
        neon = mix(vec3(0.03, 0.03, 0.08), vec3(0.2, 0.5, 0.8), bright * 0.5);
    }
    
    // Apply neon glow on edges (bright areas)
    float glow = pow(bright, 3.0) * neon_intensity;
    neon += vec3(0.0, 0.3, 0.5) * glow * 0.2;
    
    COLOR.rgb = neon;
    COLOR.a = c.a;
}
