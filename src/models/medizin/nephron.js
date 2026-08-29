import * as THREE from 'three'
import { arrow, atom, bond, glass, glow, label, std, tube, V } from '../../three/lib'

/**
 * Nephron mit Glomerulus, Tubulussystem und kortikomedullärem
 * Osmolaritätsgradienten (Gegenstrommultiplikation).
 * Maßstab: schematisch, Längenverhältnisse annähernd realistisch.
 */
export default {
  id: 'nephron',
  name: 'Nephron & Harnbereitung',
  discipline: 'medizin',
  level: 'Bachelor / Physikum',
  tagline: 'Filtration, Resorption und Gegenstromprinzip',
  scale: 'schematisch',

  build() {
    const group = new THREE.Group()
    const glomerulusG = new THREE.Group()
    const tubulus = new THREE.Group()
    const gradient = new THREE.Group()
    const gefaesse = new THREE.Group()
    const transport = new THREE.Group()
    const beschriftung = new THREE.Group()

    // --- Kortikomedullärer Osmolaritätsgradient als Hintergrundschichten --------
    const schichten = [
      { y: 6, osm: 300, name: 'Nierenrinde (Cortex)', farbe: 0x91a7ff },
      { y: 2, osm: 600, name: 'äußeres Mark', farbe: 0x748ffc },
      { y: -2, osm: 900, name: 'inneres Mark', farbe: 0x5c7cfa },
      { y: -6, osm: 1200, name: 'Papillenspitze', farbe: 0x4263eb },
    ]
    schichten.forEach((s) => {
      const platte = new THREE.Mesh(new THREE.BoxGeometry(26, 3.9, 12), glass(s.farbe, 0.16))
      platte.position.set(0, s.y, -3)
      gradient.add(platte)
      gradient.add(label(`${s.name} · ${s.osm} mOsm/kg`, [-15.5, s.y, -3], 'cold'))
    })

    // --- Glomerulus mit Bowman-Kapsel --------------------------------------------
    const bowman = new THREE.Mesh(new THREE.SphereGeometry(2.6, 32, 24), glass(0xffd43b, 0.22))
    bowman.position.set(-9, 7.5, 0)
    glomerulusG.add(bowman)

    // Kapillarknäuel
    for (let i = 0; i < 7; i++) {
      const pts = []
      for (let j = 0; j < 10; j++) {
        const a = (j / 10) * Math.PI * 4 + i
        const r = 1.5 * (0.6 + 0.4 * Math.sin(j * 1.3 + i))
        pts.push(V(-9 + Math.cos(a) * r, 7.5 + Math.sin(j * 0.9 + i) * 1.2, Math.sin(a) * r))
      }
      glomerulusG.add(tube(pts, 0.2, std(0xe03131, { roughness: 0.45 }), { tubularSegments: 80 }))
    }

    // Vas afferens (weit) und Vas efferens (eng) – Grundlage der Autoregulation
    const afferens = tube([V(-14.5, 8.6, 0), V(-11.5, 8.0, 0)], 0.45, std(0xe03131))
    const efferens = tube([V(-6.6, 8.0, 0), V(-4.5, 8.8, 0)], 0.28, std(0xf03e3e))
    gefaesse.add(afferens, efferens)
    beschriftung.add(
      label('Vas afferens (weit)', [-15.5, 9.6, 0], 'hot'),
      label('Vas efferens (eng) → hoher Filtrationsdruck', [-3.0, 9.8, 0], 'hot'),
      label('Glomerulus + Bowman-Kapsel', [-9, 10.6, 0], 'warm'),
      label('GFR 125 ml/min = 180 l/Tag', [-9, -0.4, 3.5], 'muted'),
    )

    // --- Tubulussystem -------------------------------------------------------------
    // Proximaler Tubulus (gewunden, Bürstensaum)
    const proximalPunkte = [V(-6.6, 6.6, 0)]
    for (let i = 0; i < 10; i++) {
      proximalPunkte.push(V(-6.0 + i * 0.55, 6.6 + (i % 2 === 0 ? 1.0 : -1.0), (i % 3) * 0.5 - 0.5))
    }
    proximalPunkte.push(V(-0.5, 5.4, 0))
    const proximal = tube(proximalPunkte, 0.5, std(0x51cf66, { roughness: 0.5 }), { tubularSegments: 200 })
    tubulus.add(proximal)

    // Henle-Schleife: absteigend (wasserdurchlässig) und aufsteigend (salzresorbierend)
    const absteigend = tube(
      [V(-0.5, 5.4, 0), V(-0.2, 0, 0), V(0, -6.5, 0)],
      0.4,
      std(0x74c0fc, { roughness: 0.5 }),
      { tubularSegments: 120 },
    )
    const schleife = tube(
      [V(0, -6.5, 0), V(0.9, -7.6, 0), V(1.8, -6.5, 0)],
      0.4,
      std(0x4dabf7, { roughness: 0.5 }),
      { tubularSegments: 60 },
    )
    const aufsteigend = tube(
      [V(1.8, -6.5, 0), V(2.0, 0, 0), V(2.3, 5.4, 0)],
      0.45,
      std(0xff922b, { roughness: 0.5 }),
      { tubularSegments: 120 },
    )
    tubulus.add(absteigend, schleife, aufsteigend)

    // Macula densa am Übergang zum distalen Tubulus (juxtaglomerulärer Apparat)
    const maculaDensa = atom([2.3, 5.8, 0], 0.35, 0xfa5252, { material: glow(0xfa5252, 0.8) })
    tubulus.add(maculaDensa)

    // Distaler Tubulus
    const distalPunkte = [V(2.3, 5.8, 0)]
    for (let i = 0; i < 8; i++) {
      distalPunkte.push(V(3.0 + i * 0.5, 6.2 + (i % 2 === 0 ? 0.8 : -0.8), (i % 2) * 0.4))
    }
    distalPunkte.push(V(7.5, 5.8, 0))
    const distal = tube(distalPunkte, 0.42, std(0x9775fa, { roughness: 0.5 }), { tubularSegments: 160 })
    tubulus.add(distal)

    // Sammelrohr durch das gesamte Mark
    const sammelrohr = tube(
      [V(7.5, 5.8, 0), V(7.8, 0, 0), V(8.0, -7.5, 0)],
      0.55,
      std(0xe8590c, { roughness: 0.5 }),
      { tubularSegments: 140 },
    )
    tubulus.add(sammelrohr)

    // Vasa recta (Gegenstromaustauscher)
    const vasaAb = tube([V(-2.5, 6, -2), V(-2.2, -7, -2)], 0.22, std(0xe03131, { roughness: 0.5 }))
    const vasaAuf = tube([V(-3.4, -7, -2), V(-3.6, 6, -2)], 0.22, std(0x4263eb, { roughness: 0.5 }))
    gefaesse.add(vasaAb, vasaAuf)
    beschriftung.add(label('Vasa recta – Gegenstromaustauscher', [-6.5, -8.4, -2], 'cold'))

    // --- Transportprozesse als bewegte Marker --------------------------------------
    const filtratBahn = [
      ...proximalPunkte, V(-0.2, 0, 0), V(0, -6.5, 0), V(0.9, -7.6, 0), V(1.8, -6.5, 0),
      V(2.0, 0, 0), V(2.3, 5.4, 0), ...distalPunkte, V(7.8, 0, 0), V(8.0, -7.5, 0),
    ]
    const filtratPartikel = []
    for (let i = 0; i < 22; i++) {
      const p = atom([0, 0, 0], 0.2, 0xffd43b, { material: glow(0xffd43b, 0.7), segments: 10 })
      p.userData.offset = i / 22
      transport.add(p)
      filtratPartikel.push(p)
    }

    // Wasserrückresorption im absteigenden Schenkel
    const wasserPfeile = []
    for (let i = 0; i < 5; i++) {
      const y = 3.5 - i * 2.2
      const a = arrow([-0.2, y, 0], [-2.2, y, 0], 0x4dabf7, { radius: 0.06 })
      transport.add(a)
      wasserPfeile.push(a)
    }
    // Salzresorption im aufsteigenden Schenkel (NKCC2)
    const salzPfeile = []
    for (let i = 0; i < 5; i++) {
      const y = -5 + i * 2.2
      const a = arrow([2.0, y, 0], [4.0, y, 0], 0xff922b, { radius: 0.06 })
      transport.add(a)
      salzPfeile.push(a)
    }

    const marken = [
      ['Proximaler Tubulus – 65 % Na⁺, 100 % Glucose', [-3.0, 8.6, 2.5], 'green'],
      ['absteigender Schenkel: wasserdurchlässig, salzdicht', [-4.6, 1.5, 2.5], 'cold'],
      ['aufsteigender Schenkel: NKCC2, wasserdicht', [5.6, 0.5, 2.5], 'warm'],
      ['Macula densa – tubuloglomeruläres Feedback', [4.0, 7.6, 1.5], 'hot'],
      ['Distaler Tubulus – NCC, Ca²⁺ (PTH)', [5.5, 8.6, 0], 'accent2'],
      ['Sammelrohr – ADH/Aquaporin-2, Aldosteron', [11.5, 0, 0], 'warm'],
      ['Endharn: 1–1,5 l/Tag (99 % resorbiert)', [8.0, -9.2, 0], 'muted'],
    ]
    marken.forEach(([text, pos, tone]) => beschriftung.add(label(text, pos, tone)))

    group.add(gradient, glomerulusG, tubulus, gefaesse, transport, beschriftung)

    return {
      group,
      camera: { position: [0, 2, 40], target: [0, 0, 0] },
      layers: [
        { id: 'gradient', name: 'Osmolaritätsgradient', objects: [gradient] },
        { id: 'glomerulus', name: 'Glomerulus', objects: [glomerulusG] },
        { id: 'tubulus', name: 'Tubulussystem', objects: [tubulus] },
        { id: 'gefaesse', name: 'Gefäße & Vasa recta', objects: [gefaesse] },
        { id: 'transport', name: 'Transportvorgänge', objects: [transport] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung] },
      ],
      update(t) {
        // Filtrat fließt durch das Tubulussystem
        filtratPartikel.forEach((p) => {
          p.userData.offset = (p.userData.offset + 0.0016) % 1
          const f = p.userData.offset * (filtratBahn.length - 1)
          const idx = Math.min(filtratBahn.length - 2, Math.floor(f))
          p.position.lerpVectors(filtratBahn[idx], filtratBahn[idx + 1], f - idx)
          // Volumen nimmt entlang des Tubulus ab – Partikel werden kleiner
          p.scale.setScalar(1 - p.userData.offset * 0.55)
        })

        // Resorptionspfeile pulsieren
        wasserPfeile.forEach((a, i) => {
          a.scale.setScalar(0.7 + 0.35 * Math.sin(t * 2 + i * 0.6))
        })
        salzPfeile.forEach((a, i) => {
          a.scale.setScalar(0.7 + 0.35 * Math.sin(t * 2 + i * 0.6 + Math.PI))
        })

        maculaDensa.material.emissiveIntensity = 0.5 + 0.5 * Math.sin(t * 3)
      },
    }
  },

  info: {
    summary:
      'Die Niere filtriert täglich etwa 180 Liter Primärharn – das entspricht dem 60-fachen des Plasmavolumens – und resorbiert davon über 99 % zurück. Dieses scheinbar verschwenderische Prinzip erlaubt eine extrem schnelle und präzise Regulation von Volumen, Elektrolyten und pH-Wert.',
    sections: [
      {
        title: 'Glomeruläre Filtration',
        body: [
          'Der effektive Filtrationsdruck ergibt sich aus P_eff = P_kap − P_Bowman − π_kap ≈ 48 − 13 − 25 = 10 mmHg. Der onkotische Druck steigt entlang der Kapillare an, sodass die Filtration zum Ende hin abnimmt.',
          'Die Filtrationsbarriere ist dreischichtig: fenestriertes Endothel (70–100 nm), Basalmembran (negativ geladen durch Heparansulfat) und die Schlitzmembran der Podozyten (Nephrin, Podocin).',
          'Selektivität: Moleküle < 10 kDa passieren frei, > 70 kDa praktisch gar nicht. Albumin (69 kDa) wird zusätzlich durch seine negative Ladung zurückgehalten – geht die Ladungsselektivität verloren (Minimal-Change-Glomerulopathie), resultiert eine selektive Albuminurie.',
          'Autoregulation hält die GFR zwischen 80 und 180 mmHg systolisch konstant: über den myogenen Bayliss-Effekt und das tubuloglomeruläre Feedback der Macula densa. Steigt das NaCl-Angebot dort, wird Adenosin freigesetzt und das Vas afferens verengt.',
        ],
      },
      {
        title: 'Tubuläre Resorption',
        body: [
          'Proximaler Tubulus: resorbiert 65 % des Natriums, praktisch 100 % der Glucose und Aminosäuren sowie 85 % des Bicarbonats – isoosmotisch, da das Epithel wasserdurchlässig ist.',
          'Die Glucoseresorption über SGLT2 hat ein Transportmaximum: Ab einer Plasmakonzentration von etwa 180 mg/dl (Nierenschwelle) erscheint Glucose im Urin. SGLT2-Hemmer (Gliflozine) senken diese Schwelle therapeutisch.',
          'Der aufsteigende Schenkel der Henle-Schleife ist wasserundurchlässig und resorbiert NaCl über den NKCC2-Transporter – das Filtrat wird hypoton ("Verdünnungssegment"). Schleifendiuretika wie Furosemid blockieren genau diesen Transporter und sind daher die stärksten Diuretika.',
          'Distaler Tubulus: NCC-Cotransporter (Ziel der Thiazide), Ca²⁺-Resorption unter PTH-Kontrolle. Sammelrohr: Aldosteron steuert ENaC und die Na⁺/K⁺-ATPase (Ziel von Spironolacton), ADH steuert den Einbau von Aquaporin-2.',
        ],
      },
      {
        title: 'Gegenstromprinzip',
        body: [
          'Die Henle-Schleife arbeitet als Gegenstrommultiplikator. Der Einzeleffekt ist klein: Der aufsteigende Schenkel pumpt NaCl ins Interstitium und erzeugt lokal etwa 200 mOsm/kg Differenz.',
          'Durch die gegenläufige Strömung wird dieser Einzeleffekt entlang der Schleifenachse aufmultipliziert. So entsteht der kortikomedulläre Gradient von 300 mOsm/kg in der Rinde bis 1200 mOsm/kg an der Papillenspitze.',
          'Harnstoff-Recycling aus dem inneren Sammelrohr (über UT-A1/A3, ADH-abhängig) trägt rund die Hälfte zum Gradienten bei – deshalb konzentrieren proteinarm ernährte Menschen schlechter.',
          'Die Vasa recta verlaufen ebenfalls haarnadelförmig und wirken als Gegenstromaustauscher: Sie versorgen das Mark mit Sauerstoff, ohne den Gradienten auszuwaschen. Das Nierenmark arbeitet dennoch an der Grenze zur Hypoxie – daher seine hohe Anfälligkeit für ischämische Schäden.',
          'Der eigentliche Konzentrierungsschritt erfolgt im Sammelrohr: Unter ADH-Wirkung werden Aquaporin-2-Kanäle eingebaut, Wasser folgt osmotisch ins hypertone Interstitium. Ohne ADH (Diabetes insipidus) werden bis zu 20 l verdünnter Urin pro Tag ausgeschieden.',
        ],
      },
      {
        title: 'Clearance und Nierenfunktion',
        body: [
          'Clearance-Formel: C = (U × V̇)/P. Inulin wird frei filtriert, weder resorbiert noch sezerniert – seine Clearance entspricht daher exakt der GFR (Goldstandard).',
          'Kreatinin wird zusätzlich geringfügig sezerniert und überschätzt die GFR leicht; klinisch schätzt man sie über CKD-EPI oder MDRD.',
          'PAH wird zu ~90 % in einer Passage eliminiert, seine Clearance entspricht näherungsweise dem renalen Plasmafluss (RPF ≈ 600 ml/min). Daraus folgt die Filtrationsfraktion FF = GFR/RPF ≈ 20 %.',
          'Der kreatininblinde Bereich ist klausurrelevant: Das Serumkreatinin steigt erst messbar an, wenn die GFR bereits um etwa 50 % gefallen ist.',
        ],
      },
    ],
    facts: [
      { k: 'Nephrone pro Niere', v: '~1 Million' },
      { k: 'GFR', v: '125 ml/min = 180 l/Tag' },
      { k: 'Endharn', v: '1–1,5 l/Tag (> 99 % resorbiert)' },
      { k: 'Effektiver Filtrationsdruck', v: '~10 mmHg' },
      { k: 'Renaler Plasmafluss', v: '~600 ml/min' },
      { k: 'Filtrationsfraktion', v: '~20 %' },
      { k: 'Osmolarität Cortex → Papille', v: '300 → 1200 mOsm/kg' },
      { k: 'Nierenschwelle Glucose', v: '~180 mg/dl' },
    ],
    exam: [
      'Effektiven Filtrationsdruck berechnen und Verlauf entlang der Kapillare erklären.',
      'Gegenstrommultiplikation Schritt für Schritt herleiten – warum reicht der Einzeleffekt nicht?',
      'Angriffspunkte der Diuretika den Tubulusabschnitten zuordnen.',
      'Clearance-Konzept: Inulin, Kreatinin und PAH vergleichen.',
      'Wirkung von ADH auf Sammelrohr und Aquaporin-2 beschreiben.',
    ],
  },
}
