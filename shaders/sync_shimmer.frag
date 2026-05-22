#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float shimmer = sin(uv.x * 10.0 + uTime * 5.0) * 0.5 + 0.5;
    fragColor = vec4(1.0, 1.0, 1.0, shimmer * 0.3);
}
