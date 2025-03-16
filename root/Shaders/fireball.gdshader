shader_type canvas_item;

uniform float time_scale : hint_range(0.0, 10.0) = 1.0;
uniform float noise_scale : hint_range(0.0, 10.0) = 2.0;
uniform float flame_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec4 flame_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform bool flip = false;

// Noise functions
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    // Base UV coordinates with flip handling
    vec2 uv = UV;
    if (!flip) {
        uv.x = 1.0 - uv.x;
    }
    
    // Create circular shape
    vec2 center = vec2(0.5, 0.5);
    float dist = length(uv - center);
    float circle = smoothstep(0.5, 0.4, dist);
    
    // Create animated noise
    float time = TIME * time_scale;
    vec2 noise_uv = uv * noise_scale;
    // Adjust noise movement based on flip
    if (flip) {
        noise_uv.x += time * flame_speed;
    } else {
        noise_uv.x -= time * flame_speed;
    }
    
    // Combine multiple noise layers
    float noise1 = noise(noise_uv);
    float noise2 = noise(noise_uv * 1.5 + vec2(0.5, 0.3));
    float noise3 = noise(noise_uv * 2.0 + vec2(-0.2, -0.5));
    
    // Combine noises with different weights
    float combined_noise = noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2;
    
    // Create flame shape with circular base
    float flame_shape;
    if (flip) {
        flame_shape = uv.x;  // Flame points left when flipped
    } else {
        flame_shape = 1.0 - uv.x;  // Flame points right when not flipped
    }
    flame_shape = pow(flame_shape, 2.0);
    
    // Combine noise with flame shape and circle
    float flame = combined_noise * flame_shape * circle;
    
    // Create color gradient
    vec4 color = mix(flame_color, core_color, flame);
    
    // Add some transparency at the edges
    float alpha = smoothstep(0.0, 0.1, flame);
    color.a = alpha;
    
    COLOR = color;
} 