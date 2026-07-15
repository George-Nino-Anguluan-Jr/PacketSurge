shader_type canvas_item;

uniform vec4 base_dark : source_color = vec4(0.003, 0.006, 0.012, 1.0);     // Absolute deep void black/blue (very soothing)
uniform vec4 secondary_dark : source_color = vec4(0.015, 0.024, 0.045, 1.0);  // Deep cyber navy/indigo
uniform vec4 aurora_cyan : source_color = vec4(0.0, 0.55, 0.85, 0.22);       // Rich translucent cyber cyan
uniform vec4 aurora_indigo : source_color = vec4(0.2, 0.1, 0.5, 0.18);       // Rich translucent dark indigo
uniform vec4 line_color : source_color = vec4(0.0, 0.83, 1.0, 0.20);         // Saturated and crisp cyber line connections
uniform float speed_scale : hint_range(0.01, 1.0) = 0.14;                    // Relaxing motion speed
uniform float plexus_scale = 5.5;                                            // Relaxing size for nodes (slightly larger spacing)

// Hash function for random positions and movements
vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453123);
}

// Function to draw a line segment between two points
float draw_line(vec2 p, vec2 a, vec2 b, float thickness) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float d = length(pa - ba * h);
    return smoothstep(thickness, 0.0, d);
}

void fragment() {
    vec2 uv = UV;
    
    // 1. Soothing base dark gradient
    float radial_dist = distance(uv, vec2(0.5, 0.5));
    vec4 final_bg = mix(secondary_dark, base_dark, radial_dist * 1.25);
    
    // 2. Slow-drifting soft auroras (large, blurry background light washes)
    float t = TIME * speed_scale;
    
    vec2 blob1_pos = vec2(0.5 + 0.28 * sin(t * 1.4), 0.5 + 0.20 * cos(t * 0.9));
    float blob1_dist = distance(uv, blob1_pos);
    float blob1_weight = smoothstep(0.6, 0.0, blob1_dist);
    vec4 blob_layer1 = aurora_cyan * blob1_weight;
    
    vec2 blob2_pos = vec2(0.5 - 0.25 * cos(t * 1.0), 0.5 - 0.22 * sin(t * 1.2));
    float blob2_dist = distance(uv, blob2_pos);
    float blob2_weight = smoothstep(0.7, 0.0, blob2_dist);
    vec4 blob_layer2 = aurora_indigo * blob2_weight;

    // 3. Neural Constellation (Plexus) Layer
    // Scale UV for plexus grid cells
    vec2 p_uv = uv * plexus_scale;
    vec2 i_uv = floor(p_uv);
    vec2 f_uv = fract(p_uv);
    
    // Store points in a local array for connections
    // We check a 3x3 block of cells around the current pixel cell
    vec2 points[9];
    int idx = 0;
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 g = vec2(float(x), float(y));
            vec2 cell = i_uv + g;
            vec2 r = hash22(cell);
            
            // Animate points gently inside their respective cells
            vec2 p = g + 0.5 + 0.42 * sin(t * 3.8 + r * 6.2831);
            points[idx] = p;
            idx++;
        }
    }
    
    float lines = 0.0;
    float nodes = 0.0;
    
    // Draw connections and nodes
    for (int i = 0; i < 9; i++) {
        // Draw the point (node) itself with a slightly stronger core glow
        float dist_to_node = length(f_uv - points[i]);
        float node_shape = smoothstep(0.08, 0.0, dist_to_node); // soft-glow node
        nodes += node_shape * 0.55;
        
        // Check connections to other cells
        for (int j = i + 1; j < 9; j++) {
            float d = distance(points[i], points[j]);
            if (d < 1.35) {
                // Connection line fades as nodes get farther apart
                float line_fade = smoothstep(1.35, 0.5, d);
                float line_thickness = 0.018; // slightly wider for crispness
                float segment = draw_line(f_uv, points[i], points[j], line_thickness);
                lines += segment * line_fade;
            }
        }
    }
    
    // Combine line and node strengths with line color
    vec4 plexus_color = line_color * (lines + nodes * 1.8);
    
    // Soft vignette/edge fade to keep screen borders clean and focus in center
    float border_fade = smoothstep(0.0, 0.15, uv.x) * smoothstep(1.0, 0.85, uv.x) *
                        smoothstep(0.0, 0.15, uv.y) * smoothstep(1.0, 0.85, uv.y);
    
    vec4 final_color = final_bg + blob_layer1 + blob_layer2 + (plexus_color * border_fade);
    
    COLOR = final_color;
}
