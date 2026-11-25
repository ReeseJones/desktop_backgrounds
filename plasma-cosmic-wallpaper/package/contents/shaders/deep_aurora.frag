#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    float uBrightness;
    float uStarDensity;
    float uColorBalance;
    vec2 uResolution;
};

const float PI = 3.14159265359;

mat2 rot2(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    mat2 m = mat2(0.80, 0.60, -0.60, 0.80) * 2.02;
    for (int i = 0; i < 5; ++i) {
        v += amp * vnoise(p);
        p = m * p + vec2(9.2, 23.7);
        amp *= 0.5;
    }
    return v;
}

vec3 starColorFromHash(float h) {
    vec3 coolCyan = vec3(0.46, 0.92, 1.00);
    vec3 iceBlue = vec3(0.75, 0.89, 1.00);
    vec3 pureWhite = vec3(0.95, 0.97, 1.00);
    vec3 softViolet = vec3(0.82, 0.72, 1.00);
    if (h < 0.30) {
        return mix(coolCyan, iceBlue, h / 0.30);
    } else if (h < 0.72) {
        return mix(iceBlue, pureWhite, (h - 0.30) / 0.42);
    }
    return mix(pureWhite, softViolet, (h - 0.72) / 0.28);
}

vec3 starLayer(vec2 uv, float scale, float baseProb, float corePx, float px, float spikeStrength, float time) {
    vec2 sp = uv * scale;
    vec2 id = floor(sp);
    vec2 gv = fract(sp) - 0.5;

    float prob = clamp(baseProb * uStarDensity, 0.0, 0.94);
    vec3 acc = vec3(0.0);

    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offsCell = vec2(float(x), float(y));
            vec2 cid = id + offsCell;
            float existHash = hash12(cid + vec2(29.3, 51.7));
            float exist = smoothstep(1.0 - prob, 1.0 - prob + 0.06, existHash);
            if (exist <= 0.001) {
                continue;
            }

            vec2 rnd = hash22(cid + vec2(11.4, 3.8));
            float lumHash = hash12(cid + vec2(77.9, 19.1));
            float colorHash = hash12(cid + vec2(43.2, 68.5));

            vec2 offset = offsCell + (rnd - 0.5) * 0.72 - gv;
            float distCell = length(offset);
            float boundFade = smoothstep(1.05, 0.65, distCell);
            if (boundFade <= 0.001) {
                continue;
            }

            float dUV = distCell / scale;
            float mag = mix(0.24, 1.38, pow(lumHash, 2.8));
            float coreR = corePx * px * mix(0.65, 1.02, lumHash);
            float haloFactor = smoothstep(0.86, 1.0, lumHash);
            float haloR = px * mix(2.0, 5.4, lumHash);

            float twinkle = 0.84 + 0.16 * sin(time * (0.9 + rnd.x * 2.1) + rnd.y * 2.0 * PI);
            float core = exp(-(dUV * dUV) / max(coreR * coreR, 1e-10));
            float halo = 0.24 * haloFactor * exp(-dUV / max(haloR, 1e-6));

            float spikes = 0.0;
            if (spikeStrength > 0.001 && lumHash > 0.86) {
                vec2 pUV = abs(offset) / scale;
                float spikeAmp = smoothstep(0.86, 0.99, lumHash) * spikeStrength;
                float sx = exp(-pUV.x / max(0.72 * px, 1e-6)) * exp(-pUV.y / max(18.0 * px, 1e-5));
                float sy = exp(-pUV.y / max(0.72 * px, 1e-6)) * exp(-pUV.x / max(18.0 * px, 1e-5));
                spikes = spikeAmp * (sx + sy) * 0.62;
            }

            vec3 scol = starColorFromHash(colorHash);
            acc += scol * (core * 1.15 + halo + spikes) * mag * twinkle * exist * boundFade;
        }
    }
    return acc;
}

vec3 auroraCurtain(
    vec2 p,
    float baseY,
    float slope,
    float amp1,
    float freq1,
    float speed1,
    float phase,
    float curtainHeight,
    float time,
    vec3 edgeColor,
    vec3 midColor,
    vec3 topColor
) {
    // Smooth, sweeping organic fold warping along the curtain spine (silky curves, zero jitter)
    float foldWarp = (fbm(vec2(p.x * 0.95 + time * 0.05 + phase, phase * 2.3)) - 0.5) * 0.14;
    float fineFold = (fbm(vec2(p.x * 1.9 - time * 0.07 + phase * 1.4, phase * 5.7)) - 0.5) * 0.022;

    float wave = amp1 * sin(p.x * freq1 + time * speed1 + phase)
               + (amp1 * 0.42) * cos(p.x * (freq1 * 1.8) - time * (speed1 * 0.7) + phase * 1.5)
               + foldWarp + fineFold;

    float spineY = baseY + slope * p.x + wave;
    // In Qt Quick, smaller y is higher up on screen
    float upDist = spineY - p.y;

    // Crisp luminous ionized plasma arc + subtle soft glow around the rim
    float crispRim = exp(-(upDist * upDist) / 0.000042);
    float softRim = exp(-(upDist * upDist) / 0.00045) * 0.35;

    // Upward-rising translucent silk drapery
    float above = smoothstep(-0.012, 0.007, upDist);
    float heightFade = exp(-max(upDist, 0.0) / max(curtainHeight, 0.03));

    // Silky fine magnetic plasma striations curving slightly upward with the folds
    float rayCoordX = p.x + foldWarp * 1.6 - upDist * 0.12;
    float raysCoarse = fbm(vec2(rayCoordX * 14.0 + time * 0.16 + phase, upDist * 0.75 - time * 0.22));
    float raysFine = fbm(vec2(rayCoordX * 34.0 - time * 0.11 + phase * 2.7, upDist * 1.35 - time * 0.34));
    float rayPattern = smoothstep(0.24, 0.80, raysCoarse * 0.55 + raysFine * 0.45);
    float curtainDensity = mix(0.28, 1.35, rayPattern) * above * heightFade;

    // Natural brightening/fading waves along the length of the ribbon
    float flowWave = smoothstep(0.18, 0.84, fbm(vec2(p.x * 1.9 + time * 0.09 + phase * 3.1, phase)));
    float longitudinal = mix(0.22, 1.0, flowWave) * smoothstep(1.32, 0.52, abs(p.x));

    float hRatio = clamp(max(upDist, 0.0) / max(curtainHeight * 1.65, 0.05), 0.0, 1.0);
    vec3 gradCol = mix(edgeColor, midColor, smoothstep(0.0, 0.35, hRatio));
    gradCol = mix(gradCol, topColor, smoothstep(0.32, 0.96, hRatio));

    vec3 rimCol = edgeColor * (crispRim * (0.55 + 0.75 * rayPattern) + softRim);
    vec3 curtainCol = gradCol * curtainDensity * 0.85;

    return (rimCol + curtainCol) * longitudinal;
}

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
    vec2 res = max(uResolution, vec2(1.0));
    vec2 uv = (qt_TexCoord0 - 0.5) * vec2(res.x / res.y, 1.0);
    float px = 1.0 / max(min(res.x, res.y), 720.0);

    float t = uTime * 0.32;
    float bal = clamp(uColorBalance, -1.0, 1.0);

    // Deep tranquil midnight cosmos gradient
    vec3 skyTop = vec3(0.003, 0.005, 0.018);
    vec3 skyBot = mix(vec3(0.007, 0.016, 0.048), vec3(0.016, 0.012, 0.052), bal * 0.5 + 0.5);
    vec3 col = mix(skyTop, skyBot, smoothstep(-0.55, 0.55, qt_TexCoord0.y - 0.5));

    // Faint diagonal cosmic Milky Way dust veil
    vec2 dustP = rot2(-0.34) * uv * 1.9 + vec2(t * 0.010, -t * 0.006);
    float mist = fbm(dustP + 0.75 * fbm(dustP * 1.7));
    float mistBand = exp(-pow((rot2(-0.34) * uv).y * 2.3, 2.0));
    vec3 mistCol = mix(vec3(0.02, 0.11, 0.36), vec3(0.16, 0.06, 0.38), clamp(0.45 + bal * 0.45, 0.0, 1.0));
    col += mistCol * smoothstep(0.34, 0.84, mist) * mistBand * 0.28;

    // Ultra-crisp 3-layer starfield
    vec2 drift = vec2(t * 0.003, t * 0.001);
    vec3 stars = vec3(0.0);
    stars += starLayer(uv + drift, 46.0, 0.26, 0.80, px, 0.0, uTime) * 0.58;
    stars += starLayer(uv + drift * 1.4 + vec2(5.1, 2.3), 24.0, 0.18, 0.98, px, 0.0, uTime) * 0.88;
    stars += starLayer(uv + drift * 1.9 + vec2(1.7, 7.9), 11.0, 0.13, 1.18, px, 0.62, uTime) * 1.15;
    col += stars;

    // Deep blue / purple / electric cyan aurora palette
    vec3 cyanEdge = mix(vec3(0.04, 0.92, 1.00), vec3(0.24, 0.76, 1.00), clamp(bal * 0.4 + 0.2, 0.0, 1.0));
    vec3 cobaltMid = mix(vec3(0.04, 0.30, 0.92), vec3(0.18, 0.22, 0.86), bal * 0.5 + 0.5);
    vec3 violetTop = mix(vec3(0.18, 0.18, 0.78), vec3(0.58, 0.14, 0.92), clamp(0.58 + bal * 0.42, 0.0, 1.0));
    vec3 amethystEdge = mix(vec3(0.12, 0.66, 1.00), vec3(0.54, 0.30, 0.98), clamp(0.45 + bal * 0.50, 0.0, 1.0));

    // Gently tilted celestial arc frame
    vec2 ap = rot2(-0.22) * uv;

    // 4 layered translucent cosmic plasma aurora curtains
    col += auroraCurtain(
        ap, 0.10, -0.14, 0.085, 2.2, 0.24, 0.4, 0.34, t,
        cyanEdge, cobaltMid, violetTop
    ) * 0.88;

    col += auroraCurtain(
        ap, 0.01, -0.08, 0.075, 2.9, -0.20, 2.2, 0.28, t,
        mix(cyanEdge, amethystEdge, 0.40), mix(cobaltMid, violetTop, 0.45), violetTop
    ) * 0.76;

    col += auroraCurtain(
        ap, 0.23, -0.18, 0.065, 1.9, 0.18, 4.1, 0.26, t,
        amethystEdge, mix(cobaltMid, violetTop, 0.65), violetTop * 0.92
    ) * 0.62;

    col += auroraCurtain(
        ap, -0.09, -0.02, 0.060, 2.6, 0.16, 5.6, 0.24, t,
        cyanEdge * 0.88, cobaltMid * 0.92, violetTop * 0.88
    ) * 0.52;

    // Gentle framing vignette
    float vig = 1.0 - 0.25 * dot(uv * vec2(0.82, 1.0), uv * vec2(0.82, 1.0));
    col *= clamp(vig, 0.68, 1.0);

    col *= clamp(uBrightness, 0.35, 1.85);
    col = aces(col);

    // Sub-LSB triangular dithering
    float dither = (hash12(gl_FragCoord.xy) + hash12(gl_FragCoord.xy + vec2(23.11, 7.91)) - 1.0) * (0.75 / 255.0);
    col = clamp(col + dither, 0.0, 1.0);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
