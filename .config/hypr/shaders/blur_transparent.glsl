// Hypr-DarkWindow compatible blur-transparent shader

vec4 fragment(vec4 inputColor, sampler2D tex, vec2 uv, float opacity, float blurStrength) {
    vec2 resolution = vec2(textureSize(tex, 0));
    vec2 pixel = 1.0 / resolution;
    vec4 color = vec4(0.0);

    // Simple 3x3 blur kernel
    for (float x = -1.0; x <= 1.0; x++) {
        for (float y = -1.0; y <= 1.0; y++) {
            color += texture(tex, uv + vec2(x, y) * pixel * blurStrength);
        }
    }

    color /= 9.0;

    // Apply transparency
    color.a *= opacity;

    return color;
}

