shader_type canvas_item;

uniform bool foil_enabled = false;
uniform float foil_strength : hint_range(0.0, 2.0) = 0.65;
uniform float gold_strength : hint_range(0.0, 2.0) = 0.55;
uniform float rainbow_strength : hint_range(0.0, 2.0) = 0.45;
uniform float shine_strength : hint_range(0.0, 3.0) = 1.1;
uniform float shine_width : hint_range(0.01, 0.5) = 0.10;
uniform float shine_speed : hint_range(0.0, 5.0) = 0.8;
uniform float rainbow_scale : hint_range(1.0, 30.0) = 12.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.15;



vec3 rainbow(float t) {
    return vec3(
        0.5 + 0.5 * sin(6.28318 * (t + 0.00)),
        0.5 + 0.5 * sin(6.28318 * (t + 0.33)),
        0.5 + 0.5 * sin(6.28318 * (t + 0.66))
    );
}

vec3 overlay_blend(vec3 base, vec3 blend) {
    vec3 result;
    result.r = (base.r < 0.5) ? (2.0 * base.r * blend.r) : (1.0 - 2.0 * (1.0 - base.r) * (1.0 - blend.r));
    result.g = (base.g < 0.5) ? (2.0 * base.g * blend.g) : (1.0 - 2.0 * (1.0 - base.g) * (1.0 - blend.g));
    result.b = (base.b < 0.5) ? (2.0 * base.b * blend.b) : (1.0 - 2.0 * (1.0 - base.b) * (1.0 - blend.b));
    return clamp(result, 0.0, 1.0);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (tex.a <= 0.01) {
        discard;
    }
    if (!foil_enabled) {
        COLOR = tex;
      } else {
    
    vec3 base = tex.rgb;

    float diagonal = UV.x + UV.y;

    float wave1 = sin(diagonal * rainbow_scale + TIME * shine_speed);
    float wave2 = sin(UV.x * 18.0 - TIME * 1.2);
    float wave3 = sin(UV.y * 16.0 + TIME * 0.9);

    float shimmer = (wave1 * 0.5 + 0.5);
    shimmer += (wave2 * 0.5 + 0.5) * 0.25;
    shimmer += (wave3 * 0.5 + 0.5) * 0.25;
    shimmer /= 1.5;

    float grain = hash(UV * 120.0 + TIME * 0.25);
    shimmer += (grain - 0.5) * noise_strength;
    shimmer = clamp(shimmer, 0.0, 1.0);

    vec3 gold_color = vec3(1.0, 0.84, 0.25);
    vec3 rainbow_color = rainbow(diagonal * 0.5 + TIME * 0.12);

    vec3 foil_color = mix(gold_color, rainbow_color, rainbow_strength);
    vec3 overlay_color = mix(gold_color, foil_color, shimmer);

    vec3 overlaid = overlay_blend(base, overlay_color);
    vec3 final_color = mix(base, overlaid, foil_strength);

    float shine_pos = fract(TIME * shine_speed);
    float shine_line = abs(diagonal - shine_pos * 2.0);
    shine_line = min(shine_line, abs(diagonal - (shine_pos * 2.0 - 2.0)));
    float shine = smoothstep(shine_width, 0.0, shine_line);

    final_color += shine * shine_strength * vec3(1.0, 0.95, 0.75);

    final_color = mix(final_color, overlay_blend(final_color, gold_color), gold_strength * 0.25);

    COLOR = vec4(clamp(final_color, 0.0, 1.0), tex.a);
 }
}