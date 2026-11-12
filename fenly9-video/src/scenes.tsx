import React from "react";
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig, random } from "remotion";
import { Atmosphere, Center, RevealText, GoldLine, Label, Panel, Phone, Logo, fade, useUnit, SERIF, SANS } from "./components";
import { COLORS } from "./config";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/* 1 ─ Kalte Eröffnung: fallende Paragraphen in der Dunkelheit */
export const Schatten: React.FC = () => {
  const f = useCurrentFrame();
  const { u, width, height } = useUnit();
  return (
    <Atmosphere>
      {new Array(26).fill(0).map((_, i) => {
        const x = random(`p${i}`) * width;
        const y = ((random(`q${i}`) * height + f * (1 + random(`v${i}`) * 2)) % (height + 200)) - 100;
        return <div key={i} style={{ position: "absolute", left: x, top: y, fontFamily: SERIF, color: COLORS.gold,
          fontSize: (40 + random(`z${i}`) * 120) * u, opacity: 0.05 + random(`o${i}`) * 0.18, filter: `blur(${random(`b${i}`) * 4}px)` }}>§</div>;
      })}
      <Center style={{ transform: `scale(${1 + f / 900})` }}>
        <RevealText text="Macht war nie laut." size={110} start={15} stagger={8} />
        <RevealText text="Sie flüstert — in Paragraphen." size={52} start={95} italic color={COLORS.goldLight} />
      </Center>
    </Atmosphere>
  );
};

/* 2 ─ Machiavelli */
export const Machiavelli: React.FC = () => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  return (
    <Atmosphere tint={COLORS.crimson}>
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <div style={{ fontFamily: SERIF, fontSize: 330 * u, color: COLORS.crimson, opacity: 0.08 * fade(f, 0, 40),
          letterSpacing: 30 * u, transform: `translateX(${-f * 0.6 * u}px)` }}>IL PRINCIPE</div>
      </AbsoluteFill>
      <Center gap={34}>
        <Label start={5}>Niccolò Machiavelli · Il Principe · 1513</Label>
        <GoldLine start={10} width={500} color={COLORS.crimson} />
        <RevealText text="„Wer einen anderen mächtig macht, richtet sich selbst zugrunde.“" size={78} start={25} italic maxWidth={1400} />
        <div style={{ opacity: fade(f, 190, 25) }}>
          <RevealText text="Wer die Regeln nicht kennt, macht immer die anderen mächtig." size={40} serif={false} weight={300} start={190} color={COLORS.muted} />
        </div>
      </Center>
    </Atmosphere>
  );
};

/* 3 ─ Sun Tzu: vom Schlachtfeld zum Vertrag */
export const SunTzu: React.FC = () => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const toContract = fade(f, 220, 40);
  return (
    <Atmosphere>
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <div style={{ fontFamily: SERIF, fontSize: 620 * u, color: COLORS.gold, opacity: 0.07 * (1 - toContract),
          transform: `scale(${1.1 - f / 2000})` }}>孫子</div>
      </AbsoluteFill>
      <Center gap={30} style={{ opacity: 1 - toContract }}>
        <Label start={5}>Sun Tzu · Die Kunst des Krieges</Label>
        <GoldLine start={10} width={500} />
        <RevealText text="„Kenne deinen Feind und kenne dich selbst — und in hundert Schlachten wirst du nie in Gefahr sein.“" size={68} start={22} italic maxWidth={1500} />
      </Center>
      <Center style={{ opacity: toContract }}>
        <svg width={420 * u} height={540 * u} viewBox="0 0 420 540">
          <rect x="10" y="10" width="400" height="520" rx="10" fill="none" stroke={COLORS.gold} strokeWidth="2"
            strokeDasharray="1840" strokeDashoffset={1840 * (1 - fade(f, 225, 50))} />
          {new Array(14).fill(0).map((_, i) => (
            <rect key={i} x="45" y={60 + i * 32} height="6" rx="3" fill={COLORS.gold}
              opacity={0.35} width={(i % 4 === 3 ? 180 : 330) * fade(f, 240 + i * 3, 20)} />
          ))}
        </svg>
        <RevealText text="Die Schlachtfelder von heute heißen Verträge." size={54} start={260} />
      </Center>
    </Atmosphere>
  );
};

/* 4 ─ Gesellschaft · Politik · Wirtschaft */
const Icon: React.FC<{ kind: number; on: number }> = ({ kind, on }) => {
  const c = COLORS.gold;
  const common = { fill: "none", stroke: c, strokeWidth: 3, strokeLinecap: "round" as const };
  return (
    <svg width="120" height="120" viewBox="0 0 120 120" style={{ filter: `drop-shadow(0 0 ${on * 18}px ${c})`, opacity: 0.3 + on * 0.7 }}>
      {kind === 0 && <g {...common}><circle cx="60" cy="38" r="14" /><circle cx="28" cy="52" r="10" /><circle cx="92" cy="52" r="10" />
        <path d="M30 100c0-18 14-30 30-30s30 12 30 30M8 100c0-12 8-22 20-22M112 100c0-12-8-22-20-22" /></g>}
      {kind === 1 && <g {...common}><path d="M60 14v86M30 100h60M20 34h80M20 34l-14 34h28zM100 34l-14 34h28z" />
        <path d="M6 68a14 8 0 0 0 28 0M86 68a14 8 0 0 0 28 0" /></g>}
      {kind === 2 && <g {...common}><path d="M10 106h100M22 106V76M46 106V58M70 106V66M94 106V30" />
        <path d="M14 66l30-26 22 12 40-34" /><path d="M92 18h14v14" /></g>}
    </svg>
  );
};
export const Reiche: React.FC = () => {
  const f = useCurrentFrame();
  const { u, vertical } = useUnit();
  const items = ["Gesellschaft", "Politik", "Wirtschaft"];
  const sub = ["formt Normen & Werte", "macht Gesetze", "entscheidet über Märkte"];
  return (
    <Atmosphere>
      <Center gap={70}>
        <div style={{ display: "flex", flexDirection: vertical ? "column" : "row", gap: 90 * u }}>
          {items.map((t, i) => {
            const on = fade(f, 15 + i * 55, 25);
            return (
              <div key={t} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 * u, opacity: 0.25 + on * 0.75,
                transform: `translateY(${(1 - on) * 30 * u}px) scale(${u})` }}>
                <Icon kind={i} on={on} />
                <div style={{ fontFamily: SERIF, fontSize: 56, color: COLORS.text }}>{t}</div>
                <div style={{ fontFamily: SANS, fontSize: 22, color: COLORS.muted, letterSpacing: 2 }}>{sub[i]}</div>
              </div>
            );
          })}
        </div>
        <GoldLine start={190} width={900} />
        <RevealText text="Wer das Recht beherrscht, beherrscht das Spiel." size={64} start={200} color={COLORS.goldLight} />
      </Center>
    </Atmosphere>
  );
};

/* 5 ─ Enthüllung: Machiavellex → Chiara Lex → FENLY 9 */
export const Reveal: React.FC = () => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const name = (t: string, a: number, b: number) => {
    const o = interpolate(f, [a, a + 15, b - 10, b], [0, 1, 1, 0], clamp);
    const strike = interpolate(f, [b - 30, b - 12], [0, 100], clamp);
    return (
      <div style={{ position: "absolute", opacity: o, fontFamily: SERIF, fontSize: 96 * u, color: COLORS.muted,
        filter: `blur(${(1 - o) * 10}px)`, letterSpacing: 6 * u }}>
        {t}
        <div style={{ position: "absolute", left: 0, top: "55%", height: 3 * u, width: `${strike}%`, background: COLORS.crimson }} />
      </div>
    );
  };
  const flash = interpolate(f, [118, 124, 150], [0, 0.9, 0], clamp);
  return (
    <Atmosphere>
      <Center>
        {name("Machiavellex", 5, 60)}
        {name("Chiara Lex", 62, 118)}
        {f >= 120 && <Logo start={120} size={1.1} />}
        {f >= 120 && <div style={{ position: "absolute", bottom: 300 * u, width: "100%", display: "flex", justifyContent: "center" }}>
          <Label start={155}>Legal Intelligence · Strategie · Unternehmenssteuerung</Label></div>}
      </Center>
      <AbsoluteFill style={{ background: `radial-gradient(circle, ${COLORS.goldLight} 0%, transparent 60%)`, opacity: flash }} />
    </Atmosphere>
  );
};

/* 6 ─ Die drei Module */
export const Module: React.FC = () => {
  const { u, vertical } = useUnit();
  const mods = [
    { n: "Legalus", d: "durchleuchtet Recht & Verträge", g: "§" },
    { n: "Opportunisma", d: "erkennt Chancen, bevor andere sie sehen", g: "◈" },
    { n: "Stratego", d: "plant den nächsten Zug", g: "♜" },
  ];
  return (
    <Atmosphere>
      <Center gap={50}>
        <Label>Ein System. Drei Waffen.</Label>
        <div style={{ display: "flex", flexDirection: vertical ? "column" : "row", gap: 40 * u }}>
          {mods.map((m, i) => (
            <Panel key={m.n} start={15 + i * 40} glow="rgba(201,169,97,0.12)" style={{ width: 460 * u, textAlign: "center", padding: 44 * u }}>
              <div style={{ fontFamily: SERIF, fontSize: 90 * u, color: COLORS.gold, lineHeight: 1 }}>{m.g}</div>
              <div style={{ fontFamily: SERIF, fontSize: 60 * u, marginTop: 14 * u }}>{m.n}</div>
              <div style={{ fontSize: 22 * u, color: COLORS.muted, marginTop: 10 * u }}>{m.d}</div>
            </Panel>
          ))}
        </div>
        <div style={{ position: "absolute", top: 70 * u }}><Logo size={0.35} /></div>
      </Center>
    </Atmosphere>
  );
};

/* 7 ─ Vertrags-Röntgen */
export const Vertrag: React.FC = () => {
  const f = useCurrentFrame();
  const { u, vertical } = useUnit();
  const scanY = interpolate(f, [20, 200], [0, 100], clamp);
  const tags = [
    { line: 3, c: COLORS.green, t: "Vorteil · Exklusivrecht 5 Jahre" },
    { line: 7, c: COLORS.amber, t: "Schwachstelle · Kündigungsfrist 14 Tage" },
    { line: 11, c: COLORS.crimson, t: "Risiko · §14.2 unbegrenzte Haftung" },
  ];
  const score = Math.round(interpolate(f, [60, 230], [0, 73], clamp));
  return (
    <Atmosphere tint={COLORS.crimson}>
      <Center style={{ flexDirection: vertical ? "column" : "row", gap: 60 * u }}>
        <Panel style={{ width: 640 * u, height: 760 * u, position: "relative", overflow: "hidden" }}>
          <div style={{ fontSize: 18 * u, letterSpacing: 4 * u, color: COLORS.muted }}>LEGALUS · VERTRAGSANALYSE</div>
          <div style={{ fontFamily: SERIF, fontSize: 36 * u, margin: `${10 * u}px 0 ${24 * u}px` }}>Liefervertrag „Atlas“</div>
          {new Array(16).fill(0).map((_, i) => {
            const tag = tags.find((t) => t.line === i);
            const hit = tag && scanY > (i / 16) * 100;
            return (
              <div key={i} style={{ height: 30 * u, display: "flex", alignItems: "center", gap: 12 * u, marginBottom: 10 * u }}>
                <div style={{ height: 8 * u, borderRadius: 4 * u, width: `${i % 5 === 4 ? 55 : 88}%`,
                  background: hit ? tag!.c : "rgba(233,230,223,0.16)", boxShadow: hit ? `0 0 ${16 * u}px ${tag!.c}` : "none" }} />
              </div>
            );
          })}
          <div style={{ position: "absolute", left: 0, right: 0, top: `${scanY}%`, height: 3 * u, background: COLORS.goldLight,
            boxShadow: `0 0 ${40 * u}px ${12 * u}px rgba(236,217,164,0.35)` }} />
        </Panel>
        <div style={{ display: "flex", flexDirection: "column", gap: 22 * u, width: 560 * u }}>
          <Panel start={50}>
            <div style={{ fontSize: 18 * u, color: COLORS.muted, letterSpacing: 3 * u }}>RISIKO-SCORE</div>
            <div style={{ fontFamily: SERIF, fontSize: 110 * u, color: score > 60 ? COLORS.crimson : COLORS.amber, lineHeight: 1 }}>{score}<span style={{ fontSize: 40 * u }}>/100</span></div>
          </Panel>
          {tags.map((t, i) => (
            <Panel key={t.t} start={70 + i * 45} style={{ borderLeft: `${5 * u}px solid ${t.c}`, fontSize: 24 * u }}>{t.t}</Panel>
          ))}
        </div>
      </Center>
    </Atmosphere>
  );
};

/* 8 ─ Zukunftssimulation: Entscheidungsbaum */
export const Zukunft: React.FC = () => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const branches = [
    { y: 120, t: "Szenario A · Klage", p: "38 %", e: "− 2,4 Mio €", c: COLORS.crimson },
    { y: 330, t: "Szenario B · Nachverhandlung", p: "51 %", e: "Risiko − 62 %", c: COLORS.green },
    { y: 540, t: "Szenario C · Vergleich", p: "11 %", e: "− 0,6 Mio €", c: COLORS.amber },
  ];
  const best = fade(f, 250, 30);
  return (
    <Atmosphere>
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <div style={{ position: "absolute", top: 80 * u, display: "flex", flexDirection: "column", alignItems: "center", gap: 12 * u }}>
          <Label>Stratego · Zukunftssimulation</Label>
          <RevealText text="Was passiert, wenn Klausel 14.2 eintritt?" size={52} start={10} />
        </div>
        <svg width={1600 * u} height={660 * u} viewBox="0 0 1600 660" style={{ marginTop: 140 * u }}>
          <circle cx="160" cy="330" r={26 * fade(f, 30)} fill={COLORS.crimson} />
          <circle cx="160" cy="330" r={26 + 30 * ((f % 40) / 40)} fill="none" stroke={COLORS.crimson} opacity={1 - (f % 40) / 40} />
          <text x="160" y="400" textAnchor="middle" fill={COLORS.text} fontFamily={SANS} fontSize="24">§14.2 tritt ein</text>
          {branches.map((b, i) => {
            const p = fade(f, 60 + i * 35, 45);
            const dim = b.c === COLORS.green ? 1 : 1 - best * 0.6;
            return (
              <g key={i} opacity={dim}>
                <path d={`M186 330 C 500 330, 500 ${b.y}, 820 ${b.y}`} fill="none" stroke={b.c} strokeWidth={b.c === COLORS.green ? 3 + best * 3 : 3}
                  strokeDasharray="800" strokeDashoffset={800 * (1 - p)} />
                <g opacity={fade(f, 95 + i * 35)}>
                  <rect x="840" y={b.y - 60} width="620" height="120" rx="14" fill="rgba(18,18,24,0.9)" stroke={b.c} />
                  <text x="870" y={b.y - 12} fill={COLORS.text} fontFamily={SERIF} fontSize="38">{b.t}</text>
                  <text x="870" y={b.y + 32} fill={COLORS.muted} fontFamily={SANS} fontSize="24">Wahrscheinlichkeit {b.p}  ·  {b.e}</text>
                </g>
              </g>
            );
          })}
        </svg>
        <div style={{ position: "absolute", bottom: 150 * u, opacity: best, fontFamily: SANS, fontSize: 28 * u, color: COLORS.green,
          border: `1px solid ${COLORS.green}`, padding: `${12 * u}px ${28 * u}px`, borderRadius: 40 * u, letterSpacing: 2 * u }}>
          Empfohlener Zug: Option B — vor Fristablauf nachverhandeln
        </div>
      </AbsoluteFill>
    </Atmosphere>
  );
};

/* 9 ─ Unternehmenskarte + Push-Nachricht aufs Handy */
export const Unternehmen: React.FC = () => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { u, vertical } = useUnit();
  const nodes = [
    { x: 400, y: 70, n: "CEO", s: "Strategie" },
    { x: 140, y: 260, n: "Recht", s: "3 Personen" }, { x: 400, y: 260, n: "Vertrieb", s: "5 Personen" }, { x: 660, y: 260, n: "Finanzen", s: "2 Personen" },
    { x: 60, y: 450, n: "L. Weber", s: "Vertragsrecht · frei" }, { x: 240, y: 450, n: "M. Kaya", s: "Compliance · 80 %" },
    { x: 400, y: 450, n: "J. Brandt", s: "Key Account" }, { x: 660, y: 450, n: "S. Roth", s: "Controlling" },
  ];
  const edges = [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [2, 6], [3, 7]];
  const pick = fade(f, 150, 20);
  const notif = spring({ frame: f - 230, fps, config: { damping: 14 } });
  return (
    <Atmosphere>
      <Center style={{ flexDirection: vertical ? "column" : "row", gap: 80 * u }}>
        <div>
          <Label>Organisation · Live</Label>
          <svg width={760 * u} height={560 * u} viewBox="0 0 760 540" style={{ overflow: "visible", marginTop: 20 * u }}>
            {edges.map(([a, b], i) => (
              <line key={i} x1={nodes[a].x} y1={nodes[a].y} x2={nodes[b].x} y2={nodes[b].y} stroke={COLORS.gold}
                strokeOpacity={0.4} strokeWidth="2" strokeDasharray="300" strokeDashoffset={300 * (1 - fade(f, 10 + i * 8, 30))} />
            ))}
            {pick > 0 && <line x1={nodes[0].x} y1={nodes[0].y} x2={nodes[4].x} y2={nodes[4].y} stroke={COLORS.goldLight} strokeWidth="4"
              strokeDasharray="500" strokeDashoffset={500 * (1 - pick)} />}
            {nodes.map((n, i) => {
              const hot = i === 4 && pick > 0.5;
              return (
                <g key={i} opacity={fade(f, 15 + i * 9)}>
                  <rect x={n.x - 80} y={n.y - 36} width="160" height="72" rx="12" fill="rgba(18,18,24,0.95)"
                    stroke={hot ? COLORS.goldLight : COLORS.line} strokeWidth={hot ? 3 : 1} />
                  <text x={n.x} y={n.y - 4} textAnchor="middle" fill={COLORS.text} fontFamily={SERIF} fontSize="26">{n.n}</text>
                  <text x={n.x} y={n.y + 22} textAnchor="middle" fill={hot ? COLORS.goldLight : COLORS.muted} fontFamily={SANS} fontSize="14">{n.s}</text>
                </g>
              );
            })}
          </svg>
        </div>
        <Phone start={180} scale={0.95}>
          <div style={{ textAlign: "center", fontSize: 64 * u, fontWeight: 200 }}>08:14</div>
          <div style={{ textAlign: "center", fontSize: 16 * u, color: COLORS.muted, marginBottom: 30 * u }}>Donnerstag, 12. November</div>
          <div style={{ transform: `translateY(${(1 - notif) * -200 * u}px)`, opacity: notif, background: "rgba(40,38,34,0.92)",
            borderRadius: 22 * u, padding: 18 * u, border: `1px solid ${COLORS.line}` }}>
            <div style={{ display: "flex", gap: 10 * u, alignItems: "center", fontSize: 14 * u, color: COLORS.gold, letterSpacing: 2 * u }}>
              <div style={{ width: 26 * u, height: 26 * u, borderRadius: 7 * u, background: COLORS.gold, color: "#000", textAlign: "center",
                fontFamily: SERIF, fontWeight: 700, fontSize: 20 * u, lineHeight: `${26 * u}px` }}>9</div> FENLY 9 · CEO
            </div>
            <div style={{ fontSize: 19 * u, fontWeight: 600, marginTop: 10 * u }}>Neue Aufgabe für Sie, Frau Weber</div>
            <div style={{ fontSize: 16 * u, color: "#cfcabb", marginTop: 6 * u, lineHeight: 1.4 }}>
              Bitte prüfen Sie §14.2 im Vertrag „Atlas“ bis Freitag. Sie haben die Qualifikation im Vertragsrecht und aktuell Kapazität.
            </div>
          </div>
        </Phone>
      </Center>
    </Atmosphere>
  );
};

/* 10 ─ Tagesbriefing für den CEO */
export const Briefing: React.FC = () => {
  const { u } = useUnit();
  const items = [
    ["Recht", "Vertrag „Atlas“: §14.2 in Prüfung (L. Weber)", COLORS.amber],
    ["Vertrieb", "2 Abschlüsse · Pipeline + 18 %", COLORS.green],
    ["Compliance", "Neue EU-Verordnung betrifft 3 Verträge", COLORS.crimson],
    ["Team", "M. Kaya zu 80 % ausgelastet", COLORS.muted],
  ];
  return (
    <Atmosphere>
      <Center>
        <Panel style={{ width: 900 * u }} glow="rgba(201,169,97,0.1)">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
            <div style={{ fontFamily: SERIF, fontSize: 52 * u }}>Ihr Briefing</div>
            <div style={{ fontSize: 20 * u, color: COLORS.gold, letterSpacing: 3 * u }}>07:00 · 90 SEKUNDEN</div>
          </div>
          {items.map(([k, t, c], i) => (
            <Panel key={k} start={25 + i * 28} style={{ marginTop: 18 * u, display: "flex", gap: 20 * u, alignItems: "center", padding: 20 * u }}>
              <div style={{ width: 12 * u, height: 12 * u, borderRadius: 6 * u, background: c, boxShadow: `0 0 ${12 * u}px ${c}` }} />
              <div style={{ width: 170 * u, fontSize: 18 * u, color: COLORS.muted, letterSpacing: 2 * u, textTransform: "uppercase" }}>{k}</div>
              <div style={{ fontSize: 24 * u }}>{t}</div>
            </Panel>
          ))}
        </Panel>
      </Center>
    </Atmosphere>
  );
};

/* 11 ─ Angreifbarkeit: Du vs. Konkurrent (Radar) */
const Radar: React.FC<{ vals: number[]; color: string; start: number; weak: number; title: string }> = ({ vals, color, start, weak, title }) => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const axes = ["Verträge", "Compliance", "IP", "Personal", "Finanzen", "Markt"];
  const p = fade(f, start, 40);
  const pt = (i: number, r: number) => {
    const a = (Math.PI * 2 * i) / 6 - Math.PI / 2;
    return [200 + Math.cos(a) * r * 150, 200 + Math.sin(a) * r * 150];
  };
  const pulse = 0.5 + 0.5 * Math.sin(f / 5);
  return (
    <div style={{ textAlign: "center" }}>
      <div style={{ fontFamily: SERIF, fontSize: 44 * u, color: COLORS.text }}>{title}</div>
      <svg width={460 * u} height={460 * u} viewBox="-30 -30 460 460">
        {[0.33, 0.66, 1].map((r) => <polygon key={r} points={axes.map((_, i) => pt(i, r).join(",")).join(" ")} fill="none" stroke={COLORS.line} />)}
        <polygon points={vals.map((v, i) => pt(i, v * p).join(",")).join(" ")} fill={color} fillOpacity={0.18} stroke={color} strokeWidth="3" />
        {axes.map((a, i) => { const [x, y] = pt(i, 1.17); return <text key={a} x={x} y={y + 6} textAnchor="middle" fill={COLORS.muted} fontFamily={SANS} fontSize="17">{a}</text>; })}
        {p > 0.9 && (() => { const [x, y] = pt(weak, vals[weak]); return <circle cx={x} cy={y} r={10 + pulse * 14} fill={COLORS.crimson} opacity={0.4 + pulse * 0.4} />; })()}
      </svg>
    </div>
  );
};
export const Angriff: React.FC = () => {
  const { u, vertical } = useUnit();
  return (
    <Atmosphere tint={COLORS.crimson}>
      <Center gap={20}>
        <Label color={COLORS.crimson}>Schwachstellen-Analyse</Label>
        <div style={{ display: "flex", flexDirection: vertical ? "column" : "row", gap: 120 * u }}>
          <Radar title="Ihr Unternehmen" vals={[0.85, 0.4, 0.75, 0.8, 0.7, 0.65]} color={COLORS.gold} start={15} weak={1} />
          <Radar title="Konkurrent" vals={[0.45, 0.8, 0.6, 0.5, 0.85, 0.7]} color={COLORS.muted} start={60} weak={0} />
        </div>
        <RevealText text="Kenne deine Schwäche — bevor es dein Gegner tut." size={50} start={170} color={COLORS.goldLight} />
      </Center>
    </Atmosphere>
  );
};

/* 12 ─ Finale */
export const Finale: React.FC = () => {
  const f = useCurrentFrame();
  const { u } = useUnit();
  const out = interpolate(f, [130, 150], [1, 0], clamp);
  return (
    <Atmosphere>
      <Center style={{ opacity: out }}>
        <RevealText text="RECHT IST MACHT." size={120} start={5} stagger={10} spacing={10} weight={600} />
        <RevealText text="WISSEN IST VORSPRUNG." size={60} start={50} stagger={10} spacing={10} color={COLORS.gold} />
      </Center>
      <Center gap={40} style={{ opacity: fade(f, 150, 30) }}>
        {f > 145 && <Logo start={150} />}
        <div style={{ opacity: fade(f, 200, 30), fontFamily: SERIF, fontStyle: "italic", fontSize: 48 * u, color: COLORS.goldLight }}>Sieh, was kommt.</div>
        <div style={{ opacity: fade(f, 230, 30), fontFamily: SANS, fontSize: 22 * u, letterSpacing: 6 * u, color: COLORS.muted }}>JETZT DEMO ANFRAGEN · FENLY9</div>
      </Center>
    </Atmosphere>
  );
};
