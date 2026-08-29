import * as THREE from 'three'
import { atom, bond, glass, glow, label, leader, rng, std, tube, V } from '../../three/lib'

/**
 * Eukaryotische Tierzelle im Anschnitt mit Kompartimenten und Zytoskelett.
 * Maßstab: 1 Einheit ≈ 0,7 µm (Zelldurchmesser hier ~20 µm).
 */
export default {
  id: 'zelle',
  name: 'Eukaryotische Tierzelle',
  discipline: 'biologie',
  level: 'Bachelor',
  tagline: 'Kompartimentierung, Sekretionsweg und Zytoskelett',
  scale: '1 Einheit ≈ 0,7 µm',

  build() {
    const group = new THREE.Group()
    const membran = new THREE.Group()
    const kern = new THREE.Group()
    const er = new THREE.Group()
    const golgi = new THREE.Group()
    const mitochondrien = new THREE.Group()
    const vesikel = new THREE.Group()
    const zytoskelett = new THREE.Group()
    const beschriftung = new THREE.Group()
    const zufall = rng(7)

    const R = 14 // Zellradius

    // --- Plasmamembran (aufgeschnitten, damit das Innere sichtbar bleibt) -------
    const zellHuelle = new THREE.Mesh(
      new THREE.SphereGeometry(R, 64, 48, 0, Math.PI * 1.45),
      glass(0x74c0fc, 0.14),
    )
    membran.add(zellHuelle)
    const randring = new THREE.Mesh(new THREE.TorusGeometry(R, 0.25, 12, 96), std(0x4dabf7))
    randring.rotation.x = Math.PI / 2
    membran.add(randring)

    // --- Zellkern mit Doppelmembran, Poren und Nukleolus ------------------------
    const kernR = 5.2
    const kernHuelle = new THREE.Mesh(new THREE.SphereGeometry(kernR, 48, 32), glass(0x9775fa, 0.3))
    kern.add(kernHuelle)
    const kernInnen = new THREE.Mesh(new THREE.SphereGeometry(kernR - 0.35, 48, 32), glass(0x9775fa, 0.22))
    kern.add(kernInnen)

    // Kernporenkomplexe (real ~2000–4000 pro Kern, Durchmesser 120 nm)
    for (let i = 0; i < 26; i++) {
      const u = zufall() * Math.PI * 2
      const v = Math.acos(2 * zufall() - 1)
      const p = V(
        Math.sin(v) * Math.cos(u) * kernR,
        Math.cos(v) * kernR,
        Math.sin(v) * Math.sin(u) * kernR,
      )
      const pore = new THREE.Mesh(new THREE.TorusGeometry(0.42, 0.14, 8, 16), std(0xffd43b))
      pore.position.copy(p)
      pore.lookAt(V(0, 0, 0))
      kern.add(pore)
    }

    // Nukleolus (Ort der rRNA-Synthese und Ribosomen-Vormontage)
    const nukleolus = new THREE.Mesh(new THREE.SphereGeometry(1.7, 32, 24), std(0x7048e8, { roughness: 0.5 }))
    nukleolus.position.set(1.4, 0.8, 0.6)
    kern.add(nukleolus)

    // Chromatin als geschlungene Fäden
    for (let c = 0; c < 6; c++) {
      const pts = []
      for (let i = 0; i < 14; i++) {
        pts.push(
          V(
            (zufall() - 0.5) * kernR * 1.3,
            (zufall() - 0.5) * kernR * 1.3,
            (zufall() - 0.5) * kernR * 1.3,
          ),
        )
      }
      kern.add(tube(pts, 0.13, std(0xd0bfff, { roughness: 0.6 }), { tubularSegments: 120 }))
    }
    kern.position.set(-2, 1, 0)

    // --- Endoplasmatisches Retikulum -------------------------------------------
    // Raues ER: Zisternen mit Ribosomen; glattes ER: tubuläres Netzwerk
    for (let i = 0; i < 7; i++) {
      const zisterne = new THREE.Mesh(
        new THREE.TorusGeometry(6.5 + i * 0.55, 0.22, 8, 64, Math.PI * 1.1),
        std(0x51cf66, { roughness: 0.5, transparent: true, opacity: 0.85 }),
      )
      zisterne.rotation.x = Math.PI / 2 + (zufall() - 0.5) * 0.5
      zisterne.rotation.z = zufall() * Math.PI
      zisterne.position.set(-2, 1 + (i - 3) * 0.9, 0)
      er.add(zisterne)

      // Ribosomen auf dem rauen ER (Durchmesser real 25 nm)
      for (let r = 0; r < 16; r++) {
        const a = zufall() * Math.PI * 1.1
        const rad = 6.5 + i * 0.55
        const p = new THREE.Vector3(Math.cos(a) * rad, Math.sin(a) * rad, 0)
        p.applyEuler(zisterne.rotation).add(zisterne.position)
        er.add(atom(p, 0.16, 0x2f9e44, { segments: 8 }))
      }
    }

    // --- Golgi-Apparat: gestapelte Zisternen (cis → medial → trans) -------------
    golgi.position.set(6, -2, 2)
    for (let i = 0; i < 6; i++) {
      const zisterne = new THREE.Mesh(
        new THREE.TorusGeometry(2.6 - i * 0.16, 0.28, 8, 48, Math.PI * 1.5),
        std(i < 2 ? 0xff922b : i < 4 ? 0xfd7e14 : 0xe8590c, { roughness: 0.5 }),
      )
      zisterne.rotation.x = Math.PI / 2
      zisterne.position.y = i * 0.75
      golgi.add(zisterne)
    }

    // --- Mitochondrien mit Cristae ----------------------------------------------
    const mitoPositionen = [
      [7, 4, -3], [-8, -5, 3], [3, 7, 4], [-6, 6, -4], [9, 0, -5],
    ]
    mitoPositionen.forEach((p, idx) => {
      const m = new THREE.Group()
      const aussen = new THREE.Mesh(
        new THREE.CapsuleGeometry(1.0, 2.4, 8, 24),
        glass(0xff6b6b, 0.35),
      )
      m.add(aussen)
      // Cristae: Einfaltungen der inneren Membran (Oberflächenvergrößerung ~5×)
      for (let c = 0; c < 9; c++) {
        const crista = new THREE.Mesh(
          new THREE.TorusGeometry(0.72, 0.09, 6, 20, Math.PI * 1.4),
          std(0xe03131, { roughness: 0.5 }),
        )
        crista.position.y = -1.3 + c * 0.32
        crista.rotation.x = Math.PI / 2
        crista.rotation.z = c * 0.7
        m.add(crista)
      }
      m.position.set(...p)
      m.rotation.set(zufall() * 3, zufall() * 3, zufall() * 3)
      m.userData.phase = idx
      mitochondrien.add(m)
    })

    // --- Vesikel, Lysosomen, Peroxisomen ----------------------------------------
    const transportVesikel = []
    for (let i = 0; i < 14; i++) {
      const v = atom(
        [(zufall() - 0.5) * 20, (zufall() - 0.5) * 18, (zufall() - 0.5) * 16],
        0.4 + zufall() * 0.25,
        0x22b8cf,
        { material: glow(0x22b8cf, 0.25) },
      )
      v.userData.start = v.position.clone()
      v.userData.phase = zufall() * Math.PI * 2
      vesikel.add(v)
      transportVesikel.push(v)
    }
    // Lysosomen (sauer, pH 4,5–5,0)
    for (let i = 0; i < 5; i++) {
      vesikel.add(
        atom(
          [(zufall() - 0.5) * 18, (zufall() - 0.5) * 16, (zufall() - 0.5) * 14],
          0.75,
          0xf76707,
          { material: std(0xf76707, { roughness: 0.4 }) },
        ),
      )
    }

    // --- Zytoskelett -------------------------------------------------------------
    // Mikrotubuli (25 nm) strahlen vom Zentrosom aus
    const zentrosom = V(4, 3, -1)
    for (let i = 0; i < 16; i++) {
      const dir = V(zufall() * 2 - 1, zufall() * 2 - 1, zufall() * 2 - 1).normalize()
      const ende = zentrosom.clone().addScaledVector(dir, R * 0.85)
      zytoskelett.add(bond(zentrosom, ende, { radius: 0.09, color: 0x868e96 }))
    }
    // Zentriolenpaar
    ;[0, 1].forEach((k) => {
      const z = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.3, 0.9, 9), std(0x495057))
      z.position.copy(zentrosom)
      z.rotation.z = k * Math.PI / 2
      zytoskelett.add(z)
    })
    // Aktinfilamente (7 nm) kortikal unter der Membran
    for (let i = 0; i < 20; i++) {
      const pts = []
      const a0 = zufall() * Math.PI * 2
      const b0 = zufall() * Math.PI
      for (let s = 0; s < 5; s++) {
        const a = a0 + s * 0.25
        const b = b0 + (zufall() - 0.5) * 0.4
        pts.push(V(Math.sin(b) * Math.cos(a) * R * 0.93, Math.cos(b) * R * 0.93, Math.sin(b) * Math.sin(a) * R * 0.93))
      }
      zytoskelett.add(tube(pts, 0.06, std(0xffd43b, { roughness: 0.6 }), { tubularSegments: 40 }))
    }

    // --- Beschriftungen ----------------------------------------------------------
    const marken = [
      ['Zellkern (Ø 6 µm) mit Nukleolus', [-2, 8, 0], 'accent2'],
      ['Kernpore – 120 nm, ~2000 pro Kern', [-9, 4.5, 4], 'warm'],
      ['raues ER – kotranslationale Proteinsynthese', [-13, -3, 5], 'green'],
      ['Golgi – Modifikation & Sortierung', [10, 2, 4], 'warm'],
      ['Mitochondrium – ATP-Produktion', [11, 6, -3], 'hot'],
      ['Lysosom – pH 4,5, saure Hydrolasen', [-11, -8, 0], 'warm'],
      ['Mikrotubuli vom Zentrosom (25 nm)', [8, 8, -2], 'muted'],
      ['Aktin-Kortex (7 nm)', [0, -14, 6], 'muted'],
      ['Plasmamembran – Lipiddoppelschicht 5 nm', [0, 16, 0], 'accent'],
    ]

    marken.forEach(([text, pos, tone]) => beschriftung.add(label(text, pos, tone)))

    group.add(membran, kern, er, golgi, mitochondrien, vesikel, zytoskelett, beschriftung)

    return {
      group,
      camera: { position: [6, 12, 42], target: [0, 0, 0] },
      layers: [
        { id: 'membran', name: 'Plasmamembran', objects: [membran] },
        { id: 'kern', name: 'Zellkern', objects: [kern] },
        { id: 'er', name: 'Endoplasmatisches Retikulum', objects: [er] },
        { id: 'golgi', name: 'Golgi-Apparat', objects: [golgi] },
        { id: 'mito', name: 'Mitochondrien', objects: [mitochondrien] },
        { id: 'vesikel', name: 'Vesikel & Lysosomen', objects: [vesikel] },
        { id: 'zyto', name: 'Zytoskelett', objects: [zytoskelett] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung] },
      ],
      update(t) {
        group.rotation.y = Math.sin(t * 0.12) * 0.45
        // Vesikeltransport entlang gedachter Mikrotubuli-Bahnen
        transportVesikel.forEach((v) => {
          const s = v.userData.start
          const ph = v.userData.phase
          v.position.set(
            s.x + Math.sin(t * 0.5 + ph) * 1.6,
            s.y + Math.cos(t * 0.42 + ph) * 1.4,
            s.z + Math.sin(t * 0.33 + ph * 2) * 1.2,
          )
        })
        // Mitochondrien bewegen sich langsam (Fusion/Fission-Dynamik)
        mitochondrien.children.forEach((m, i) => {
          m.rotation.y += 0.002 * (1 + i * 0.1)
          m.position.y += Math.sin(t * 0.4 + i) * 0.004
        })
        nukleolus.rotation.y = t * 0.2
      },
    }
  },

  info: {
    summary:
      'Der entscheidende evolutionäre Schritt der Eukaryoten ist die Kompartimentierung: Durch interne Membranen entstehen chemisch getrennte Reaktionsräume mit eigenem pH-Wert, eigener Ionenzusammensetzung und eigenem Enzymbesatz. Das erlaubt gleichzeitig ablaufende, sonst unvereinbare Stoffwechselwege in derselben Zelle.',
    sections: [
      {
        title: 'Zellkern und Genexpression',
        body: [
          'Die Kernhülle besteht aus zwei Membranen; die äußere geht direkt in das raue ER über. Kernporenkomplexe (~120 MDa, aus über 30 verschiedenen Nukleoporinen) regeln den Stofftransport.',
          'Moleküle bis ~40 kDa diffundieren frei; größere benötigen ein Kernlokalisierungssignal (NLS) und Importin, angetrieben vom RanGTP-Gradienten.',
          'Die räumliche Trennung von Transkription (Kern) und Translation (Zytoplasma) ist die Voraussetzung für das Spleißen – Prokaryoten können das nicht, weil dort Ribosomen bereits an die entstehende mRNA binden.',
          'Der Nukleolus ist kein membranumhülltes Organell, sondern ein Phasenseparationskondensat: Ort der rRNA-Transkription und der Ribosomen-Vormontage.',
        ],
      },
      {
        title: 'Sekretionsweg',
        body: [
          'Der Weg lautet: raues ER → COPII-Vesikel → cis-Golgi → medial → trans-Golgi-Netzwerk → sekretorische Vesikel → Plasmamembran.',
          'Am rauen ER erfolgt die kotranslationale Translokation: Ein N-terminales Signalpeptid wird vom SRP erkannt, das Ribosom dockt am Sec61-Translokon an, die Kette wird direkt ins ER-Lumen geschleust.',
          'Im ER finden Faltung (Chaperone BiP, Calnexin), Disulfidbrückenbildung (PDI) und N-Glykosylierung statt. Fehlgefaltete Proteine werden über ERAD retrotransloziert und proteasomal abgebaut; Überlastung löst die Unfolded Protein Response aus.',
          'Der Golgi modifiziert Glykane und sortiert. Mannose-6-Phosphat markiert lysosomale Enzyme – fehlt dieser Marker (I-Zell-Krankheit, Mukolipidose II), werden die Hydrolasen fälschlich sezerniert.',
        ],
      },
      {
        title: 'Mitochondrien',
        body: [
          'Zwei Membranen: die äußere ist durch Porine für Moleküle < 5 kDa durchlässig, die innere praktisch impermeabel und Sitz der Atmungskette.',
          'Die Cristae vergrößern die innere Membranfläche etwa um den Faktor 5 und sind der Ort der ATP-Synthese.',
          'Eigenes zirkuläres Genom (human: 16 569 bp, 37 Gene), eigene 70S-artige Ribosomen – starke Belege für die Endosymbiontentheorie. Vererbung ausschließlich maternal.',
          'Mitochondrien sind ein dynamisches Netzwerk: Fusion (Mitofusine, OPA1) und Fission (DRP1) laufen ständig ab; geschädigte Bereiche werden per Mitophagie entfernt.',
        ],
      },
      {
        title: 'Zytoskelett',
        body: [
          'Drei Systeme: Mikrofilamente (Aktin, 7 nm), Intermediärfilamente (10 nm), Mikrotubuli (25 nm).',
          'Mikrotubuli sind polar (Plus-/Minus-Ende) und zeigen dynamische Instabilität – schnelles Wachstum und Katastrophen im Wechsel. Kinesin transportiert zum Plus-Ende, Dynein zum Minus-Ende.',
          'Pharmakologisch hochrelevant: Taxane stabilisieren Mikrotubuli, Vincaalkaloide destabilisieren sie – beide blockieren die Mitose und werden als Zytostatika eingesetzt. Colchicin wirkt am selben Ziel bei Gicht.',
          'Der Aktin-Kortex unter der Plasmamembran bestimmt Zellform, Migration (Lamellipodien, Filopodien) und Zytokinese.',
        ],
      },
    ],
    facts: [
      { k: 'Zelldurchmesser', v: '10–30 µm' },
      { k: 'Zellkern', v: '~6 µm' },
      { k: 'Membrandicke', v: '5–8 nm' },
      { k: 'Ribosom (80S)', v: '25–30 nm' },
      { k: 'Mitochondrium', v: '0,5–1 × 1–4 µm' },
      { k: 'Kernporen pro Kern', v: '2000–4000' },
      { k: 'mtDNA (human)', v: '16 569 bp, 37 Gene' },
      { k: 'Lysosomaler pH', v: '4,5–5,0' },
    ],
    exam: [
      'Sekretionsweg vollständig mit Vesikeltypen (COPI, COPII, Clathrin) beschreiben.',
      'Kotranslationale Translokation: Rolle von Signalpeptid, SRP und Sec61.',
      'Belege für die Endosymbiontentheorie aufzählen.',
      'Warum ermöglicht Kompartimentierung unvereinbare Reaktionswege?',
    ],
  },
}
