import * as THREE from 'three'
import { atom, bond, glass, label, std, tube, V } from '../../three/lib'

/**
 * Proteinstruktur: α-Helix und β-Faltblatt mit korrekten Ramachandran-Parametern,
 * dazu die Hierarchie Primär- bis Quartärstruktur.
 * Maßstab: 1 Einheit = 1 Å.
 */
export default {
  id: 'protein',
  name: 'Proteinstruktur',
  discipline: 'biologie',
  level: 'Bachelor',
  tagline: 'α-Helix, β-Faltblatt und Faltungshierarchie',
  scale: '1 Einheit = 1 Å',

  build() {
    const group = new THREE.Group()
    const helix = new THREE.Group()
    const faltblatt = new THREE.Group()
    const tertiaer = new THREE.Group()
    const beschriftung = new THREE.Group()
    // H-Brücken hängen jeweils in ihrer eigenen Struktur, damit sie deren
    // Rotation mitmachen. Die Ebenen-Umschaltung fasst beide zusammen.
    const hbHelix = new THREE.Group()
    const hbBlatt = new THREE.Group()

    // ------------------------------------------------ α-Helix (rechtsgängig)
    // Reale Parameter: 3,6 Reste/Windung, 1,5 Å Anstieg, Cα-Radius 2,3 Å,
    // Ganghöhe 5,4 Å, φ = −57°, ψ = −47°
    helix.position.set(-13, 0, 0)
    const resteHelix = 26
    const helixR = 2.3
    const anstieg = 1.5
    const drehung = (2 * Math.PI) / 3.6
    const caHelix = []

    for (let i = 0; i < resteHelix; i++) {
      const w = i * drehung
      const p = V(Math.cos(w) * helixR, (i - resteHelix / 2) * anstieg, Math.sin(w) * helixR)
      caHelix.push(p)
      helix.add(atom(p, 0.55, i % 2 ? 0x4dabf7 : 0x74c0fc, { segments: 16 }))
      // Seitenketten ragen radial nach außen
      const aussen = p.clone().setY(p.y).multiplyScalar(1.0)
      aussen.x *= 1.9
      aussen.z *= 1.9
      helix.add(bond(p, aussen, { radius: 0.14, color: 0xadb5bd }))
      helix.add(atom(aussen, 0.32, 0xffd43b, { segments: 12 }))
    }
    // Rückgrat als Band
    helix.add(tube(caHelix, 0.85, std(0x4dabf7, { roughness: 0.4 }), { tubularSegments: 300 }))

    // H-Brücken C=O(i) ··· H–N(i+4): das definierende Merkmal der α-Helix
    for (let i = 0; i < resteHelix - 4; i++) {
      hbHelix.add(bond(caHelix[i], caHelix[i + 4], { radius: 0.1, color: 0xff922b }))
    }
    helix.add(hbHelix)

    helix.add(
      label('α-Helix', [0, resteHelix * anstieg * 0.5 + 3, 0], 'accent'),
      label('3,6 Reste/Windung · Anstieg 1,5 Å · Ganghöhe 5,4 Å', [0, resteHelix * anstieg * 0.5 + 1.6, 0], 'muted'),
      label('H-Brücke C=O(i) ··· H–N(i+4)', [0, -resteHelix * anstieg * 0.5 - 2, 0], 'warm'),
      label('φ = −57° · ψ = −47°', [0, -resteHelix * anstieg * 0.5 - 3.4, 0], 'muted'),
    )

    // ------------------------------------------- antiparalleles β-Faltblatt
    faltblatt.position.set(2, 0, 0)
    const straenge = 4
    const resteStrang = 9
    const strangAbstand = 4.8 // Å zwischen benachbarten Strängen
    const restAbstand = 3.3 // Å Anstieg pro Rest
    const strangPunkte = []

    for (let s = 0; s < straenge; s++) {
      const pts = []
      const richtung = s % 2 === 0 ? 1 : -1 // antiparallel
      for (let i = 0; i < resteStrang; i++) {
        const y = richtung * (i - resteStrang / 2) * restAbstand
        // Pleated sheet: Zickzack senkrecht zur Blattebene
        const z = (i % 2 === 0 ? 1 : -1) * 0.9
        pts.push(V((s - (straenge - 1) / 2) * strangAbstand, y, z))
      }
      strangPunkte.push(pts)
      pts.forEach((p) => faltblatt.add(atom(p, 0.5, s % 2 === 0 ? 0x51cf66 : 0x2f9e44, { segments: 14 })))
      faltblatt.add(tube(pts, 0.7, std(s % 2 === 0 ? 0x51cf66 : 0x2f9e44, { roughness: 0.45 }), { tubularSegments: 100 }))
      // Pfeilspitze zeigt die N→C-Richtung
      const letzte = pts[pts.length - 1]
      const kegel = new THREE.Mesh(new THREE.ConeGeometry(1.3, 2.4, 16), std(s % 2 === 0 ? 0x51cf66 : 0x2f9e44))
      kegel.position.copy(letzte).add(V(0, richtung * 1.6, 0))
      kegel.rotation.z = richtung > 0 ? 0 : Math.PI
      faltblatt.add(kegel)
    }

    // Interstrang-H-Brücken – bei antiparalleler Anordnung linear und damit stärker
    for (let s = 0; s < straenge - 1; s++) {
      for (let i = 0; i < resteStrang; i++) {
        const a = strangPunkte[s][i]
        const b = strangPunkte[s + 1][resteStrang - 1 - i]
        if (Math.abs(a.y - b.y) < 1.2) {
          hbBlatt.add(bond(a, b, { radius: 0.09, color: 0xff922b }))
        }
      }
    }
    faltblatt.add(hbBlatt)

    faltblatt.add(
      label('antiparalleles β-Faltblatt', [0, resteStrang * restAbstand * 0.5 + 4, 0], 'green'),
      label('Anstieg 3,3 Å/Rest · Strangabstand 4,8 Å · φ = −139° · ψ = +135°', [0, resteStrang * restAbstand * 0.5 + 2.6, 0], 'muted'),
      label('antiparallel: lineare H-Brücken → stabiler als parallel', [0, -resteStrang * restAbstand * 0.5 - 2.4, 0], 'muted'),
    )

    // -------------------------------------------------- Tertiärstruktur (Globulär)
    tertiaer.position.set(16, 0, 0)
    const faltungPunkte = []
    const n = 90
    for (let i = 0; i < n; i++) {
      const t = i / n
      // Pseudozufällige, aber deterministische globuläre Faltung
      const r = 5.5 * (0.55 + 0.45 * Math.sin(t * 7.3))
      const th = t * Math.PI * 8.5
      const ph = Math.acos(1 - 2 * ((t * 3.7) % 1))
      faltungPunkte.push(
        V(r * Math.sin(ph) * Math.cos(th), r * Math.cos(ph) * 1.1, r * Math.sin(ph) * Math.sin(th)),
      )
    }
    const kette = tube(faltungPunkte, 0.55, std(0x9775fa, { roughness: 0.4 }), { tubularSegments: 600 })
    tertiaer.add(kette)

    // Hydrophober Kern
    const kern = new THREE.Mesh(new THREE.SphereGeometry(2.6, 32, 24), glass(0xffd43b, 0.3))
    tertiaer.add(kern)
    tertiaer.add(label('hydrophober Kern', [0, 0, 4.5], 'warm'))

    // Disulfidbrücke Cys–Cys
    const cys1 = faltungPunkte[18]
    const cys2 = faltungPunkte[62]
    tertiaer.add(atom(cys1, 0.6, 0xfcc419), atom(cys2, 0.6, 0xfcc419))
    tertiaer.add(bond(cys1, cys2, { radius: 0.22, color: 0xfcc419 }))
    tertiaer.add(
      label('Tertiärstruktur', [0, 9, 0], 'accent2'),
      label('Disulfidbrücke (Cys–Cys)', [0, -8, 0], 'warm'),
      label('Faltung getrieben vom hydrophoben Effekt (Entropie des Wassers)', [0, -9.6, 0], 'muted'),
    )

    group.add(helix, faltblatt, tertiaer, beschriftung)

    return {
      group,
      camera: { position: [0, 8, 58], target: [1, 0, 0] },
      layers: [
        { id: 'helix', name: 'α-Helix', objects: [helix] },
        { id: 'blatt', name: 'β-Faltblatt', objects: [faltblatt] },
        { id: 'tertiaer', name: 'Tertiärstruktur', objects: [tertiaer] },
        { id: 'hbruecken', name: 'Wasserstoffbrücken', objects: [hbHelix, hbBlatt] },
      ],
      update(t) {
        helix.rotation.y = t * 0.35
        faltblatt.rotation.y = Math.sin(t * 0.3) * 0.6
        tertiaer.rotation.y = t * 0.28
        kern.material.opacity = 0.2 + 0.12 * Math.sin(t * 1.4)
      },
    }
  },

  info: {
    summary:
      'Sekundärstrukturen entstehen ausschließlich durch Wasserstoffbrücken des Peptidrückgrats – unabhängig von den Seitenketten. Genau deshalb sind α-Helix und β-Faltblatt universell: Pauling sagte beide 1951 rein theoretisch voraus, bevor sie experimentell bestätigt wurden.',
    sections: [
      {
        title: 'Die Peptidbindung',
        body: [
          'Die C–N-Bindung besitzt durch Mesomerie etwa 40 % Doppelbindungscharakter. Sie ist mit 133 pm kürzer als eine normale C–N-Einfachbindung (147 pm) und nicht frei drehbar.',
          'Damit sind sechs Atome (Cα, C, O, N, H, Cα) starr in einer Ebene. Frei drehbar bleiben nur die Winkel φ (N–Cα) und ψ (Cα–C).',
          'Über 99 % aller Peptidbindungen liegen in trans-Konfiguration vor. Ausnahme ist Prolin, bei dem cis energetisch fast gleichwertig ist – die cis/trans-Isomerisierung ist dort oft der geschwindigkeitsbestimmende Schritt der Faltung (katalysiert durch Peptidyl-Prolyl-Isomerasen).',
          'Der Ramachandran-Plot trägt ψ gegen φ auf und zeigt die sterisch erlaubten Bereiche – die Cluster entsprechen genau α-Helix und β-Faltblatt.',
        ],
      },
      {
        title: 'α-Helix',
        body: [
          '3,6 Aminosäurereste pro Windung, Anstieg 1,5 Å pro Rest, Ganghöhe 5,4 Å. Die Helix ist rechtsgängig (φ = −57°, ψ = −47°).',
          'Jede C=O-Gruppe bildet eine Wasserstoffbrücke zur N–H-Gruppe des vierten folgenden Restes (i → i+4). Alle Rückgrat-H-Brücken sind dadurch abgesättigt und nahezu parallel zur Helixachse ausgerichtet.',
          'Die Seitenketten weisen nach außen. Da 3,6 Reste einer Windung entsprechen, liegen Reste im Abstand von 3–4 Positionen auf derselben Seite – Grundlage amphipathischer Helices in Membranproteinen und Coiled-Coils.',
          'Prolin ist ein Helixbrecher (kein N–H für die Brücke, starrer Ring), Glycin destabilisiert durch zu hohe Flexibilität.',
        ],
      },
      {
        title: 'β-Faltblatt',
        body: [
          'Fast vollständig gestreckte Konformation: 3,3 Å pro Rest (gegenüber 1,5 Å in der Helix). Die Seitenketten zeigen abwechselnd nach oben und unten.',
          'H-Brücken verlaufen zwischen benachbarten Strängen, nicht innerhalb eines Strangs. Antiparallele Blätter haben lineare und damit stärkere Brücken; parallele sind leicht abgewinkelt und benötigen längere Verbindungsschleifen.',
          'β-Faltblätter zeigen typischerweise eine leichte Rechtsverdrillung, weil die L-Aminosäuren chiral sind.',
          'Fehlfaltung in β-reiche Amyloidstrukturen ist pathogen: Alzheimer (Aβ, Tau), Parkinson (α-Synuclein), Prionerkrankungen, Typ-2-Diabetes (IAPP).',
        ],
      },
      {
        title: 'Faltung und Hierarchie',
        body: [
          'Primärstruktur: Aminosäuresequenz. Sekundär: lokale Rückgratmuster. Tertiär: räumliche Anordnung einer Kette. Quartär: Zusammenlagerung mehrerer Untereinheiten (z. B. Hämoglobin α₂β₂).',
          'Die Faltung wird nicht primär von Wasserstoffbrücken getrieben, sondern vom hydrophoben Effekt: Das Verbergen unpolarer Seitenketten im Kern setzt geordnete Wassermoleküle frei – ein Entropiegewinn des Lösungsmittels.',
          'Anfinsens Experiment mit Ribonuklease A zeigte, dass die Sequenz die Struktur vollständig bestimmt (Thermodynamische Hypothese). Levinthals Paradox verdeutlicht, dass die Faltung dennoch nicht durch Zufallssuche erfolgen kann, sondern über einen Energietrichter mit Faltungsintermediaten.',
          'Die Netto-Stabilität globulärer Proteine ist erstaunlich gering: nur 20–60 kJ/mol, entsprechend wenigen Wasserstoffbrücken. Proteine sind marginal stabil – vermutlich, weil Regulierbarkeit und Abbaubarkeit selektiert wurden.',
        ],
      },
    ],
    facts: [
      { k: 'α-Helix: Reste/Windung', v: '3,6' },
      { k: 'α-Helix: Anstieg', v: '1,5 Å/Rest' },
      { k: 'α-Helix: φ / ψ', v: '−57° / −47°' },
      { k: 'β-Faltblatt: Anstieg', v: '3,3 Å/Rest' },
      { k: 'β-Faltblatt: φ / ψ', v: '−139° / +135°' },
      { k: 'Peptidbindung C–N', v: '133 pm (40 % DB-Charakter)' },
      { k: 'Faltungsstabilität', v: '20–60 kJ/mol' },
      { k: 'Anteil trans-Peptidbindungen', v: '> 99 %' },
    ],
    exam: [
      'Warum ist die Peptidbindung planar? Mesomerie zeichnen.',
      'Ramachandran-Plot: erlaubte Bereiche den Sekundärstrukturen zuordnen; Sonderrolle von Glycin und Prolin.',
      'H-Brücken-Muster i→i+4 gegenüber Interstrang-Brücken abgrenzen.',
      'Warum treibt der hydrophobe Effekt die Faltung, obwohl er entropisch beschrieben wird?',
    ],
  },
}
