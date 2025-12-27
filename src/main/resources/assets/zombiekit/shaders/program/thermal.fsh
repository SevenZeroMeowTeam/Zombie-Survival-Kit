#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D ThermalSampler;

in vec2 texCoord;
out vec4 fragColor;

// 简单伪随机函数
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// 计算亮度
float luma(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec4 sceneColor = texture(DiffuseSampler, texCoord);
    vec4 thermalColor = textureLod(ThermalSampler, texCoord, 0.0);

    // 背景处理
    float sceneLuma = luma(sceneColor.rgb);
    vec3 bgDeep = vec3(0.0); // 黑
    vec3 bgMid  = vec3(0.3); // 深灰
    vec3 bgHigh = vec3(0.7); // 浅灰
    vec3 bgColor = mix(bgDeep, bgMid, smoothstep(0.0, 0.4, sceneLuma));
    bgColor = mix(bgColor, bgHigh, smoothstep(0.4, 1.0, sceneLuma));

    float noise = random(texCoord * 100.0);
    bgColor += (noise - 0.5) * 0.05;

    vec2 uv = texCoord * (1.0 - texCoord.yx);
    float vig = uv.x * uv.y * 15.0;
    vig = pow(vig, 0.25);
    bgColor *= vig;

    vec3 finalColor = bgColor;

    // 环境热源处理
    float warmth = sceneColor.r - max(sceneColor.g, sceneColor.b);
    float brightHeat = smoothstep(0.92, 1.0, sceneLuma);
    float warmHeat = smoothstep(0.5, 0.9, sceneLuma) * smoothstep(0.05, 0.4, warmth);
    float envHeat = max(brightHeat, warmHeat);

    if (envHeat > 0.01) {
        vec3 envColor = mix(vec3(0.3), vec3(1.0), envHeat); // 灰->白
        finalColor = mix(finalColor, envColor, clamp(envHeat + 0.4, 0.0, 1.0));
    }

    // 实体热源处理
    bool isEntityHot = thermalColor.a > 0.01 || dot(thermalColor.rgb, vec3(1.0)) > 0.01;
    if (isEntityHot) {
        float texLuma = luma(thermalColor.rgb);
        float heat = 0.4 + 0.6 * texLuma;
        heat = pow(heat, 0.8);

        vec3 colCold = vec3(0.3);
        vec3 colMid  = vec3(0.6);
        vec3 colHot  = vec3(1.0);

        vec3 objectColor;
        if (heat < 0.5) {
            objectColor = mix(colCold, colMid, heat * 2.0);
        } else {
            objectColor = mix(colMid, colHot, (heat - 0.5) * 2.0);
        }

        finalColor = objectColor;
    }

    fragColor = vec4(finalColor, 1.0);
}
