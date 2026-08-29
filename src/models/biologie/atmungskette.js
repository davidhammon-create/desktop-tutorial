import * as THREE from 'three'
import { arrow, atom, bond, glass, glow, label, lipidBilayer, rng, std, V } from '../../three/lib'

/**
 * Innere Mitochondrienmembran: Atmungskette (Komplex I–IV), Protonengradient
 * und rotierende F₀F₁-ATP-Synthase.
 * Maßstab: 1 Einheit ≈ 1 nm.
 */
export default {
  id: 'atmungskette',
  name: 'Atmungskette & ATP-Synthase',
  discipline: 'biologie',
  level: 'Master',
  tagline: 'Chemiosmose, Protonengradient und Rotationskatalyse',
  scale: '1 Einheit ≈ 1 nm',

  build() {
    const group = new THREE.Group()
    const membranG = new THREE.Group()
    const komplexe = new THREE.Group()
    const protonen = new THREE.Group()
    const synthase = new THREE.Group()
    const elektronen = new THREE.Group()
    const beschriftung = new THREE.Group()
    const zufall = rng(13)

    // --- Innere Mitochondrienmembran --------------------------------------------
    const membran = lipidBilayer(46, 14, {
      spacing: 0.95,
      headRadius: 0.3,
      thickness: 1.5,
      headColor: 0x4dabf7,
      tailColor: 0xffd43b,
    })
    membranG.add(membran)
    membranG.add(
      label('Intermembranraum – hohe H⁺-Konzentration, pH ≈ 6,9', [0, 6.5, 0], 'warm'),
      label('Matrix – pH ≈ 7,9', [0, -6.5, 0], 'accent'),
    )

    // --- Atmungskettenkomplexe ---------------------------------------------------
    const definition = [
      { x: -17, name: 'Komplex I', unter: 'NADH-Dehydrogenase', h: 4, farbe: 0x5b8def, breite: 4.5 },
      { x: -9, name: 'Komplex II', unter: 'Succinat-DH (0 H⁺)', h: 0, farbe: 0x51cf66, breite: 3.2 },
      { x: -1, name: 'Komplex III', unter: 'Cytochrom-bc₁', h: 4, farbe: 0x9775fa, breite: 4.0 },
      { x: 7.5, name: 'Komplex IV', unter: 'Cytochrom-c-Oxidase', h: 2, farbe: 0xff922b, breite: 4.0 },
    ]

    const komplexObjekte = []
    definition.forEach((k) => {
      const körper = new THREE.Mesh(
        new THREE.CylinderGeometry(k.breite / 2, k.breite / 2 * 0.8, k.h === 0 ? 3.0 : 5.5, 24),
        std(k.farbe, { roughness: 0.4, metalness: 0.2 }),
      )
      körper.position.set(k.x, k.h === 0 ? -1.2 : 0.4, 0)
      komplexe.add(körper)
      komplexObjekte.push(körper)

      beschriftung.add(
        label(k.name, [k.x, 4.6, 0], 'accent'),
        label(k.unter, [k.x, 3.9, 0], 'muted'),
        label(k.h > 0 ? `${k.h} H⁺` : 'kein H⁺-Pumpen', [k.x, -4.4, 0], k.h > 0 ? 'warm' : 'muted'),
      )
    })

    // Mobile Elektronenüberträger: Ubichinon (Q) und Cytochrom c
    const ubichinon = atom([-5, -0.6, 1.6], 0.55, 0xffd43b, { material: glow(0xffd43b, 0.6) })
    const cytc = atom([3.4, 3.2, 1.2], 0.5, 0xe03131, { material: glow(0xe03131, 0.6) })
    komplexe.add(ubichinon, cytc)
    beschriftung.add(
      label('Q (Ubichinon) – membranlöslich', [-5, -2.6, 2.6], 'muted'),
      label('Cyt c – peripher, wasserlöslich', [3.4, 4.4, 2.4], 'muted'),
    )

    // --- F₀F₁-ATP-Synthase --------------------------------------------------------
    const synthaseX = 17
    // F₀: c-Ring (human c₈) in der Membran
    const cRing = new THREE.Group()
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * Math.PI * 2
      const c = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.42, 3.6, 12), std(0x22b8cf, { roughness: 0.4 }))
      c.position.set(Math.cos(a) * 1.5, 0, Math.sin(a) * 1.5)
      cRing.add(c)
    }
    cRing.position.set(synthaseX, 0, 0)
    synthase.add(cRing)

    // a-Untereinheit: enthält die beiden Halbkanäle
    const aUnter = new THREE.Mesh(new THREE.BoxGeometry(1.3, 3.6, 2.2), std(0xfa5252, { roughness: 0.45 }))
    aUnter.position.set(synthaseX - 2.6, 0, 0)
    synthase.add(aUnter)

    // γ-Achse (zentraler Stiel)
    const gamma = new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.7, 6.5, 16), std(0xffd43b, { metalness: 0.5, roughness: 0.3 }))
    gamma.position.set(synthaseX, -4.4, 0)
    synthase.add(gamma)

    // F₁-Kopf: α₃β₃-Hexamer
    const f1 = new THREE.Group()
    const betaUnter = []
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * Math.PI * 2
      const istBeta = i % 2 === 1
      const u = new THREE.Mesh(
        new THREE.SphereGeometry(1.5, 24, 18),
        std(istBeta ? 0xe8590c : 0x862e9e, { roughness: 0.45 }),
      )
      u.position.set(Math.cos(a) * 1.7, 0, Math.sin(a) * 1.7)
      u.scale.y = 1.3
      f1.add(u)
      if (istBeta) betaUnter.push(u)
    }
    f1.position.set(synthaseX, -8.2, 0)
    synthase.add(f1)

    // Peripherer Stiel (b₂-δ) verhindert Mitrotation des Kopfes
    synthase.add(
      bond([synthaseX - 2.6, 1.6, 0], [synthaseX - 1.6, -8.2, 0], { radius: 0.28, color: 0x495057 }),
    )

    // ATP-Produkte
    const atpMolekuele = []
    for (let i = 0; i < 6; i++) {
      const m = atom([synthaseX, -11, 0], 0.45, 0x51cf66, { material: glow(0x51cf66, 0.8) })
      m.userData.phase = (i / 6) * Math.PI * 2
      m.visible = false
      synthase.add(m)
      atpMolekuele.push(m)
    }

    beschriftung.add(
      label('ATP-Synthase (Komplex V)', [synthaseX, 5.4, 0], 'green'),
      label('F₀: c₈-Ring + a-Untereinheit', [synthaseX, 4.6, 0], 'muted'),
      label('γ-Achse dreht im α₃β₃-Kopf', [synthaseX + 5.5, -5.5, 0], 'warm'),
      label('F₁: α₃β₃ – Bindungswechsel-Mechanismus', [synthaseX, -11.6, 0], 'accent2'),
      label('8 H⁺ pro Umdrehung → 3 ATP  (2,7 H⁺/ATP)', [synthaseX, -12.6, 0], 'muted'),
    )

    // --- Protonen im Intermembranraum -------------------------------------------
    const protonenListe = []
    for (let i = 0; i < 60; i++) {
      const p = atom(
        [(zufall() - 0.5) * 44, 2.2 + zufall() * 4, (zufall() - 0.5) * 12],
        0.22,
        0xff6b6b,
        { material: glow(0xff6b6b, 0.7), segments: 8 },
      )
      p.userData = { start: p.position.clone(), phase: zufall() * Math.PI * 2, ziel: null }
      protonen.add(p)
      protonenListe.push(p)
    }

    // --- Elektronenfluss ----------------------------------------------------------
    const elektronenListe = []
    const bahn = [
      V(-17, 1.5, 0), V(-12, -0.5, 1.2), V(-5, -0.6, 1.6), V(-1, 0.5, 0),
      V(3.4, 3.2, 1.2), V(7.5, 1.0, 0), V(7.5, -2.5, 0),
    ]
    for (let i = 0; i < 8; i++) {
      const e = atom([0, 0, 0], 0.26, 0x4dabf7, { material: glow(0x4dabf7, 1.0), segments: 10 })
      e.userData.offset = i / 8
      elektronen.add(e)
      elektronenListe.push(e)
    }
    beschriftung.add(
      label('e⁻-Fluss: NADH → Q → Cyt c → O₂', [-6, -6.4, 3], 'accent'),
      label('½O₂ + 2H⁺ + 2e⁻ → H₂O', [7.5, -6.4, 0], 'cold'),
      label('ΔG = −220 kJ/mol über die gesamte Kette', [-6, -7.4, 3], 'muted'),
    )

    group.add(membranG, komplexe, protonen, synthase, elektronen, beschriftung)

    return {
      group,
      camera: { position: [2, 4, 52], target: [2, -3, 0] },
      layers: [
        { id: 'membran', name: 'Lipiddoppelschicht', objects: [membranG] },
        { id: 'komplexe', name: 'Komplex I–IV', objects: [komplexe] },
        { id: 'protonen', name: 'Protonengradient', objects: [protonen] },
        { id: 'synthase', name: 'ATP-Synthase', objects: [synthase] },
        { id: 'elektronen', name: 'Elektronentransport', objects: [elektronen] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung] },
      ],
      update(t) {
        // c-Ring und γ-Achse rotieren; F₁-Kopf bleibt fixiert (peripherer Stiel).
        const winkel = t * 1.1
        cRing.rotation.y = winkel
        gamma.rotation.y = winkel

        // Bindungswechsel: die drei β-Untereinheiten durchlaufen O → L → T
        betaUnter.forEach((b, i) => {
          const phase = winkel + (i * 2 * Math.PI) / 3
          const s = 1 + 0.14 * Math.sin(phase)
          b.scale.set(s, 1.3 * s, s)
          b.material.emissive?.setHex(0xe8590c)
          b.material.emissiveIntensity = Math.max(0, Math.sin(phase)) * 0.5
        })

        // ATP wird bei jeder Dritteldrehung freigesetzt
        atpMolekuele.forEach((m, i) => {
          const f = (winkel / (Math.PI * 2 / 3) + i) % atpMolekuele.length
          if (f < 1) {
            m.visible = true
            m.position.set(synthaseX + (f - 0.5) * 3, -11 - f * 2.2, Math.sin(m.userData.phase) * 2)
          } else {
            m.visible = false
          }
        })

        // Protonen driften zur ATP-Synthase und treten durch den c-Ring in die Matrix
        protonenListe.forEach((p, i) => {
          const s = p.userData.start
          const zyklus = (t * 0.35 + i / protonenListe.length) % 1
          if (zyklus < 0.7) {
            // Diffusion im Intermembranraum, langsame Drift nach rechts
            const x = s.x + zyklus * (synthaseX - 2.6 - s.x) / 0.7
            p.position.set(
              x,
              s.y + Math.sin(t * 2 + p.userData.phase) * 0.35,
              s.z + Math.cos(t * 1.6 + p.userData.phase) * 0.35,
            )
          } else {
            // Durchtritt durch F₀ in die Matrix
            const f = (zyklus - 0.7) / 0.3
            const a = winkel + f * Math.PI * 1.6
            p.position.set(
              synthaseX + Math.cos(a) * 1.5 * (1 - f * 0.3),
              2.2 - f * 7,
              Math.sin(a) * 1.5 * (1 - f * 0.3),
            )
          }
        })

        // Elektronen laufen die Redoxkette entlang
        elektronenListe.forEach((e) => {
          const f = (t * 0.22 + e.userData.offset) % 1
          const idx = Math.min(bahn.length - 2, Math.floor(f * (bahn.length - 1)))
          const lokal = f * (bahn.length - 1) - idx
          e.position.lerpVectors(bahn[idx], bahn[idx + 1], lokal)
        })

        // Komplexe pulsieren im Takt der Protonenpumpe
        komplexObjekte.forEach((k, i) => {
          k.scale.y = 1 + 0.03 * Math.sin(t * 2.5 + i)
        })
      },
    }
  },

  info: {
    summary:
      'Mitchells chemiosmotische Theorie (1961, Nobelpreis 1978) war zunächst hoch umstritten: Die Energie der Elektronenübertragung wird nicht in einem chemischen Zwischenprodukt gespeichert, sondern als elektrochemischer Protonengradient über der inneren Mitochondrienmembran. Die ATP-Synthase ist ein echter Rotationsmotor – der kleinste bekannte Motor der Biologie.',
    sections: [
      {
        title: 'Elektronentransport',
        body: [
          'Komplex I (NADH-Dehydrogenase) überträgt 2 e⁻ von NADH auf Ubichinon und pumpt dabei 4 H⁺ in den Intermembranraum.',
          'Komplex II (Succinat-Dehydrogenase) ist gleichzeitig Enzym des Citratzyklus, speist FADH₂-Elektronen ein – pumpt aber keine Protonen. Deshalb liefert FADH₂ weniger ATP als NADH.',
          'Komplex III (Cytochrom-bc₁) überträgt die Elektronen über den Q-Zyklus auf Cytochrom c und pumpt 4 H⁺.',
          'Komplex IV (Cytochrom-c-Oxidase) reduziert O₂ zu Wasser (½O₂ + 2H⁺ + 2e⁻ → H₂O) und pumpt 2 H⁺. Sie ist das Ziel von Cyanid, Kohlenmonoxid und Azid.',
          'Die Reihenfolge der Komplexe folgt aufsteigenden Redoxpotentialen: NAD⁺/NADH (−320 mV) bis O₂/H₂O (+820 mV). Die Gesamtdifferenz von 1,14 V entspricht ΔG° = −220 kJ/mol pro Elektronenpaar.',
        ],
      },
      {
        title: 'Protonenmotorische Kraft',
        body: [
          'Δp = Δψ − (2,3·RT/F)·ΔpH. Der Gradient hat also zwei Anteile: ein elektrisches Membranpotential Δψ ≈ 150–180 mV (Matrix negativ) und einen pH-Unterschied von etwa einer Einheit (~60 mV).',
          'Bei Mitochondrien dominiert klar der elektrische Anteil; bei Chloroplasten ist es umgekehrt der ΔpH.',
          'Entkoppler wie 2,4-Dinitrophenol (DNP) sind lipophile schwache Säuren, die Protonen an der Membran vorbeischleusen. Die Atmung läuft dann maximal, ohne ATP zu bilden – die Energie wird vollständig zu Wärme. DNP wurde in den 1930ern als Schlankheitsmittel verkauft und führte zu tödlicher Hyperthermie.',
          'Physiologisch nutzt braunes Fettgewebe genau diesen Mechanismus über Thermogenin (UCP1) zur zitterfreien Wärmebildung bei Neugeborenen.',
        ],
      },
      {
        title: 'Rotationskatalyse der ATP-Synthase',
        body: [
          'F₀ ist der membranständige Motor: Protonen treten über einen Halbkanal der a-Untereinheit ein, protonieren einen Aspartatrest im c-Ring, der sich dadurch um eine Position weiterdreht, und verlassen ihn über den zweiten Halbkanal zur Matrix.',
          'Der c-Ring ist starr mit der γ-Achse verbunden. Diese dreht sich im α₃β₃-Kopf, der durch den peripheren Stiel (b₂δ) am Mitrotieren gehindert wird.',
          'Boyers Bindungswechsel-Mechanismus: Die asymmetrische γ-Achse zwingt die drei β-Untereinheiten nacheinander durch die Zustände Open (leer), Loose (ADP+Pi gebunden) und Tight (ATP gebildet). Erstaunlich: Die ATP-Bildung selbst benötigt kaum Energie – der Protonengradient wird für die Freisetzung des fest gebundenen ATP verbraucht.',
          'Beim Menschen hat der c-Ring 8 Untereinheiten. Eine volle Umdrehung erfordert also 8 H⁺ und liefert 3 ATP – rechnerisch 2,7 H⁺ pro ATP. Zusammen mit dem ATP/ADP-Translokator (1 H⁺) ergibt das etwa 3,7 H⁺ pro exportiertem ATP.',
          'Nojis Experiment (1997) machte die Rotation direkt sichtbar: An die γ-Achse gekoppelte fluoreszente Aktinfilamente rotierten im Mikroskop erkennbar gegen den Uhrzeigersinn.',
        ],
      },
      {
        title: 'ATP-Bilanz',
        body: [
          'Aktuelle Werte: NADH ≈ 2,5 ATP, FADH₂ ≈ 1,5 ATP. Die älteren Ganzzahlen 3 und 2 stammen aus Zeiten, in denen man ganzzahlige Stöchiometrien annahm.',
          'Vollständige Oxidation von Glucose: etwa 30–32 ATP, abhängig vom Shuttle für zytosolisches NADH (Malat-Aspartat-Shuttle: 2,5; Glycerin-3-phosphat-Shuttle: 1,5).',
          'Ein Mensch setzt täglich etwa das eigene Körpergewicht an ATP um – bei einem Gesamtbestand von nur ~50 g. Jedes ATP-Molekül wird also mehr als 1000-mal pro Tag recycelt.',
        ],
      },
    ],
    facts: [
      { k: 'H⁺ Komplex I / III / IV', v: '4 / 4 / 2' },
      { k: 'Redoxspanne NADH→O₂', v: '1,14 V (−220 kJ/mol)' },
      { k: 'Membranpotential Δψ', v: '150–180 mV' },
      { k: 'ΔpH über Membran', v: '≈ 1,0 Einheit' },
      { k: 'c-Ring (human)', v: 'c₈ → 8 H⁺/Umdrehung' },
      { k: 'ATP pro Umdrehung', v: '3' },
      { k: 'NADH / FADH₂', v: '≈ 2,5 / 1,5 ATP' },
      { k: 'Glucose gesamt', v: '30–32 ATP' },
    ],
    exam: [
      'Warum liefert FADH₂ weniger ATP als NADH? (Einspeisung nach Komplex I.)',
      'Chemiosmotische Theorie erklären und Δp in seine zwei Anteile zerlegen.',
      'Bindungswechsel-Mechanismus: Wofür wird die Energie des Gradienten tatsächlich verbraucht?',
      'Wirkung von Entkopplern gegen Hemmstoffe der Atmungskette abgrenzen (O₂-Verbrauch, ATP, Wärme).',
    ],
  },
}
