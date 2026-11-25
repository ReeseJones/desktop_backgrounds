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
    vec4 uColorBg;
    vec4 uColorPrimary;
    vec4 uColorSecondary;
    vec4 uColorAccent;
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
    for (int i = 0; i < 6; ++i) {
        v += amp * vnoise(p);
        p = m * p + vec2(13.7, 29.3);
        amp *= 0.5;
    }
    return v;
}

float ridgedFbm(vec2 p) {
    float v = 0.0;
    float amp = 0.55;
    float weight = 1.0;
    mat2 m = mat2(0.80, -0.60, 0.60, 0.80) * 2.06;
    for (int i = 0; i < 5; ++i) {
        float n = 1.0 - abs(2.0 * vnoise(p) - 1.0);
        n = n * n * weight;
        weight = clamp(n * 1.45, 0.15, 1.0);
        v += n * amp;
        p = m * p + vec2(7.1, 19.4);
        amp *= 0.48;
    }
    return v;
}

vec3 starColorFromHash(float h, vec3 accentCol, vec3 secondaryCol) {
    vec3 coolAccent = mix(vec3(0.86, 0.94, 1.00), clamp(accentCol, 0.0, 1.0), 0.55);
    vec3 iceNeutral = mix(vec3(0.84, 0.90, 1.00), coolAccent, 0.35);
    vec3 pureWhite = vec3(0.96, 0.97, 1.00);
    vec3 softSecondary = mix(vec3(0.90, 0.86, 1.00), clamp(secondaryCol, 0.0, 1.0), 0.40);
    if (h < 0.30) {
        return mix(coolAccent, iceNeutral, h / 0.30);
    } else if (h < 0.72) {
        return mix(iceNeutral, pureWhite, (h - 0.30) / 0.42);
    }
    return mix(pureWhite, softSecondary, (h - 0.72) / 0.28);
}

vec3 starLayer(vec2 uv, float scale, float baseProb, float corePx, float px, float spikeStrength, float time, vec3 accentCol, vec3 secondaryCol) {
    vec2 sp = uv * scale;
    vec2 id = floor(sp);
    vec2 gv = fract(sp) - 0.5;

    float prob = clamp(baseProb * uStarDensity, 0.0, 0.94);
    vec3 acc = vec3(0.0);

    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offsCell = vec2(float(x), float(y));
            vec2 cid = id + offsCell;
            float existHash = hash12(cid + vec2(41.7, 17.3));
            float exist = smoothstep(1.0 - prob, 1.0 - prob + 0.06, existHash);
            if (exist <= 0.001) {
                continue;
            }

            vec2 rnd = hash22(cid + vec2(5.1, 9.8));
            float lumHash = hash12(cid + vec2(83.2, 11.4));
            float colorHash = hash12(cid + vec2(27.9, 64.1));

            vec2 offset = offsCell + (rnd - 0.5) * 0.70 - gv;
            float distCell = length(offset);
            float boundFade = smoothstep(1.05, 0.65, distCell);
            if (boundFade <= 0.001) {
                continue;
            }

            float dUV = distCell / scale;
            float mag = mix(0.24, 1.35, pow(lumHash, 2.8));
            float coreR = corePx * px * mix(0.65, 1.05, lumHash);
            float haloFactor = smoothstep(0.82, 1.0, lumHash);
            float haloR = px * mix(2.2, 6.2, lumHash);

            float twinkle = 0.84 + 0.16 * sin(time * (1.1 + rnd.x * 2.4) + rnd.y * 2.0 * PI);
            float core = exp(-(dUV * dUV) / max(coreR * coreR, 1e-10));
            float halo = 0.28 * haloFactor * exp(-dUV / max(haloR, 1e-6));

            float spikes = 0.0;
            if (spikeStrength > 0.001 && lumHash > 0.84) {
                vec2 pUV = abs(offset) / scale;
                float spikeAmp = smoothstep(0.84, 0.99, lumHash) * spikeStrength;
                float sx = exp(-pUV.x / max(0.75 * px, 1e-6)) * exp(-pUV.y / max(18.0 * px, 1e-5));
                float sy = exp(-pUV.y / max(0.75 * px, 1e-6)) * exp(-pUV.x / max(18.0 * px, 1e-5));
                spikes = spikeAmp * (sx + sy) * 0.65;
            }

            vec3 scol = starColorFromHash(colorHash, accentCol, secondaryCol);
            acc += scol * (core * 1.15 + halo + spikes) * mag * twinkle * exist * boundFade;
        }
    }
    return acc;
}

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
    vec2 res = max(uResolution, vec2(1.0));
    vec2 uv = (qt_TexCoord0 - 0.5) * vec2(res.x / res.y, 1.0);
    float px = 1.0 / max(min(res.x, res.y), 720.0);

    float t = uTime * 0.042;
    float bal = clamp(uColorBalance, -1.0, 1.0);

    vec3 bgCol = pow(max(clamp(uColorBg.rgb, 0.0, 1.0), vec3(1e-4)), vec3(1.6)) * 0.85;
    vec3 primaryCol = pow(max(clamp(uColorPrimary.rgb, 0.0, 1.0), vec3(1e-4)), vec3(1.25));
    vec3 secondaryCol = pow(max(clamp(uColorSecondary.rgb, 0.0, 1.0), vec3(1e-4)), vec3(1.25));
    vec3 accentCol = pow(max(clamp(uColorAccent.rgb, 0.0, 1.0), vec3(1e-4)), vec3(1.25));

    // Subtle deep-space backdrop gradient
    vec3 col = mix(bgCol * 0.45, bgCol * 1.15 + primaryCol * 0.03,
                   smoothstep(-0.7, 0.7, uv.y - uv.x * 0.25));

    // Align and gently curve the main cosmic nebula corridor diagonally
    vec2 np = rot2(-0.42) * uv;
    float spine = 0.14 * sin(np.x * 1.9 + t * 0.35) + 0.06 * cos(np.x * 3.6 - t * 0.2);
    float bandDist = abs(np.y - spine);
    float corridor = exp(-bandDist * bandDist * 4.4);
    float broadAura = exp(-bandDist * bandDist * 1.25);

    // Double domain-warped volumetric nebula clouds
    vec2 p = np * 2.15 + vec2(t * 0.18, -t * 0.08);
    vec2 q = vec2(
        fbm(p + vec2(0.0, 0.0) + vec2(t * 0.22, -t * 0.15)),
        fbm(p + vec2(5.2, 1.3) + vec2(-t * 0.16, t * 0.20))
    );
    vec2 r = vec2(
        fbm(p + 2.05 * q + vec2(1.7, 9.2) + vec2(t * 0.18, t * 0.10)),
        fbm(p + 2.05 * q + vec2(8.3, 2.8) + vec2(-t * 0.12, -t * 0.19))
    );

    float cloudBase = fbm(p + 1.85 * r);
    float cloudDetail = fbm(p * 1.9 + 2.4 * r - vec2(t * 0.14, 0.0));
    float dustNoise = fbm(p * 2.35 - 1.5 * q + vec2(4.1, 7.3));

    float density = smoothstep(0.24, 0.84, cloudBase * 0.72 + cloudDetail * 0.36);
    float cloudBody = density * mix(0.22, 1.0, corridor) + broadAura * 0.16 * cloudBase;

    // Dark cosmic dust lanes for volumetric depth and high-contrast structure
    float dustRidge = 1.0 - abs(2.0 * dustNoise - 1.0);
    float dustMask = smoothstep(0.50, 0.88, dustRidge) * corridor;

    // Fine sinuous ionized plasma filaments along warped coordinates
    float filRaw = ridgedFbm(p * 1.55 + 1.45 * r + vec2(0.0, t * 0.12));
    float plasmaFilaments = pow(clamp(filRaw * 0.92, 0.0, 1.0), 3.6) * (0.28 + 0.85 * corridor);
    float hotVeins = pow(clamp(filRaw * 0.96, 0.0, 1.0), 7.5) * corridor;

    // Color palette controlled smoothly by the 4 base colors + uColorBalance (-1 primary/accent .. +1 secondary)
    vec3 deepSapphire = mix(primaryCol, secondaryCol, clamp(bal * 0.35 + 0.15, 0.0, 1.0)) * 0.85;
    vec3 royalViolet = mix(primaryCol * 0.65 + secondaryCol * 0.35, secondaryCol, clamp(0.65 + bal * 0.35, 0.0, 1.0));
    vec3 electricCyan = mix(accentCol, mix(accentCol, primaryCol, 0.35), clamp(bal * 0.35 + 0.15, 0.0, 1.0));
    vec3 amethystGlow = mix(mix(primaryCol, accentCol, 0.45), mix(secondaryCol, vec3(1.0), 0.18), clamp(0.5 + bal * 0.5, 0.0, 1.0));
    vec3 hotCore = mix(accentCol, vec3(0.95, 0.97, 1.0), 0.45);

    float colorWave = smoothstep(0.28, 0.76, q.x * 0.65 + r.y * 0.35);
    vec3 nebulaGas = mix(deepSapphire, royalViolet, clamp(colorWave + bal * 0.26, 0.0, 1.0));
    nebulaGas = mix(nebulaGas, electricCyan * 0.68, smoothstep(0.60, 0.90, cloudDetail) * 0.48 * (1.0 - max(bal, 0.0) * 0.45));

    col += nebulaGas * cloudBody * 0.86;
    col *= 1.0 - 0.60 * dustMask;

    // Luminous ionized plasma arcs & glowing filament cores
    vec3 filamentTint = mix(electricCyan, amethystGlow, clamp(0.28 + r.x * 0.45 + bal * 0.30, 0.0, 1.0));
    col += filamentTint * plasmaFilaments * 1.18;
    col += mix(hotCore, mix(secondaryCol, vec3(1.0), 0.45), clamp(0.25 + bal * 0.30, 0.0, 1.0)) * hotVeins * 1.35;

    // Subtle soft ambient nebula core bloom
    col += mix(deepSapphire, electricCyan, 0.35) * broadAura * 0.085;

    // Multi-layer crisp parallax starfield
    vec2 drift1 = vec2(t * 0.014, t * 0.005);
    vec2 drift2 = vec2(t * 0.024, t * 0.008);
    vec2 drift3 = vec2(t * 0.036, t * 0.012);

    vec3 stars = vec3(0.0);
    stars += starLayer(uv + drift1, 44.0, 0.25, 0.82, px, 0.0, uTime, accentCol, secondaryCol) * 0.55;
    stars += starLayer(uv + drift2 + vec2(3.7, 1.9), 23.0, 0.18, 1.02, px, 0.0, uTime, accentCol, secondaryCol) * 0.85;
    stars += starLayer(uv + drift3 + vec2(8.1, 4.3), 10.5, 0.13, 1.25, px, 0.65, uTime, accentCol, secondaryCol) * 1.15;

    // Slight dust extinction on far background stars inside dense dark dust lanes
    col += stars * (1.0 - 0.40 * dustMask);

    // Gentle edge vignette to keep desktop framing deep and calm
    float vig = 1.0 - 0.26 * dot(uv * vec2(0.82, 1.0), uv * vec2(0.82, 1.0));
    col *= clamp(vig, 0.68, 1.0);

    col *= clamp(uBrightness, 0.35, 1.85);
    col = aces(col);

    // Sub-LSB triangular dithering to eliminate dark gradient banding
    float dither = (hash12(gl_FragCoord.xy) + hash12(gl_FragCoord.xy + vec2(17.13, 31.71)) - 1.0) * (0.75 / 255.0);
    col = clamp(col + dither, 0.0, 1.0);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
