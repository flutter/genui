#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform vec3 uColor4;

out vec4 fragColor;

void main() {
    vec2 pos = FlutterFragCoord().xy;
    
    // Normalize coordinates to 0.0 - 1.0 range
    vec2 uv = pos / uSize;

    // 2. Animate the "mesh points" using Sine waves
    // We create 4 moving points (blobs) that drift around the screen
    vec2 p1 = vec2(0.5 + 0.4 * sin(uTime * 0.5), 0.5 + 0.4 * cos(uTime * 0.3));
    vec2 p2 = vec2(0.5 + 0.4 * sin(uTime * 0.8 + 2.0), 0.5 + 0.4 * cos(uTime * 0.6 + 1.0));
    vec2 p3 = vec2(0.5 + 0.4 * sin(uTime * 0.4 + 4.0), 0.5 + 0.4 * cos(uTime * 0.5 + 3.0));
    vec2 p4 = vec2(0.5 + 0.4 * sin(uTime * 0.7 + 5.0), 0.5 + 0.4 * cos(uTime * 0.4 + 2.0));

    // 3. Calculate distance from current pixel to each moving point
    // We increase the 'blob' size by dividing by distance (soft glow effect)
    float d1 = distance(uv, p1);
    float d2 = distance(uv, p2);
    float d3 = distance(uv, p3);
    float d4 = distance(uv, p4);

    // 4. Create weighted blend based on proximity
    // The closer a pixel is to a point, the more of that color it gets
    float w1 = 1.0 / (d1 * d1 + 0.1);
    float w2 = 1.0 / (d2 * d2 + 0.1);
    float w3 = 1.0 / (d3 * d3 + 0.1);
    float w4 = 1.0 / (d4 * d4 + 0.1);

    // Normalize weights so they sum to 1.0
    float total = w1 + w2 + w3 + w4;
    vec3 color = (uColor1 * w1 + uColor2 * w2 + uColor3 * w3 + uColor4 * w4) / total;

    // Add a subtle noise/dither to prevent color banding (optional)
    // float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    // color += (noise - 0.5) * 0.02;

    fragColor = vec4(color, 1.0);
}
