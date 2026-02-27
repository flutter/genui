#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // x, y resolution
uniform float uTime;     // For animating the ripple phase
uniform float uProgress; // 0.0 to 1.0, controls the overall effect strength
uniform sampler2D uTexture; // The input image

out vec4 fragColor;

void main() {
    vec2 pos = FlutterFragCoord().xy;
    vec2 uv = pos / uSize;
    vec2 center = vec2(0.5, 0.5);
    
    // Aspect ratio correction for circular ripples
    float ratio = uSize.x / uSize.y;
    vec2 uvCorrected = uv;
    uvCorrected.x *= ratio;
    vec2 centerCorrected = center;
    centerCorrected.x *= ratio;

    // --- 1. Multiple Ripples ---
    vec2 toCenter = uvCorrected - centerCorrected;
    float dist = length(toCenter);
    
    // Frequency: How many ripples
    float frequency = 30.0; 
    // Speed: How fast they move outwards
    float speed = 10.0;
    
    // Continuous concentric waves moving outwards
    float wave = sin(dist * frequency - uTime * speed);
    
    // Attenuation: Ripples get weaker further from center
    float attenuation = 1.0 / (1.0 + dist * 2.0);
    
    // Distortion direction
    vec2 dir = vec2(0.0);
    if (dist > 0.001) {
        dir = normalize(toCenter);
    }
    
    // Apply distortion
    // Strength is modulated by uProgress (fade in/out) and attenuation
    float strength = 0.02 * uProgress * attenuation;
    vec2 distortion = dir * wave * strength;
    vec2 distortedUV = uv + distortion;

    // --- 2. Frosted Glass (Blur) ---
    // Increased blur radius for stronger frost
    float blurRadius = 0.025 * uProgress; 
    vec4 blurredColor = vec4(0.0);
    float totalWeight = 0.0;
    
    // 5x5 Sample Grid for smoother, stronger blur
    for (float x = -2.0; x <= 2.0; x++) {
        for (float y = -2.0; y <= 2.0; y++) {
            // Add pseudo-random noise to the offset for a "frosted" texture look
            float noise = fract(sin(dot(uv + vec2(x, y), vec2(12.9898, 78.233))) * 43758.5453);
            
            // Offset with noise influence
            vec2 offset = vec2(x, y) * blurRadius * (0.7 + 0.6 * noise);
            
            // Gaussian-like weight
            float weight = 1.0 / (1.0 + length(vec2(x, y)));
            
            blurredColor += texture(uTexture, distortedUV + offset) * weight;
            totalWeight += weight;
        }
    }
    blurredColor /= totalWeight;

    // --- 3. Final Mix ---
    vec4 originalColor = texture(uTexture, uv);
    
    // Mix based on uProgress
    fragColor = mix(originalColor, blurredColor, uProgress);
}
