import React from "react";
import { T, S } from "../shared/tokens";
import { Reveal, Orbs } from "../shared/Reveal";
import { GrowthChart } from "../shared/GrowthChart";
import { AnimatedNumber } from "../shared/AnimatedNumber";
import { Logo } from "../shared/Logo";
import { fmt, futureValue } from "../shared/format";

const brandStrip = [
  { name: "Netflix", domain: "netflix.com", color: "#E50914", letter: "N" },
  { name: "Spotify", domain: "spotify.com", color: "#1DB954", letter: "S" },
  { name: "Adobe", domain: "adobe.com", color: "#FF0000", letter: "A" },
  { name: "Amazon", domain: "amazon.de", color: "#FF9900", letter: "P" },
  { name: "Vodafone", domain: "vodafone.de", color: "#E60000", letter: "V" },
  { name: "Disney+", domain: "disneyplus.com", color: "#113CCF", letter: "D" },
  { name: "Klarna", domain: "klarna.com", color: "#FFB3C7", letter: "K" },
  { name: "PayPal", domain: "paypal.com", color: "#003087", letter: "P" },
];

export default function Landing({ onStart }) {
  return (
    <div style={S.page}>
      <Orbs />
      <nav style={{ position: "sticky", top: 0, zIndex: 10, backdropFilter: "blur(24px)", background: "rgba(5,5,8,0.7)", borderBottom: `1px solid ${T.border}` }}>
        <div style={{ ...S.container, display: "flex", justifyContent: "space-between", alignItems: "center", height: 60 }}>
          <div style={{ fontWeight: 700, fontSize: 19, letterSpacing: -0.5 }}>
            Abo<span style={{ background: `linear-gradient(90deg, ${T.green}, ${T.teal})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Wandler</span>
          </div>
          <button style={{ ...S.btn, padding: "9px 20px", fontSize: 14 }} onClick={onStart}>App starten</button>
        </div>
      </nav>

      <section style={{ ...S.container, textAlign: "center", padding: "110px 24px 60px" }}>
        <Reveal><div style={{ ...S.tag(T.green), marginBottom: 24 }}>✦ KI-gestützter Finanz-Check</div></Reveal>
        <Reveal delay={0.1}>
          <h1 style={{ fontSize: "clamp(40px, 7vw, 76px)", fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1.05, margin: "0 0 24px" }}>
            Dein Netflix-Abo<br />
            <span style={{ background: `linear-gradient(90deg, ${T.green}, ${T.teal}, ${T.purple})`, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>wird zu Vermögen.</span>
          </h1>
        </Reveal>
        <Reveal delay={0.2}>
          <p style={{ fontSize: 20, color: T.textDim, maxWidth: 560, margin: "0 auto 40px", lineHeight: 1.5 }}>
            Verbinde Bankkonto, PayPal & Co. — die KI findet vergessene Abos und dubiose Abbuchungen und zeigt, was aus dem Geld werden könnte, wenn du es stattdessen investierst.
          </p>
        </Reveal>
        <Reveal delay={0.3}>
          <div style={{ display: "flex", gap: 14, justifyContent: "center", flexWrap: "wrap" }}>
            <button style={S.btn} onClick={onStart}>Kostenlos analysieren →</button>
            <button style={S.btnGhost} onClick={() => document.getElementById("how")?.scrollIntoView({ behavior: "smooth" })}>So funktioniert's</button>
          </div>
        </Reveal>
      </section>

      {/* Brand marquee — in-sync.io-style continuous scroll */}
      <section style={{ paddingBottom: 70, overflow: "hidden" }}>
        <style>{`
          @keyframes marquee { 0% { transform: translateX(0); } 100% { transform: translateX(-50%); } }
        `}</style>
        <div style={{ display: "flex", width: "max-content", animation: "marquee 24s linear infinite", gap: 40, alignItems: "center" }}>
          {[...brandStrip, ...brandStrip].map((b, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, opacity: 0.75 }}>
              <Logo domain={b.domain} letter={b.letter} color={b.color} size={32} />
              <span style={{ color: T.textDim, fontSize: 15, fontWeight: 550 }}>{b.name}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Animated stat row */}
      <section style={{ ...S.container, paddingBottom: 70 }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 20 }}>
          {[
            { value: 47, suffix: " €", label: "Ø vergessenes Abo pro Monat" },
            { value: 1250000, format: (v) => fmt(v), label: "Möglicher Vermögensaufbau in 25 J.*" },
            { value: 12, suffix: "+", label: "Erkannte Betrugsmuster-Kategorien" },
          ].map((s, i) => (
            <Reveal key={i} delay={i * 0.1}>
              <div style={{ ...S.card, textAlign: "center" }}>
                <div style={{ fontSize: 32, fontWeight: 700, color: T.green, letterSpacing: -0.5 }}>
                  <AnimatedNumber value={s.value} format={s.format || ((v) => Math.round(v) + (s.suffix || ""))} />
                </div>
                <div style={{ fontSize: 13.5, color: T.textDim, marginTop: 8 }}>{s.label}</div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      <section style={{ ...S.container, paddingBottom: 100 }}>
        <Reveal>
          <div style={{ ...S.card, padding: 36 }}>
            <div style={{ display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 16, marginBottom: 20 }}>
              <div>
                <div style={{ fontSize: 14, color: T.textDim }}>Beispiel: Adobe-Abo (59,99 €/Monat) → MSCI World, 25 Jahre</div>
                <div style={{ fontSize: 34, fontWeight: 700, letterSpacing: -1 }}>≈ {fmt(futureValue(59.99, 7.1, 25))}</div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 14, color: T.textDim }}>Möglicher Renten-Boost*</div>
                <div style={{ fontSize: 26, fontWeight: 700, color: T.green }}>+{fmt(futureValue(59.99, 7.1, 25) * 0.04 / 12)}/Monat</div>
              </div>
            </div>
            <GrowthChart monthly={59.99} ret={7.1} years={25} />
            <p style={{ fontSize: 12, color: T.textFaint, marginTop: 14 }}>
              *Modellrechnung auf Basis historischer Durchschnittsrenditen. Keine Garantie, keine Anlageberatung. Vergangene Wertentwicklung ist kein Indikator für zukünftige Ergebnisse.
            </p>
          </div>
        </Reveal>
      </section>

      <section id="how" style={{ ...S.container, paddingBottom: 100 }}>
        <Reveal><h2 style={{ fontSize: 40, fontWeight: 700, letterSpacing: -1, textAlign: "center", marginBottom: 56 }}>Drei Schritte zur Klarheit</h2></Reveal>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: 20 }}>
          {[
            { icon: "🔗", t: "Verbinden oder hochladen", d: "Girokonto, PayPal, Kreditkarte, Klarna verbinden — oder Kontoauszüge als PDF/CSV hochladen bzw. Text einfügen. Die KI liest alles.", c: T.teal },
            { icon: "🧠", t: "KI prüft alles", d: "Wiederkehrende Zahlungen, unbekannte Empfänger, ausländische IBANs, Preissteigerungen — recherchiert und bewertet, inkl. Firmen-Hintergrundcheck.", c: T.purple },
            { icon: "📈", t: "Umwandeln statt verlieren", d: "Unnötige Abos kündigen (KI schreibt den Kündigungsbrief) und denselben Betrag in einen ETF-Sparplan umleiten.", c: T.green },
          ].map((f, i) => (
            <Reveal key={i} delay={i * 0.12}>
              <div style={{ ...S.card, height: "100%", boxSizing: "border-box" }}>
                <div style={{ fontSize: 36, marginBottom: 16 }}>{f.icon}</div>
                <h3 style={{ fontSize: 20, fontWeight: 650, margin: "0 0 10px", color: f.c }}>{f.t}</h3>
                <p style={{ color: T.textDim, lineHeight: 1.55, margin: 0, fontSize: 15 }}>{f.d}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      <section style={{ ...S.container, paddingBottom: 100 }}>
        <Reveal><h2 style={{ fontSize: 40, fontWeight: 700, letterSpacing: -1, textAlign: "center", marginBottom: 12 }}>Mehr als nur Tracking</h2></Reveal>
        <Reveal delay={0.1}><p style={{ textAlign: "center", color: T.textDim, marginBottom: 56, fontSize: 17 }}>Was AboWandler anders macht als klassische Finanz-Apps</p></Reveal>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(250px, 1fr))", gap: 16 }}>
          {[
            ["⚠ Betrugs-Radar", "KI recherchiert unbekannte Zahlungsempfänger im Web: Existiert die Firma? Gibt es Beschwerden? Passt der Betrag?"],
            ["📄 Firmen-Berichte", "Zu jedem Abo ein ladbarer KI-Bericht über den Anbieter — Seriosität, Historie, Risiko-Einschätzung."],
            ["✉ Kündigungs-Assistent", "Die KI schreibt dir den fertigen Kündigungsbrief für jedes Abo — zum Kopieren oder Herunterladen."],
            ["🔄 Abo-zu-ETF-Wandler", "Der einzige Rechner, der aus deiner Kündigung eine konkrete Renten-Prognose macht — inkl. ETF-Vergleich und Portfolio-Mix."],
            ["🕰 Alters- & Preis-Radar", "Erkennt automatisch stille Preiserhöhungen und erinnert dich an nie überprüfte Alt-Abos."],
            ["📊 Abo-Gesundheits-Score", "Ein Score von 0-100 zeigt auf einen Blick, wie gesund dein Abo-Portfolio ist."],
            ["✉ Zugangs-Verwaltung", "E-Mail, Nutzername und Passwort pro Abo sicher (verschlüsselt) hinterlegen — nie wieder suchen beim Kündigen."],
            ["💶 Faire KI-Kosten", "Du zahlst KI-Analysen transparent nach Nutzung. Keine versteckten Gebühren."],
          ].map(([t, d], i) => (
            <Reveal key={i} delay={(i % 4) * 0.08}>
              <div style={{ ...S.card, padding: 20, height: "100%", boxSizing: "border-box" }}>
                <div style={{ fontWeight: 650, marginBottom: 8, fontSize: 16 }}>{t}</div>
                <div style={{ color: T.textDim, fontSize: 14, lineHeight: 1.5 }}>{d}</div>
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      <section style={{ ...S.container, paddingBottom: 120, textAlign: "center" }}>
        <Reveal>
          <div style={{ ...S.card, padding: "64px 32px", background: "linear-gradient(135deg, rgba(48,209,88,0.10), rgba(100,210,255,0.08))" }}>
            <h2 style={{ fontSize: 36, fontWeight: 700, letterSpacing: -1, margin: "0 0 16px" }}>Bereit für den Abo-Check?</h2>
            <p style={{ color: T.textDim, marginBottom: 32, fontSize: 17 }}>Finde in 2 Minuten heraus, wo dein Geld wirklich hingeht.</p>
            <button style={S.btn} onClick={onStart}>Jetzt starten — kostenlos →</button>
          </div>
        </Reveal>
        <p style={{ fontSize: 12, color: T.textFaint, marginTop: 40, maxWidth: 640, margin: "40px auto 0", lineHeight: 1.6 }}>
          AboWandler bietet keine Finanz- oder Anlageberatung. Alle Prognosen sind Modellrechnungen ohne Garantie. Investments bergen Verlustrisiken. Die Nutzung erfolgt auf eigenes Risiko.
        </p>
      </section>
    </div>
  );
}
