#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uColor;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float dist = distance(uv, vec2(0.5, 0.5));
    float glow = 1.0 - smoothstep(0.0, 0.5, dist);
    float pulse = 0.8 + 0.2 * sin(uTime * 2.0);
    fragColor = uColor * glow * pulse;
}
