import React from "react";
import {
  AbsoluteFill, interpolate, random, spring, useCurrentFrame, useVideoConfig, Easing,
} from "remotion";
import { loadFont as loadSerif } from "@remotion/google-fonts/CormorantGaramond";
import { loadFont as loadSans } from "@remotion/google-fonts/Inter";
import { COLORS } from "./config";

export const SERIF = loadSerif().fontFamily;
export const SANS = loadSans().fontFamily;

/** Einheit: 1 = 1px bei 1080p, funktioniert für Quer- und Hochformat */
export const useUnit = () => {
  const { width, height } = useVideoConfig();
  return { u: Math.min(width, height) / 1080, vertical: height > width, width, height };
};

export const ease = Easing.bezier(0.16, 1, 0.3, 1);
export const fade = (f: number, start: number, len = 20) =>
  interpolate(f, [start, start + len], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease });

/** Düsterer Hintergrund: Nebel, Goldstaub, Filmkorn, Vignette, Kinobalken */
export const Atmosphere: React.FC<{ tint?: string; children?: React.ReactNode }> = ({ tint = COLORS.gold, children }) => {
  const f = useCurrentFrame();
  const { width, height } = useVideoConfig();
  const dust = new Array(60).fill(0).map((_, i) => {
    const x = random(`x${i}`) * width;
    const y = (random(`y${i}`) * height - f * (0.2 + random(`s${i}`) * 0.6)) % height;
    return { x, y: y < 0 ? y + height : y, r: 0.6 + random(`r${i}`) * 2.2, o: 0.15 + random(`o${i}`) * 0.5 };
  });
  return (
    <AbsoluteFill style={{ background: COLORS.black, overflow: "hidden" }}>
      <AbsoluteFill style={{
        background: `radial-gradient(ellipse at ${50 + Math.sin(f / 90) * 8}% ${45 + Math.cos(f / 110) * 6}%, ${tint}22 0%, transparent 55%)`,
      }} />
      <AbsoluteFill style={{ filter: "blur(80px)", opacity: 0.35 }}>
        <div style={{ position: "absolute", width: width * 0.6, height: height * 0.5, left: -width * 0.1 + f * 0.6,
          top: height * 0.45, borderRadius: "50%", background: "#1b1b26" }} />
        <div style={{ position: "absolute", width: width * 0.5, height: height * 0.4, right: -width * 0.1 + f * 0.4,
          top: height * 0.05, borderRadius: "50%", background: "#221418" }} />
      </AbsoluteFill>
      <svg width={width} height={height} style={{ position: "absolute" }}>
        {dust.map((d, i) => <circle key={i} cx={d.x} cy={d.y} r={d.r} fill={COLORS.goldLight} opacity={d.o} />)}
      </svg>
      <AbsoluteFill>{children}</AbsoluteFill>
      {/* Filmkorn */}
      <svg width={width} height={height} style={{ position: "absolute", opacity: 0.09, mixBlendMode: "overlay" }}>
        <filter id="grain"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves={2} seed={f % 30} /></filter>
        <rect width="100%" height="100%" filter="url(#grain)" />
      </svg>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse at center, transparent 45%, rgba(0,0,0,0.85) 100%)" }} />
    </AbsoluteFill>
  );
};

/** Wörter erscheinen nacheinander aus Unschärfe */
export const RevealText: React.FC<{
  text: string; start?: number; size?: number; serif?: boolean; color?: string;
  stagger?: number; weight?: number; italic?: boolean; spacing?: number; maxWidth?: number;
}> = ({ text, start = 0, size = 64, serif = true, color = COLORS.text, stagger = 4, weight = 500, italic, spacing = 0, maxWidth = 1500 }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  return (
    <div style={{ display: "flex", flexWrap: "wrap", justifyContent: "center", maxWidth: maxWidth * u,
      fontFamily: serif ? SERIF : SANS, fontSize: size * u, color, fontWeight: weight,
      fontStyle: italic ? "italic" : "normal", letterSpacing: spacing * u, lineHeight: 1.2, textAlign: "center" }}>
      {text.split(" ").map((w, i) => {
        const p = fade(f, start + i * stagger, 18);
        return (
          <span key={i} style={{ opacity: p, filter: `blur(${(1 - p) * 12}px)`,
            transform: `translateY(${(1 - p) * 20 * u}px)`, marginRight: size * 0.28 * u }}>{w}</span>
        );
      })}
    </div>
  );
};

export const Center: React.FC<{ children: React.ReactNode; gap?: number; style?: React.CSSProperties }> = ({ children, gap = 30, style }) => {
  const { u } = useUnit();
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", flexDirection: "column", gap: gap * u, padding: 80 * u, ...style }}>
      {children}
    </AbsoluteFill>
  );
};

/** Goldene Trennlinie, die sich aufzieht */
export const GoldLine: React.FC<{ start?: number; width?: number; color?: string }> = ({ start = 0, width = 400, color = COLORS.gold }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  return <div style={{ height: 2 * u, width: width * u * fade(f, start, 30), background: `linear-gradient(90deg, transparent, ${color}, transparent)` }} />;
};

export const Label: React.FC<{ children: React.ReactNode; color?: string; start?: number; size?: number }> = ({ children, color = COLORS.gold, start = 0, size = 22 }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  return (
    <div style={{ fontFamily: SANS, fontSize: size * u, letterSpacing: 8 * u, textTransform: "uppercase", color,
      opacity: fade(f, start), fontWeight: 600 }}>{children}</div>
  );
};

/** Glas-Panel im App-Look */
export const Panel: React.FC<{ children: React.ReactNode; style?: React.CSSProperties; start?: number; glow?: string }> = ({ children, style, start = 0, glow }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { u } = useUnit();
  const s = spring({ frame: f - start, fps, config: { damping: 200 } });
  return (
    <div style={{ background: COLORS.panel, border: `1px solid ${COLORS.line}`, borderRadius: 18 * u,
      boxShadow: `0 ${30 * u}px ${80 * u}px rgba(0,0,0,0.6)${glow ? `, 0 0 ${60 * u}px ${glow}` : ""}`,
      padding: 28 * u, opacity: s, transform: `translateY(${(1 - s) * 40 * u}px) scale(${0.96 + s * 0.04})`,
      backdropFilter: "blur(12px)", fontFamily: SANS, color: COLORS.text, ...style }}>{children}</div>
  );
};

/** Smartphone-Mockup */
export const Phone: React.FC<{ children: React.ReactNode; start?: number; scale?: number }> = ({ children, start = 0, scale = 1 }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { u } = useUnit();
  const s = spring({ frame: f - start, fps, config: { damping: 18, mass: 0.8 } });
  const k = u * scale;
  return (
    <div style={{ width: 380 * k, height: 780 * k, borderRadius: 56 * k, background: "#0a0a0d",
      border: `${3 * k}px solid #2a2a33`, boxShadow: `0 ${40 * k}px ${120 * k}px rgba(0,0,0,0.8), inset 0 0 0 ${8 * k}px #111`,
      transform: `translateY(${(1 - s) * 600 * k}px) rotate(${(1 - s) * 8}deg)`, overflow: "hidden", position: "relative",
      padding: `${70 * k}px ${22 * k}px ${22 * k}px`, fontFamily: SANS, color: COLORS.text }}>
      <div style={{ position: "absolute", top: 18 * k, left: "50%", marginLeft: -60 * k, width: 120 * k, height: 32 * k,
        borderRadius: 20 * k, background: "#000" }} />
      {children}
    </div>
  );
};

/** FENLY 9 Logo: Hexagon mit 9, Goldglanz */
export const Logo: React.FC<{ size?: number; start?: number }> = ({ size = 1, start = 0 }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { u } = useUnit();
  const s = spring({ frame: f - start, fps, config: { damping: 200, mass: 1.4 } });
  const k = size * u;
  const shine = interpolate(f - start, [10, 60], [-150, 320], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const hex = "100,8 180,54 180,146 100,192 20,146 20,54";
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 36 * k, opacity: s, transform: `scale(${0.85 + 0.15 * s})` }}>
      <svg width={150 * k} height={150 * k} viewBox="0 0 200 200">
        <defs>
          <linearGradient id="lg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={COLORS.goldLight} /><stop offset="1" stopColor="#7a5f2a" />
          </linearGradient>
        </defs>
        <polygon points={hex} fill="none" stroke="url(#lg)" strokeWidth={5}
          strokeDasharray={560} strokeDashoffset={560 * (1 - s)} />
        <polygon points={hex} fill={COLORS.gold} opacity={0.06} />
        <text x="100" y="132" textAnchor="middle" fontFamily={SERIF} fontSize="104" fontWeight={600} fill="url(#lg)">9</text>
      </svg>
      <div style={{ position: "relative", overflow: "hidden", fontFamily: SERIF, fontWeight: 600, fontSize: 130 * k,
        letterSpacing: 26 * k, color: COLORS.goldLight, lineHeight: 1 }}>
        FENLY
        <div style={{ position: "absolute", inset: 0, transform: `translateX(${shine}%) skewX(-20deg)`,
          background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.55), transparent)", width: "40%" }} />
      </div>
    </div>
  );
};

export const Subtitle: React.FC<{ text: string; duration: number }> = ({ text, duration }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const o = interpolate(f, [8, 22, duration - 15, duration - 3], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ justifyContent: "flex-end", alignItems: "center", paddingBottom: 60 * u }}>
      <div style={{ opacity: o * 0.92, fontFamily: SANS, fontSize: 26 * u, color: "#f2efe6", maxWidth: 1300 * u,
        textAlign: "center", background: "rgba(0,0,0,0.55)", padding: `${10 * u}px ${24 * u}px`, borderRadius: 8 * u,
        lineHeight: 1.35 }}>{text}</div>
    </AbsoluteFill>
  );
};

/** Schwarzblende zwischen Szenen */
export const SceneFade: React.FC<{ duration: number }> = ({ duration }) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, 12, duration - 12, duration], [1, 0, 0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return <AbsoluteFill style={{ background: "#000", opacity: o, pointerEvents: "none" }} />;
};

// ======================= v2: Kino-Bausteine =======================
import { Img, OffthreadVideo, Audio as RAudio, Sequence as RSeq } from "remotion";
import { has, asset, firstOf } from "./config";

/**
 * Bewegtes Filmmaterial. Reihenfolge: KI-Clip (public/clips/…mp4) → Standbild (public/frames/…jpg).
 * Ohne Clip wird das Standbild per virtueller Kamerafahrt, Licht und Tiefe animiert (nur Vorschau-Ersatz).
 */
export const Footage: React.FC<{
  clip: string; still?: string; from?: number; dur?: number;
  move?: "push" | "pull" | "left" | "right" | "rise"; dim?: number; blur?: number; focus?: string;
}> = ({ clip, still, move = "push", dim = 0.25, blur = 0, focus = "50% 50%" }) => {
  const f = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const t = f / Math.max(1, durationInFrames);
  const src = firstOf(`clips/${clip}.mp4`);
  const m = {
    push: { s: 1.06 + t * 0.14, x: 0, y: 0 }, pull: { s: 1.22 - t * 0.14, x: 0, y: 0 },
    left: { s: 1.15, x: 3 - t * 6, y: 0 }, right: { s: 1.15, x: -3 + t * 6, y: 0 }, rise: { s: 1.14, x: 0, y: 3 - t * 6 },
  }[move];
  const style: React.CSSProperties = { width: "100%", height: "100%", objectFit: "cover", objectPosition: focus,
    filter: `blur(${blur}px) saturate(0.85) contrast(1.08)` };
  return (
    <AbsoluteFill style={{ overflow: "hidden", background: "#000" }}>
      {src ? (
        <OffthreadVideo src={asset(src)} muted style={{ ...style, transform: `scale(${1.02 + t * 0.03})` }} />
      ) : still && has(still) ? (
        <AbsoluteFill style={{ transform: `scale(${m.s}) translate(${m.x}%, ${m.y}%)` }}>
          <Img src={asset(still)} style={style} />
          {/* Lichtwanderung als Bewegungsersatz */}
          <AbsoluteFill style={{ mixBlendMode: "screen", opacity: 0.35,
            background: `linear-gradient(${100 + t * 40}deg, transparent ${20 + t * 50}%, rgba(236,217,164,0.25) ${30 + t * 50}%, transparent ${42 + t * 50}%)` }} />
        </AbsoluteFill>
      ) : null}
      {(src || (still && has(still))) && <AbsoluteFill style={{ background: `rgba(0,0,0,${dim})` }} />}
    </AbsoluteFill>
  );
};

/** Color-Grade, Filmkorn, Vignette, Lichtflimmern – über jede Szene */
export const Grade: React.FC = () => {
  const f = useCurrentFrame();
  const { width, height } = useVideoConfig();
  const flick = 0.03 * Math.sin(f / 3) * Math.sin(f / 7);
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg, rgba(20,24,40,0.25), rgba(40,26,8,0.18))", mixBlendMode: "soft-light" }} />
      <svg width={width} height={height} style={{ position: "absolute", opacity: 0.1, mixBlendMode: "overlay" }}>
        <filter id="g2"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves={2} seed={f % 24} /></filter>
        <rect width="100%" height="100%" filter="url(#g2)" />
      </svg>
      <AbsoluteFill style={{ background: "radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.8) 100%)", opacity: 1 + flick }} />
    </AbsoluteFill>
  );
};

/** Virtuelle 3D-Kamera: langsame Dolly-/Orbit-Fahrt um App-Oberflächen */
export const Camera3D: React.FC<{ 
  children: React.ReactNode; from?: [number, number, number]; to?: [number, number, number]; zoom?: [number, number];
}> = ({ children, from = [14, -18, -300], to = [4, 8, 0], zoom = [0.92, 1.04] }) => {
  const f = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const k = interpolate(f, [0, durationInFrames], [0, 1], { easing: Easing.bezier(0.33, 0, 0.2, 1) });
  const l = (i: number) => from[i] + (to[i] - from[i]) * k;
  return (
    <AbsoluteFill style={{ perspective: 1800, justifyContent: "center", alignItems: "center" }}>
      <div style={{ transformStyle: "preserve-3d", transform: `translateZ(${l(2)}px) rotateX(${l(0)}deg) rotateY(${l(1)}deg) scale(${zoom[0] + (zoom[1] - zoom[0]) * k})` }}>
        {children}
      </div>
    </AbsoluteFill>
  );
};

/** Einblendung: Kino-Typo mit Tracking-Animation */
export const Claim: React.FC<{ text: string; start: number; size?: number; color?: string; y?: string }> = ({ text, start, size = 46, color = COLORS.goldLight, y = "50%" }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const p = fade(f, start, 40);
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", top: `calc(${y} - 50%)` }}>
      <div style={{ fontFamily: SERIF, fontSize: size * u, color, fontWeight: 500, opacity: p, textAlign: "center",
        letterSpacing: (4 + (1 - p) * 30 + f * 0.02) * u, filter: `blur(${(1 - p) * 8}px)`, textShadow: "0 0 40px rgba(0,0,0,0.9)" }}>{text}</div>
      <div style={{ marginTop: 18 * u }}><GoldLine start={start + 10} width={360} /></div>
    </AbsoluteFill>
  );
};

/** Neues Logo im Stil der Referenzen: § über "Fenly 9" */
export const ParaLogo: React.FC<{ start?: number; size?: number; tagline?: string }> = ({ start = 0, size = 1, tagline }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { u } = useUnit();
  const k = size * u;
  const s = spring({ frame: f - start, fps, config: { damping: 200, mass: 1.6 } });
  const n = spring({ frame: f - start - 18, fps, config: { damping: 200, mass: 1.6 } });
  const shine = interpolate(f - start, [25, 75], [-60, 160], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const gold = `linear-gradient(180deg, #f6e7bd 0%, ${COLORS.gold} 45%, #6e5424 100%)`;
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
      <div style={{ fontFamily: SERIF, fontSize: 170 * k, lineHeight: 1, backgroundImage: gold,
        WebkitBackgroundClip: "text", backgroundClip: "text", WebkitTextFillColor: "transparent", color: "transparent",
        opacity: s, transform: `translateY(${(1 - s) * 30 * k}px)`, filter: `drop-shadow(0 0 ${30 * s}px rgba(201,169,97,0.45))` }}>§</div>
      <div style={{ position: "relative", fontFamily: SERIF, fontSize: 150 * k, lineHeight: 1.05, opacity: n, letterSpacing: (2 + (1 - n) * 20) * k,
        backgroundImage: `linear-gradient(100deg, transparent ${shine - 15}%, #fff ${shine}%, transparent ${shine + 15}%), ${gold}`,
        WebkitBackgroundClip: "text", backgroundClip: "text", WebkitTextFillColor: "transparent", color: "transparent" }}>Fenly 9</div>
      {tagline && <div style={{ marginTop: 22 * k, fontFamily: SANS, fontSize: 26 * k, letterSpacing: 12 * k, color: COLORS.text,
        opacity: fade(f, start + 50, 30) }}>{tagline}</div>}
    </div>
  );
};

/** Interface-Klick (nur wenn public/sfx/click.mp3 existiert) */
export const Click: React.FC<{ at: number }> = ({ at }) =>
  has("sfx/click.mp3") ? <RSeq from={at} durationInFrames={20}><RAudio src={asset("sfx/click.mp3")} volume={0.35} /></RSeq> : null;
