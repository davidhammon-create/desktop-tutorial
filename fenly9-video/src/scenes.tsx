import React from "react";
import { AbsoluteFill, Sequence, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { Footage, Grade, Camera3D, Claim, ParaLogo, Click, Panel, Label, RevealText, GoldLine, fade, useUnit, SERIF, SANS } from "./components";
import { COLORS } from "./config";

type P = { dur: number };
const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;
/** Platzhalter-Standbilder (Ausschnitte aus dem Storyboard, ohne Text) */
const F = (n: number) => `frames/c-${String(n).padStart(3, "0")}.jpg`;
const B = (n: number) => `frames/f-${String(n).padStart(3, "0")}.jpg`;

/** harte, filmische Schnitte zwischen mehreren Einstellungen */
const Cuts: React.FC<{ shots: { clip: string; still?: string; move?: any; len: number }[] }> = ({ shots }) => {
  let at = 0;
  return <>{shots.map((s, i) => { const from = at; at += s.len;
    return <Sequence key={i} from={from} durationInFrames={s.len}><Footage clip={s.clip} still={s.still} move={s.move} /></Sequence>; })}</>;
};

/* ── 1 · DER ERSTE GEDANKE ─ CEO vor der Glasfront, Kamerafahrt von hinten → Profil */
const S1: React.FC<P> = ({ dur }) => (
  <AbsoluteFill>
    <Cuts shots={[{ clip: "s1_ceo_hinten", still: F(0), move: "push", len: Math.round(dur * 0.55) },
                  { clip: "s1_ceo_profil", still: F(1), move: "pull", len: dur }]} />
    <Claim text="MACHT BEGINNT MIT WISSEN." start={Math.round(dur * 0.6)} y="78%" />
    <Grade />
  </AbsoluteFill>
);

/* ── 2 · DIE STRATEGEN ─ Machiavelli → Sun Tzu → Schach */
const S2: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const a = Math.round(dur * 0.33), b = Math.round(dur * 0.33);
  const Name: React.FC<{ n: string; sub: string; at: number }> = ({ n, sub, at }) =>
    f >= at && f < at + a ? (
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "flex-end", paddingRight: 160 * u }}>
        <div style={{ textAlign: "right" }}>
          <div style={{ fontFamily: SERIF, fontSize: 84 * u, color: COLORS.text, opacity: fade(f, at + 8) }}>{n}</div>
          <div style={{ display: "flex", justifyContent: "flex-end" }}><GoldLine start={at + 14} width={320} /></div>
          <div style={{ fontFamily: SERIF, fontStyle: "italic", fontSize: 40 * u, color: COLORS.goldLight, opacity: fade(f, at + 22) }}>{sub}</div>
        </div>
      </AbsoluteFill>) : null;
  return (
    <AbsoluteFill>
      <Cuts shots={[{ clip: "s2_machiavelli", still: F(2), move: "left", len: a },
                    { clip: "s2_suntzu", still: F(3), move: "right", len: b },
                    { clip: "s2_schach", still: F(8), move: "push", len: dur }]} />
      <Name n="Machiavelli" sub="Macht und Einfluss." at={0} />
      <Name n="Sun Tzu" sub="Strategie und Voraussicht." at={a} />
      <Claim text="ERKENNEN. VORAUSDENKEN. HANDELN." start={a + b + 15} size={52} />
      <Grade />
    </AbsoluteFill>
  );
};

/* ── 3 · DIE MACHT DES RECHTS ─ Parlament, Gericht, Börse; Wort-Schläge im Takt */
const S3: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const q = Math.round(dur / 4);
  const beats = ["Ein Gesetz.", "Eine Klausel.", "Eine Entscheidung."];
  const bStart = Math.round(dur * 0.45);
  return (
    <AbsoluteFill>
      <Cuts shots={[{ clip: "s3_parlament", still: F(0), move: "rise", len: q },
                    { clip: "s3_gericht", still: F(2), move: "push", len: q },
                    { clip: "s3_boerse", still: F(9), move: "left", len: q },
                    { clip: "s3_fassaden", still: F(8), move: "pull", len: dur }]} />
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        {beats.map((t, i) => {
          const at = bStart + i * 28;
          const o = interpolate(f, [at, at + 6, at + 24, at + 30], [0, 1, 1, i === 2 ? 1 : 0], clamp);
          return <div key={t} style={{ position: "absolute", fontFamily: SERIF, fontSize: 110 * u, color: COLORS.text, opacity: f > bStart + 90 ? 0 : o,
            transform: `scale(${1.15 - o * 0.15})`, textShadow: "0 0 60px #000" }}>{t}</div>;
        })}
      </AbsoluteFill>
      <Claim text="RECHT FORMT DIE ZUKUNFT." start={bStart + 95} size={60} />
      <Grade />
    </AbsoluteFill>
  );
};

/* ── 4 · FENLY 9 TRITT AUF ─ § aus der Dunkelheit, Kamera fliegt in die App, drei Module */
const S4: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const appIn = Math.round(dur * 0.42);
  const logoOut = interpolate(f, [appIn - 15, appIn + 5], [1, 0], clamp);
  const fly = interpolate(f, [appIn - 15, appIn + 25], [3.2, 1], { ...clamp, easing: (x) => 1 - Math.pow(1 - x, 3) });
  const mods = [
    { n: "Legalus", d: "Juristische Analyse", g: "§" },
    { n: "Opportunisma", d: "Chancen erkennen", g: "◈" },
    { n: "Stratego", d: "Szenarien & Strategie", g: "♜" },
  ];
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Footage clip="s4_bg" still={F(9)} blur={22} dim={0.8} />
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", opacity: logoOut, transform: `scale(${1 + f / 600})` }}>
        <ParaLogo start={8} tagline="LEGAL INTELLIGENCE · STRATEGIC ADVANTAGE" />
      </AbsoluteFill>
      {f >= appIn - 15 && (
        <AbsoluteFill style={{ transform: `scale(${fly})`, opacity: interpolate(f, [appIn - 15, appIn + 5], [0, 1], clamp) }}>
          <Camera3D from={[10, -14, -100]} to={[3, 6, 0]}>
            <AppShell active={0}>
              <div style={{ display: "flex", gap: 26 * u, marginTop: 40 * u }}>
                {mods.map((m, i) => {
                  const on = fade(f, appIn + 20 + i * 22, 18);
                  const hl = Math.floor((f - appIn - 20) / 22) === i;
                  return (
                    <div key={m.n} style={{ width: 300 * u, padding: 30 * u, borderRadius: 16 * u, opacity: on,
                      transform: `translateY(${(1 - on) * 30}px)`, border: `1px solid ${hl ? COLORS.gold : COLORS.line}`,
                      background: hl ? "rgba(201,169,97,0.08)" : "rgba(255,255,255,0.02)", boxShadow: hl ? `0 0 40px rgba(201,169,97,0.25)` : "none" }}>
                      <div style={{ fontFamily: SERIF, fontSize: 64 * u, color: COLORS.gold, lineHeight: 1 }}>{m.g}</div>
                      <div style={{ fontFamily: SERIF, fontSize: 42 * u, marginTop: 14 * u }}>{m.n}</div>
                      <div style={{ fontSize: 18 * u, color: COLORS.muted, marginTop: 6 * u }}>{m.d}</div>
                    </div>);
                })}
              </div>
              <div style={{ marginTop: 34 * u, fontSize: 15 * u, letterSpacing: 4 * u, color: COLORS.muted, opacity: fade(f, appIn + 90) }}>ZULETZT ANALYSIERT</div>
              {["Liefervertrag „Atlas“ · 4 markierte Klauseln", "Kooperationsvertrag Nord · Szenarien vorbereitet", "Compliance-Update EU · Aufgabe zugewiesen"].map((r, i) => (
                <div key={r} style={{ display: "flex", justifyContent: "space-between", fontSize: 19 * u, padding: `${14 * u}px 0`,
                  borderBottom: `1px solid ${COLORS.line}`, opacity: fade(f, appIn + 95 + i * 10), transform: `translateX(${(1 - fade(f, appIn + 95 + i * 10)) * 30}px)` }}>
                  <span>{r}</span><span style={{ color: COLORS.gold }}>→</span></div>))}
            </AppShell>
          </Camera3D>
          {mods.map((_, i) => <Click key={i} at={appIn + 20 + i * 22} />)}
        </AbsoluteFill>
      )}
      <Grade />
    </AbsoluteFill>
  );
};

/** App-Rahmen (Seitenleiste + Inhalt) – hier später echte Screenshots einsetzen */
const AppShell: React.FC<{ children: React.ReactNode; active: number; title?: string; w?: number; h?: number }> = ({ children, active, title = "Übersicht", w = 1320, h = 720 }) => {
  const { u } = useUnit();
  const nav = ["Legalus", "Opportunisma", "Stratego", "Unternehmen", "Aufgaben", "Berichte"];
  return (
    <div style={{ width: w * u, height: h * u, borderRadius: 26 * u, background: "linear-gradient(160deg, rgba(22,22,30,0.96), rgba(8,8,12,0.96))",
      border: `1px solid ${COLORS.line}`, boxShadow: `0 ${60 * u}px ${160 * u}px rgba(0,0,0,0.9), 0 0 ${80 * u}px rgba(201,169,97,0.08)`,
      display: "flex", overflow: "hidden", fontFamily: SANS, color: COLORS.text }}>
      <div style={{ width: 250 * u, padding: 30 * u, borderRight: `1px solid ${COLORS.line}` }}>
        <div style={{ fontFamily: SERIF, fontSize: 34 * u, color: COLORS.goldLight, marginBottom: 34 * u }}>§ Fenly 9</div>
        {nav.map((n, i) => <div key={n} style={{ fontSize: 19 * u, padding: `${12 * u}px ${14 * u}px`, borderRadius: 10 * u, marginBottom: 4 * u,
          color: i === active ? COLORS.goldLight : COLORS.muted, background: i === active ? "rgba(201,169,97,0.1)" : "transparent" }}>{n}</div>)}
      </div>
      <div style={{ flex: 1, padding: 40 * u }}>
        <div style={{ fontSize: 16 * u, letterSpacing: 4 * u, color: COLORS.muted, textTransform: "uppercase" }}>{nav[active]}</div>
        <div style={{ fontFamily: SERIF, fontSize: 44 * u }}>{title}</div>
        {children}
      </div>
    </div>
  );
};

/* ── 5 · VERTRÄGE LESEN – FOLGEN VERSTEHEN ─ Klauseln markieren, Kategorien, Zeitachse */
const S5: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const scan = interpolate(f, [15, dur * 0.45], [0, 100], clamp);
  const marks = [
    { line: 2, c: COLORS.green, k: "Stärke", t: "Exklusivrecht für 5 Jahre" },
    { line: 6, c: COLORS.amber, k: "Schwäche", t: "Kündigungsfrist nur 14 Tage" },
    { line: 9, c: COLORS.crimson, k: "Risiko", t: "§ 14.2 – Haftung ohne Obergrenze" },
    { line: 12, c: COLORS.blue, k: "Option", t: "Nachverhandlung vor Verlängerung" },
  ];
  const tl = Math.round(dur * 0.62);
  const steps = ["Heute", "1 Jahr", "5 Jahre", "10 Jahre"];
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Footage clip="s5_bg" still={B(8)} blur={20} dim={0.7} />
      <Camera3D from={[8, 16, -160]} to={[2, -6, 40]}>
        <AppShell active={0} title="Vertragsanalyse · Liefervertrag „Atlas“" h={760}>
          <div style={{ display: "flex", gap: 30 * u, marginTop: 26 * u }}>
            <div style={{ width: 520 * u, height: 470 * u, background: "#e9e4d8", borderRadius: 8 * u, padding: 30 * u, position: "relative", overflow: "hidden" }}>
              {new Array(15).fill(0).map((_, i) => {
                const m = marks.find((x) => x.line === i);
                const hit = m && scan > (i / 15) * 100;
                return <div key={i} style={{ height: 9 * u, margin: `${11 * u}px 0`, width: `${i % 4 === 3 ? 60 : 92}%`, borderRadius: 3,
                  background: hit ? m!.c : "#b9b3a5", boxShadow: hit ? `0 0 0 ${5 * u}px ${m!.c}44` : "none" }} />;
              })}
              <div style={{ position: "absolute", left: 0, right: 0, top: `${scan}%`, height: 3 * u, background: COLORS.gold, boxShadow: `0 0 ${30 * u}px ${8 * u}px rgba(201,169,97,0.5)` }} />
            </div>
            <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 14 * u }}>
              {marks.map((m, i) => (
                <Panel key={m.k} start={Math.round(15 + (m.line / 15) * (dur * 0.45 - 15))} style={{ borderLeft: `${5 * u}px solid ${m.c}`, padding: 18 * u }}>
                  <div style={{ fontSize: 15 * u, letterSpacing: 3 * u, color: m.c, textTransform: "uppercase" }}>{m.k}</div>
                  <div style={{ fontSize: 22 * u, marginTop: 4 * u }}>{m.t}</div>
                </Panel>
              ))}
            </div>
          </div>
          {/* Zeitachse */}
          <div style={{ position: "relative", marginTop: 34 * u, height: 70 * u, opacity: fade(f, tl) }}>
            <div style={{ position: "absolute", top: 14 * u, left: 0, height: 2, width: `${interpolate(f, [tl, tl + 60], [0, 100], clamp)}%`,
              background: `linear-gradient(90deg, ${COLORS.green}, ${COLORS.amber}, ${COLORS.crimson})` }} />
            {steps.map((s, i) => (
              <div key={s} style={{ position: "absolute", left: `${i * 32}%`, opacity: fade(f, tl + i * 15), textAlign: "left" }}>
                <div style={{ width: 28 * u, height: 28 * u, borderRadius: 14 * u, border: `2px solid ${COLORS.gold}`, background: "#000" }} />
                <div style={{ fontSize: 18 * u, color: COLORS.muted, marginTop: 6 * u }}>{s}</div>
              </div>
            ))}
          </div>
        </AppShell>
      </Camera3D>
      {marks.map((m) => <Click key={m.k} at={Math.round(15 + (m.line / 15) * (dur * 0.45 - 15))} />)}
      <Grade />
    </AbsoluteFill>
  );
};

/* ── 6 · STRATEGO ─ Szenarien verzweigen sich; Risiko auswählen → Folgen, Gegenmaßnahmen, offene Entscheidungen */
const S6: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const sel = Math.round(dur * 0.5);
  const sc = [{ y: 90, t: "Szenario A · Klage" }, { y: 260, t: "Szenario B · Nachverhandlung" }, { y: 430, t: "Szenario C · Schiedsverfahren" }];
  const detail = ["Folgen: Lieferstopp, Vertragsstrafe", "Gegenmaßnahme: Haftungsdeckel verhandeln", "Offen: Entscheidung Geschäftsführung"];
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Footage clip="s6_bg" still={B(9)} blur={16} dim={0.72} />
      <Camera3D from={[12, -10, -120]} to={[4, 8, 30]}>
        <AppShell active={2} title="Stratego · Szenario-Board" h={700}>
          <svg width={980 * u} height={560 * u} viewBox="0 0 980 560">
            <rect x="10" y="230" width="190" height="80" rx="12" fill="rgba(179,18,46,0.15)" stroke={COLORS.crimson} />
            <text x="105" y="278" textAnchor="middle" fill={COLORS.text} fontFamily={SANS} fontSize="20">§ 14.2 tritt ein</text>
            {sc.map((s, i) => {
              const p = fade(f, 20 + i * 20, 40);
              const chosen = i === 1 && f > sel;
              const o = f > sel && i !== 1 ? 0.35 : 1;
              return (
                <g key={i} opacity={o}>
                  <path d={`M200 270 C 300 270, 300 ${s.y + 40}, 400 ${s.y + 40}`} fill="none" stroke={chosen ? COLORS.goldLight : COLORS.gold}
                    strokeWidth={chosen ? 4 : 2} strokeDasharray="400" strokeDashoffset={400 * (1 - p)} />
                  <g opacity={fade(f, 45 + i * 20)}>
                    <rect x="400" y={s.y} width="300" height="80" rx="12" fill="rgba(18,18,26,0.95)" stroke={chosen ? COLORS.goldLight : COLORS.line} strokeWidth={chosen ? 2.5 : 1} />
                    <text x="420" y={s.y + 48} fill={COLORS.text} fontFamily={SANS} fontSize="19">{s.t}</text>
                  </g>
                </g>);
            })}
            {f > sel && detail.map((d, i) => (
              <g key={d} opacity={fade(f, sel + 12 + i * 16)}>
                <path d={`M700 300 C 730 300, 730 ${150 + i * 130}, 760 ${150 + i * 130}`} fill="none" stroke={COLORS.goldLight} strokeWidth="2" />
                <foreignObject x="760" y={110 + i * 130} width="215" height="90">
                  <div style={{ fontFamily: SANS, fontSize: 16, color: COLORS.text, border: `1px solid ${COLORS.line}`,
                    borderRadius: 10, padding: 10, background: "rgba(18,18,26,0.95)" }}>{d}</div>
                </foreignObject>
              </g>
            ))}
          </svg>
        </AppShell>
      </Camera3D>
      <Click at={sel} />
      <Claim text="SZENARIEN. RISIKEN. OPTIONEN." start={dur - 75} size={44} y="88%" />
      <Grade />
    </AbsoluteFill>
  );
};

/* ── 7 · DAS UNTERNEHMEN IM BLICK ─ Rollen, Kompetenzen, Projekte → Zuweisung → Tagesübersicht */
const S7: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const assign = Math.round(dur * 0.45);
  const people = [
    { n: "Dr. A. Schmidt", r: "Recht · Vertragsrecht", w: "Projekt Atlas", load: 0.4 },
    { n: "L. Weber", r: "Compliance", w: "EU-Verordnung", load: 0.85 },
    { n: "M. Kaya", r: "Finanzen", w: "Q4-Planung", load: 0.6 },
    { n: "J. Brandt", r: "Vertrieb", w: "Key Accounts", load: 0.7 },
  ];
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Footage clip="s7_buero" still={B(10)} blur={14} dim={0.72} />
      <Camera3D from={[6, 14, -140]} to={[2, -8, 20]}>
        <AppShell active={3} title="Team · Kompetenzen · laufende Arbeit" h={700}>
          <div style={{ display: "flex", gap: 28 * u, marginTop: 26 * u }}>
            <div style={{ flex: 1.4, display: "flex", flexDirection: "column", gap: 12 * u }}>
              {people.map((p, i) => {
                const hot = i === 0 && f > assign;
                return (
                  <Panel key={p.n} start={10 + i * 10} style={{ display: "flex", alignItems: "center", gap: 18 * u, padding: 16 * u,
                    border: `1px solid ${hot ? COLORS.goldLight : COLORS.line}`, boxShadow: hot ? "0 0 30px rgba(201,169,97,0.3)" : undefined }}>
                    <div style={{ width: 48 * u, height: 48 * u, borderRadius: 24 * u, background: "linear-gradient(135deg,#3a3630,#15151a)",
                      border: `1px solid ${COLORS.line}`, display: "flex", justifyContent: "center", alignItems: "center",
                      fontFamily: SERIF, fontSize: 22 * u, color: COLORS.goldLight }}>{p.n.split(" ").pop()![0]}</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 21 * u }}>{p.n}</div>
                      <div style={{ fontSize: 15 * u, color: COLORS.muted }}>{p.r} · arbeitet an: {hot ? "Vertragsprüfung § 14.2" : p.w}</div>
                    </div>
                    <div style={{ width: 120 * u, height: 6 * u, borderRadius: 3, background: "rgba(255,255,255,0.08)" }}>
                      <div style={{ width: `${p.load * 100 * fade(f, 20 + i * 10, 40)}%`, height: "100%", borderRadius: 3, background: p.load > 0.8 ? COLORS.crimson : COLORS.gold }} />
                    </div>
                  </Panel>);
              })}
            </div>
            <div style={{ flex: 1 }}>
              <Panel start={assign - 25} style={{ padding: 22 * u }}>
                <div style={{ fontSize: 15 * u, letterSpacing: 3 * u, color: COLORS.gold }}>AUFGABE ZUWEISEN</div>
                <div style={{ fontSize: 22 * u, marginTop: 8 * u }}>Vertragsprüfung § 14.2</div>
                <div style={{ fontSize: 15 * u, color: COLORS.muted, marginTop: 6 * u }}>Passende Kompetenz: Vertragsrecht · Kapazität frei</div>
                <div style={{ marginTop: 14 * u, padding: `${10 * u}px ${16 * u}px`, borderRadius: 30 * u, display: "inline-block", fontSize: 17 * u,
                  background: f > assign ? COLORS.gold : "transparent", color: f > assign ? "#000" : COLORS.gold, border: `1px solid ${COLORS.gold}` }}>
                  {f > assign ? "✓ Zugewiesen an Dr. A. Schmidt" : "Zuweisen"}</div>
              </Panel>
              <Panel start={assign + 40} style={{ padding: 22 * u, marginTop: 16 * u }}>
                <div style={{ fontSize: 15 * u, letterSpacing: 3 * u, color: COLORS.gold }}>TAGESÜBERSICHT · CEO</div>
                {["3 Verträge in Prüfung", "2 Aufgaben abgeschlossen", "1 Frist diese Woche"].map((t, i) =>
                  <div key={t} style={{ fontSize: 19 * u, marginTop: 10 * u, opacity: fade(f, assign + 55 + i * 12) }}>— {t}</div>)}
              </Panel>
            </div>
          </div>
        </AppShell>
      </Camera3D>
      <Click at={assign} />
      <Grade />
    </AbsoluteFill>
  );
};

/* ── 8 · DIE INFORMATION ERREICHT DEN RICHTIGEN ─ Smartphone-Nahaufnahme, Push-Nachricht */
const S8: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { u } = useUnit();
  const push = spring({ frame: f - 25, fps, config: { damping: 14 } });
  const open = fade(f, Math.round(dur * 0.62), 14);
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      <Footage clip="s8_hand_handy" still={F(9)} blur={10} dim={0.6} move="push" />
      <Camera3D from={[18, -22, -60]} to={[6, -8, 60]} zoom={[1, 1.12]}>
        <div style={{ width: 400 * u, height: 820 * u, borderRadius: 60 * u, background: "#07070a", border: `${4 * u}px solid #2b2b33`, overflow: "hidden",
          boxShadow: `0 ${50 * u}px ${140 * u}px rgba(0,0,0,0.9)`, padding: `${80 * u}px ${22 * u}px`, fontFamily: SANS, color: COLORS.text, position: "relative" }}>
          <div style={{ textAlign: "center", fontSize: 76 * u, fontWeight: 200, opacity: 1 - open }}>09:41</div>
          <div style={{ marginTop: 30 * u, transform: `translateY(${(1 - push) * -260 * u}px)`, opacity: push * (1 - open), background: "rgba(44,42,38,0.92)",
            borderRadius: 24 * u, padding: 20 * u, border: `1px solid ${COLORS.line}` }}>
            <div style={{ fontSize: 15 * u, color: COLORS.gold, letterSpacing: 2 * u }}>§ FENLY 9 · jetzt</div>
            <div style={{ fontSize: 21 * u, fontWeight: 600, marginTop: 8 * u }}>Neue Aufgabe: Vertragsprüfung</div>
            <div style={{ fontSize: 17 * u, color: "#cfcabb", marginTop: 4 * u }}>zugewiesen durch CEO</div>
          </div>
          <div style={{ position: "absolute", inset: 0, padding: `${80 * u}px ${26 * u}px`, opacity: open, transform: `scale(${0.9 + open * 0.1})` }}>
            <div style={{ fontFamily: SERIF, fontSize: 36 * u }}>Vertragsprüfung</div>
            <div style={{ fontSize: 16 * u, color: COLORS.muted, marginTop: 6 * u }}>Liefervertrag „Atlas“ · § 14.2</div>
            {["Klausel lesen & bewerten", "Risiken dokumentieren", "Optionen an CEO melden"].map((t, i) =>
              <div key={t} style={{ fontSize: 19 * u, marginTop: 22 * u, opacity: fade(f, Math.round(dur * 0.62) + 10 + i * 8) }}>☐ {t}</div>)}
          </div>
        </div>
      </Camera3D>
      <Click at={25} /><Click at={Math.round(dur * 0.62)} />
      <Grade />
    </AbsoluteFill>
  );
};

/* ── 9 · DER ABSCHLUSS ─ CEO blickt in die Kamera (Lip-Sync) → Schwarz → Logo */
const S9: React.FC<P> = ({ dur }) => {
  const f = useCurrentFrame();
  const cut = Math.round(dur * 0.62);
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {/* Lip-Sync-Clip startet synchron zur Stimme (0,5 s Versatz wie das Voiceover) */}
      {f < cut && <Footage clip="-" still={F(1)} move="push" dim={0.1} />}
      {f < cut && <Sequence from={15}><Footage clip="s9_ceo_spricht" move="push" dim={0.1} /></Sequence>}
      {f >= cut && (
        <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
          <Sequence from={cut}><ParaLogo start={6} tagline="WISSEN. STRATEGIE. MACHT." /></Sequence>
        </AbsoluteFill>
      )}
      <Grade />
    </AbsoluteFill>
  );
};

export const SCENE_COMPONENTS: React.FC<P>[] = [S1, S2, S3, S4, S5, S6, S7, S8, S9];
