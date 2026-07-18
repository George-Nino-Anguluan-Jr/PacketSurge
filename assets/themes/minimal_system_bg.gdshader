shader_type canvas_item;

uniform vec4 base_dark : source_color = vec4(0.003, 0.008, 0.018, 1.0);     // Soothing deep cyber void
uniform vec4 grid_color : source_color = vec4(0.0, 0.6, 1.0, 0.05);         // Clean, low-opacity tech grid
uniform vec4 path_color : source_color = vec4(0.0, 0.4, 0.8, 0.12);         // Cyber network defense paths
uniform vec4 tower_color : source_color = vec4(0.0, 0.85, 1.0, 0.35);       // Defense towers / nodes
uniform vec4 packet_color : source_color = vec4(0.0, 1.0, 0.7, 0.6);        // Surging packets (data flows)

uniform float grid_scale : hint_range(5.0, 50.0) = 22.0;

void fragment() {
    vec2 uv = UV;
    
    // 1. Dark base with linear radial gradient for vignette & depth
    float dist_center = distance(uv, vec2(0.5));
    vec4 col = mix(base_dark * 1.5, base_dark * 0.7, dist_center);
    
    // 2. High-performance grid
    vec2 grid_uv = fract(uv * grid_scale);
    float grid_line = step(0.97, grid_uv.x) + step(0.97, grid_uv.y);
    grid_line = clamp(grid_line, 0.0, 1.0);
    col = mix(col, grid_color, grid_line * 0.5);
    
    // 3. Cyber network defense path layout (horizontal and vertical lines)
    // Path 1 (Top horizontal path): y = 0.35
    float path1 = step(0.347, uv.y) * step(uv.y, 0.353) * step(0.15, uv.x) * step(uv.x, 0.85);
    // Path 2 (Bottom horizontal path): y = 0.65
    float path2 = step(0.647, uv.y) * step(uv.y, 0.653) * step(0.15, uv.x) * step(uv.x, 0.85);
    // Link path (Vertical connecting path): x = 0.5
    float path3 = step(0.498, uv.x) * step(uv.x, 0.502) * step(0.35, uv.y) * step(uv.y, 0.65);
    
    float all_paths = clamp(path1 + path2 + path3, 0.0, 1.0);
    col = mix(col, path_color, all_paths);
    
    // 4. Tower defense nodes guarding the intersections / strategic spots
    // Defense Tower A (Left side of Path 1): (0.3, 0.35)
    vec2 tower_a_pos = vec2(0.3, 0.35);
    float dist_to_a = distance(uv, tower_a_pos);
    float outer_ring_a = step(0.024, dist_to_a) * step(dist_to_a, 0.028);
    float inner_core_a = step(dist_to_a, 0.012) * (0.6 + 0.4 * sin(TIME * 4.0));
    
    // Defense Tower B (Right side of Path 2): (0.7, 0.65)
    vec2 tower_b_pos = vec2(0.7, 0.65);
    float dist_to_b = distance(uv, tower_b_pos);
    float outer_ring_b = step(0.024, dist_to_b) * step(dist_to_b, 0.028);
    float inner_core_b = step(dist_to_b, 0.012) * (0.6 + 0.4 * cos(TIME * 4.0));
    
    // Defense Tower C (Center hub connector): (0.5, 0.5)
    vec2 tower_c_pos = vec2(0.5, 0.5);
    float dist_to_c = distance(uv, tower_c_pos);
    float outer_ring_c = step(0.032, dist_to_c) * step(dist_to_c, 0.036);
    float inner_core_c = step(dist_to_c, 0.014) * (0.5 + 0.5 * sin(TIME * 2.5));
    
    float all_towers = clamp(outer_ring_a + inner_core_a + outer_ring_b + inner_core_b + outer_ring_c + inner_core_c, 0.0, 1.0);
    col = mix(col, tower_color, all_towers * 0.95);
    
    // 5. Moving data packets flowing along the network defense grid (surges)
    // Packet 1 moving from left to right on top path
    float p1_progress = fract(TIME * 0.12);
    vec2 p1_pos = vec2(0.15 + p1_progress * 0.7, 0.35);
    float packet1 = step(distance(uv, p1_pos), 0.008);
    
    // Packet 2 moving from right to left on bottom path
    float p2_progress = fract(TIME * 0.10 + 0.5);
    vec2 p2_pos = vec2(0.85 - p2_progress * 0.7, 0.65);
    float packet2 = step(distance(uv, p2_pos), 0.008);
    
    // Packet 3 moving vertically down the connector path
    float p3_progress = fract(TIME * 0.18 + 0.2);
    vec2 p3_pos = vec2(0.5, 0.35 + p3_progress * 0.3);
    float packet3 = step(distance(uv, p3_pos), 0.007);
    
    float all_packets = clamp(packet1 + packet2 + packet3, 0.0, 1.0);
    col += packet_color * all_packets;
    
    // 6. Beautiful tech glow vignette
    float vignette = smoothstep(1.4, 0.4, dist_center);
    COLOR = col * vignette;
}
