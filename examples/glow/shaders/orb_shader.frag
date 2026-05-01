#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

// --- Noise Functions ---
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float snoise3(vec3 p) {
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    vec3 e = step(vec3(0.0), d0 - d0.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);
    vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    return dot(vec4(31.316), n);
}

void main() {
    vec2 pos = FlutterFragCoord().xy;
    vec2 uv = (pos - 0.5 * uSize) / min(uSize.x, uSize.y) * 2.0;

    // 1. Polar Coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // 2. The "Galaxy" Twist
    // We modify the angle 'a' based on the radius 'r'.
    // The further out we go, the more we twist the angle.
    // This creates the spiral shape for the coordinate system.
    float twistAmount = 4.0; 
    float rotationSpeed = uTime * 0.4;
    
    // The Twist Calculation:
    // a: Start with base angle
    // + r * twistAmount: Twist more as we get further from center
    // - rotationSpeed: Rotate the whole thing over time
    float spiralAngle = a + (r * twistAmount) - rotationSpeed;

    // 3. Map back to Cartesian to sample noise
    // We use this 'warped' coordinate system to sample the noise.
    // Because the coordinates are twisted, the noise will appear twisted.
    vec2 spiralUV = vec2(cos(spiralAngle), sin(spiralAngle)) * r;

    // 4. Sample Noise
    // We use a lower frequency (1.5) to get "thick" bands like the reference
    float n = snoise3(vec3(spiralUV * 1.5, uTime * 0.2));
    
    // Add a little secondary detail noise
    float nDetail = snoise3(vec3(uv * 3.0, uTime * 0.1));

    // 5. Colors
    vec3 purple = vec3(0.35, 0.20, 0.60); // Darker Deep Purple base
    vec3 orange = vec3(0.98, 0.65, 0.45); // Bright Peachy Orange
    vec3 blue   = vec3(0.50, 0.65, 1.00); // Light Periwinkle Blue

    // Start with Purple
    vec3 color = purple;

    // Add Orange Bands
    // We use smoothstep to create distinct "ribbons" rather than a blurry mix
    float orangeMix = smoothstep(0.1, 0.4, n); 
    color = mix(color, orange, orangeMix);

    // Add Blue Highlights
    // These appear in the "negative" space of the noise
    float blueMix = smoothstep(-0.3, -0.05, n);
    color = mix(color, blue, blueMix * 0.8);

    // 6. Center Glow
    // Add a strong white/orange hot core
    float coreGlow = 1.0 - smoothstep(0.0, 0.35, r);
    color += vec3(1.0, 0.8, 0.6) * coreGlow * 0.9;

    // 7. Circle Mask & Premultiplied Alpha
    float alpha = 1.0 - smoothstep(0.9, 1.0, r);
    
    fragColor = vec4(color * alpha, alpha);
}