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
    vec2 uOffset;
};

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

mat2 rot2(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

// "Hash without Sine" by Dave Hoskins (MIT License)
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
    mat2 m = mat2(0.80, 0.60, -0.60, 0.80) * 2.03;
    for (int i = 0; i < 6; ++i) {
        v += amp * vnoise(p);
        p = m * p + vec2(11.3, 27.9);
        amp *= 0.5;
    }
    return v;
}

float fbm4(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    mat2 m = mat2(0.80, 0.60, -0.60, 0.80) * 2.03;
    for (int i = 0; i < 4; ++i) {
        v += amp * vnoise(p);
        p = m * p + vec2(11.3, 27.9);
        amp *= 0.5;
    }
    return v / 0.9375;
}

float ridgedFbm3(vec2 p) {
    float v = 0.0;
    float amp = 0.55;
    mat2 m = mat2(0.80, -0.60, 0.60, 0.80) * 2.05;
    for (int i = 0; i < 3; ++i) {
        float n = 1.0 - abs(2.0 * vnoise(p) - 1.0);
        v += n * n * amp;
        p = m * p + vec2(5.7, 17.1);
        amp *= 0.48;
    }
    return v;
}

// Interleaved Gradient Noise by Jorge Jimenez (for banding-free TPDF dithering)
float interleavedGradientNoise(vec2 p) {
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

vec3 starColorFromHash(float h, vec3 accentCol, vec3 secondaryCol) {
    vec3 coolAccent = mix(vec3(0.86, 0.94, 1.00), clamp(accentCol, 0.0, 1.0), 0.55);
    vec3 iceNeutral = mix(vec3(0.84, 0.90, 1.00), coolAccent, 0.35);
    vec3 pureWhite = vec3(0.96, 0.97, 1.00);
    vec3 softSecondary = mix(vec3(0.90, 0.86, 1.00), clamp(secondaryCol, 0.0, 1.0), 0.40);
    if (h < 0.32) {
        return mix(coolAccent, iceNeutral, h / 0.32);
    } else if (h < 0.74) {
        return mix(iceNeutral, pureWhite, (h - 0.32) / 0.42);
    }
    return mix(pureWhite, softSecondary, (h - 0.74) / 0.26);
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
            float existHash = hash12(cid + vec2(37.1, 23.7));
            float exist = smoothstep(1.0 - prob, 1.0 - prob + 0.06, existHash);
            if (exist <= 0.001) {
                continue;
            }

            vec2 rnd = hash22(cid + vec2(7.3, 4.9));
            float lumHash = hash12(cid + vec2(91.4, 15.2));
            float colorHash = hash12(cid + vec2(19.6, 58.3));

            vec2 offset = offsCell + (rnd - 0.5) * 0.70 - gv;
            float distCell = length(offset);
            float boundFade = smoothstep(1.05, 0.65, distCell);
            if (boundFade <= 0.001) {
                continue;
            }

            float dUV = distCell / scale;
            float mag = mix(0.24, 1.32, pow(lumHash, 2.8));
            float coreR = corePx * px * mix(0.65, 1.05, lumHash);
            float haloFactor = smoothstep(0.84, 1.0, lumHash);
            float haloR = px * mix(2.2, 5.8, lumHash);

            float twinkle = 0.85 + 0.15 * sin(time * (1.2 + rnd.x * 2.3) + rnd.y * 2.0 * PI);
            float core = exp(-(dUV * dUV) / max(coreR * coreR, 1e-10));
            float halo = 0.25 * haloFactor * exp(-dUV / max(haloR, 1e-6));

            float spikes = 0.0;
            if (spikeStrength > 0.001 && lumHash > 0.85) {
                vec2 pUV = abs(offset) / scale;
                float spikeAmp = smoothstep(0.85, 0.99, lumHash) * spikeStrength;
                float sx = exp(-pUV.x / max(0.75 * px, 1e-6)) * exp(-pUV.y / max(17.0 * px, 1e-5));
                float sy = exp(-pUV.y / max(0.75 * px, 1e-6)) * exp(-pUV.x / max(17.0 * px, 1e-5));
                spikes = spikeAmp * (sx + sy) * 0.60;
            }

            vec3 scol = starColorFromHash(colorHash, accentCol, secondaryCol);
            acc += scol * (core * 1.15 + halo + spikes) * mag * twinkle * exist * boundFade;
        }
    }
    return acc;
}

// Analytical ACES filmic tone-mapping fit by Krzysztof Narkowicz
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
    vec2 res = max(uResolution, vec2(1.0));
    vec2 aspect = vec2(res.x / res.y, 1.0);
    vec2 screenUv = (qt_TexCoord0 - 0.5) * aspect;
    vec2 offsetClamped = clamp(uOffset, vec2(-1.5), vec2(1.5));
    vec2 uv = ((qt_TexCoord0 - 0.5) - vec2(offsetClamped.x, -offsetClamped.y) * 0.5) * aspect;
    float px = 1.0 / max(min(res.x, res.y), 720.0);

    float t = uTime * 0.28;
    float bal = clamp(uColorBalance, -1.0, 1.0);

    // Subtle global tilt for cinematic diagonal framing
    vec2 tiltUV = rot2(0.22) * uv;
    float rScreen = length(tiltUV);

    float rShadow = 0.165;
    float rPhoton = rShadow * 1.045;

    vec3 bgCol = clamp(uColorBg.rgb, 0.0, 1.0);
    vec3 primaryCol = pow(max(clamp(uColorPrimary.rgb, 0.0, 1.0), vec3(1e-4)), vec3(1.25));
    vec3 secondaryCol = pow(max(clamp(uColorSecondary.rgb, 0.0, 1.0), vec3(1e-4)), vec3(1.25));
    vec3 accentCol = pow(max(clamp(uColorAccent.rgb, 0.0, 1.0), vec3(1e-4)), vec3(1.25));

    // Color palette derived from the 4 shared base colors + uColorBalance
    vec3 deepVoid = bgCol;
    vec3 sapphireCol = mix(primaryCol, mix(primaryCol, secondaryCol, 0.35), bal * 0.5 + 0.5);
    vec3 violetCol = mix(mix(primaryCol, secondaryCol, 0.5), secondaryCol, clamp(0.60 + bal * 0.40, 0.0, 1.0));
    vec3 cyanPlasma = mix(accentCol, mix(accentCol, primaryCol, 0.28), clamp(bal * 0.35 + 0.15, 0.0, 1.0));
    vec3 hotCore = mix(mix(accentCol, vec3(0.95, 0.97, 1.0), 0.52), mix(secondaryCol, vec3(0.95, 0.97, 1.0), 0.52), clamp(0.22 + bal * 0.25, 0.0, 1.0));

    // Distant cosmic nebula mist surrounding the gravity well (Cartesian swirl, seam-free)
    float outerAngle = mod(t * 0.09, TWO_PI) + 0.65 / (rScreen + 0.35);
    vec2 outerSwirl = rot2(outerAngle) * tiltUV;
    float bgMist = fbm(outerSwirl * 2.6 + vec2(t * 0.04, -t * 0.03));
    float bgVeil = smoothstep(0.32, 0.86, bgMist) * exp(-rScreen * 0.95) * smoothstep(rShadow, rShadow + 0.28, rScreen);
    vec3 col = mix(deepVoid * 0.78, deepVoid * 1.18, smoothstep(-0.6, 0.6, screenUv.y))
             + mix(sapphireCol, violetCol, clamp(0.45 + bal * 0.35, 0.0, 1.0)) * bgVeil * 0.34;

    // Gravitationally deflected background starfield, masked cleanly inside the event horizon
    float starMask = smoothstep(rShadow + 0.004, rShadow + 0.024, rScreen);
    vec2 starUV = uv * (1.0 - 0.012 / max(rScreen * rScreen, 0.038));
    vec3 stars = vec3(0.0);
    stars += starLayer(starUV + vec2(t * 0.004, 0.0), 44.0, 0.24, 0.82, px, 0.0, uTime, accentCol, secondaryCol) * 0.55;
    stars += starLayer(starUV + vec2(4.2, 1.7), 23.0, 0.17, 1.00, px, 0.0, uTime, accentCol, secondaryCol) * 0.85;
    stars += starLayer(starUV + vec2(9.1, 3.8), 10.5, 0.12, 1.20, px, 0.58, uTime, accentCol, secondaryCol) * 1.10;
    col += stars * starMask;

    // Soft event horizon shadow eclipse over background light
    float behindHorizon = smoothstep(rShadow - 0.004, rShadow + 0.012, rScreen);

    // Gravitationally lensed upper and lower arches (back of disk bent over/under shadow)
    vec2 normUV = tiltUV / max(rScreen, 1e-4);
    float lensDelta = max(rScreen - rShadow, 0.0);
    float lensAngle = mod(t * 0.42, TWO_PI) + 1.15 / (rScreen + 0.28);
    vec2 lensCoord = rot2(lensAngle) * (normUV * (0.30 + lensDelta * 1.65));
    float lensWarp = fbm4(lensCoord * 2.1 + vec2(1.7, -2.3));
    float lensNoise = fbm4(lensCoord * 2.5 + vec2(lensWarp * 0.55, -lensWarp * 0.45));
    float lensFilament = smoothstep(0.24, 0.84, fbm4(lensCoord * 3.4 + vec2(-lensWarp * 0.60, t * 0.08)));

    float lensProfile = exp(-lensDelta / 0.095) * smoothstep(rShadow - 0.004, rShadow + 0.022, rScreen);
    float archBias = 0.38 + 0.62 * pow(abs(normUV.y), 1.15);
    float dopplerLens = 0.72 + 0.42 * clamp(-normUV.x, -1.0, 1.0);

    vec3 lensTint = mix(violetCol, cyanPlasma, lensFilament * (0.72 - 0.20 * bal));
    vec3 lensGlow = lensTint * lensProfile * archBias * dopplerLens * (0.56 + 0.68 * lensNoise) * 1.08;
    col += lensGlow * behindHorizon;

    // Razor-sharp photon ring right at the shadow edge
    float photonDist = abs(rScreen - rPhoton);
    float photonCore = exp(-(photonDist * photonDist) / max(10.0 * px * px, 1e-7));
    float photonBloom = exp(-photonDist / 0.015) * smoothstep(rShadow - 0.008, rShadow + 0.006, rScreen);
    float dopplerRing = 0.78 + 0.34 * clamp(-normUV.x, -1.0, 1.0);
    vec3 photonCol = mix(violetCol, hotCore, 0.65) * photonBloom * 0.55 + hotCore * photonCore * 1.35;
    photonCol *= dopplerRing;

    // Tilted 3D relativistic accretion disk (evaluated in rotated Cartesian space -> ZERO seam, windup-free!)
    vec2 diskP = vec2(tiltUV.x, tiltUV.y * 3.10);
    float rDisk = length(diskP);

    float baseTwist = 1.45 / (rDisk + 0.34);
    float innerAngle = mod(t * 0.92, TWO_PI) + baseTwist;
    float outerDiskAngle = mod(t * 0.40, TWO_PI) + baseTwist * 0.85;
    vec2 innerP = rot2(innerAngle) * diskP;
    vec2 outerP = rot2(outerDiskAngle) * diskP;

    float innerWarp = fbm4(innerP * 2.1 + vec2(3.1, -1.9));
    float innerGas = fbm4(innerP * 2.7 + vec2(innerWarp * 0.55, -innerWarp * 0.45));
    float innerWisps = ridgedFbm3(innerP * 3.0 + vec2(innerGas * 0.60, -innerGas * 0.45));

    float outerWarp = fbm4(outerP * 1.8 + vec2(-4.2, 2.7));
    float outerGas = fbm4(outerP * 2.4 + vec2(outerWarp * 0.55, -outerWarp * 0.45));
    float outerWisps = ridgedFbm3(outerP * 2.8 + vec2(outerGas * 0.55, -outerGas * 0.40));

    float outerMix = smoothstep(0.23, 0.54, rDisk);
    float dGas = mix(innerGas, outerGas, outerMix);
    float dFilaments = mix(innerWisps, outerWisps, outerMix);

    float innerCutoff = smoothstep(0.180, 0.265, rDisk);
    float outerFalloff = exp(-max(rDisk - 0.23, 0.0) * 2.85) * smoothstep(0.96, 0.48, rDisk);

    float baseBody = smoothstep(0.14, 0.86, dGas);
    float softWisps = smoothstep(0.24, 0.92, dFilaments);
    float diskStructure = mix(0.42, 1.0, baseBody) * (0.74 + 0.38 * softWisps);
    float diskDensity = innerCutoff * outerFalloff * diskStructure;

    // Relativistic Doppler beaming (left/approaching side boosted cyan-white, right/receding deeper violet)
    float approach = clamp(-diskP.x / max(rDisk, 0.08), -1.0, 1.0);
    float dopplerBoost = 0.72 + 0.58 * approach;

    float radialHeat = smoothstep(0.68, 0.21, rDisk);
    vec3 diskOuterCol = mix(sapphireCol, violetCol, clamp(0.45 + 0.45 * bal + 0.25 * (1.0 - approach), 0.0, 1.0));
    vec3 diskInnerCol = mix(cyanPlasma, hotCore, radialHeat * 0.65 + 0.20 * max(approach, 0.0));
    vec3 diskColor = mix(diskOuterCol, diskInnerCol, clamp(radialHeat * 0.82 + softWisps * 0.30, 0.0, 1.0));

    // Extra bright ionized inner ISCO ribbon
    float iscoRing = exp(-pow((rDisk - 0.245) / 0.044, 2.0)) * (0.56 + 0.48 * softWisps);

    // Occlude back half behind the event horizon while foreground sweeps cleanly across its face
    float isForeground = smoothstep(-0.015, 0.030, tiltUV.y);
    float diskOcclusion = mix(behindHorizon, 1.0, isForeground);
    float frontAlpha = clamp((diskDensity * 1.45 + iscoRing * 0.90) * isForeground, 0.0, 1.0);

    // Keep shadow interior pure pitch-dark behind the foreground stream
    col *= behindHorizon;

    // Composite photon ring cleanly behind the foreground disk
    col += photonCol * (1.0 - 0.92 * frontAlpha);

    // Composite luminous accretion disk plasma streams in front of the shadow on foreground half
    col = mix(col, vec3(0.0), frontAlpha * 0.55);
    col += diskColor * diskDensity * dopplerBoost * diskOcclusion * 1.38;
    col += mix(cyanPlasma, hotCore, 0.50) * iscoRing * dopplerBoost * diskOcclusion * 0.78;

    // Subtle soft axial plasma bloom
    float coreHalo = exp(-rScreen * 3.1) * behindHorizon;
    col += mix(sapphireCol, violetCol, 0.4 + 0.3 * bal) * coreHalo * 0.14;

    // Gentle framing vignette
    float vig = 1.0 - 0.28 * dot(screenUv * vec2(0.80, 1.0), screenUv * vec2(0.80, 1.0));
    col *= clamp(vig, 0.65, 1.0);

    col *= clamp(uBrightness, 0.35, 1.85);
    col = aces(col);

    // Full-LSB triangular Interleaved Gradient Noise dithering to eliminate dark-gradient banding
    float ign = interleavedGradientNoise(gl_FragCoord.xy);
    float triDither = (ign < 0.5) ? (sqrt(2.0 * ign) - 1.0) : (1.0 - sqrt(2.0 - 2.0 * ign));
    col = clamp(col + triDither * (1.0 / 255.0), 0.0, 1.0);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
