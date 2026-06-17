shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;

void fragment() {
    vec2 texel_size = TEXTURE_PIXEL_SIZE * blur_amount;

    vec4 color = vec4(0.0);

    color += texture(TEXTURE, UV + vec2(-texel_size.x, -texel_size.y));
    color += texture(TEXTURE, UV + vec2( 0.0,          -texel_size.y));
    color += texture(TEXTURE, UV + vec2( texel_size.x, -texel_size.y));

    color += texture(TEXTURE, UV + vec2(-texel_size.x, 0.0));
    color += texture(TEXTURE, UV);
    color += texture(TEXTURE, UV + vec2( texel_size.x, 0.0));

    color += texture(TEXTURE, UV + vec2(-texel_size.x, texel_size.y));
    color += texture(TEXTURE, UV + vec2( 0.0,          texel_size.y));
    color += texture(TEXTURE, UV + vec2( texel_size.x, texel_size.y));

    COLOR = color / 9.0;
}