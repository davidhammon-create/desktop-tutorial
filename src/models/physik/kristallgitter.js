import * as THREE from 'three'
import { atom, bond, glass, label, metal, std, V } from '../../three/lib'

/**
 * Kristallstrukturen: fcc, bcc, hcp und Diamantstruktur mit Elementarzelle,
 * Koordinationspolyeder und (111)-Netzebene.
 * Maßstab: 1 Einheit = 1 Å.
 */

function zelle(a, farbe = 0x868e96) {
  const g = new THREE.Group()
  const k = [
    [0, 0, 0], [a, 0, 0], [a, 0, a], [0, 0, a],
    [0, a, 0], [a, a, 0], [a, a, a], [0, a, a],
  ]
  const kanten = [
    [0, 1], [1, 2], [2, 3], [3, 0],
    [4, 5], [5, 6], [6, 7], [7, 4],
    [0, 4], [1, 5], [2, 6], [3, 7],
  ]
  kanten.forEach(([i, j]) => g.add(bond(k[i], k[j], { radius: 0.035, color: farbe })))
  return g
}

export default {
  id: 'kristallgitter',
  name: 'Kristallgitter & Packungsdichte',
  discipline: 'physik',
  level: 'Bachelor',
  tagline: 'fcc, bcc, hcp und Diamantstruktur im Vergleich',
  scale: '1 Einheit = 1 Å',

  build() {
    const group = new THREE.Group()
    const a = 4.05 // Gitterkonstante Aluminium (fcc) in Å
    const rAtom = 0.9

    // --- fcc: kubisch flächenzentriert (Cu, Al, Au, Ag, γ-Fe) -------------------
    const fcc = new THREE.Group()
    fcc.position.set(-9, 0, 0)
    const fccPos = []
    for (let x = 0; x <= 1; x++)
      for (let y = 0; y <= 1; y++)
        for (let z = 0; z <= 1; z++) fccPos.push([x * a, y * a, z * a])
    const flaechen = [
      [0.5, 0.5, 0], [0.5, 0.5, 1], [0.5, 0, 0.5],
      [0.5, 1, 0.5], [0, 0.5, 0.5], [1, 0.5, 0.5],
    ]
    flaechen.forEach((f) => fccPos.push([f[0] * a, f[1] * a, f[2] * a]))
    fccPos.forEach((p, i) => fcc.add(atom(p, rAtom, i < 8 ? 0x5b8def : 0x9775fa)))
    fcc.add(zelle(a))
    fcc.add(label('fcc – kubisch flächenzentriert', [a / 2, a + 1.6, a / 2], 'accent'))
    fcc.add(label('KZ 12 · Packungsdichte 74,05 % · 4 Atome/Zelle', [a / 2, a + 0.7, a / 2], 'muted'))

    // (111)-Netzebene: dichtest gepackte Ebene, Gleitebene der Versetzungen
    const ebene111 = new THREE.Mesh(
      new THREE.CircleGeometry(a * 0.95, 3),
      glass(0xff922b, 0.32),
    )
    ebene111.position.set(a / 2, a / 2, a / 2)
    ebene111.lookAt(V(a / 2 + 1, a / 2 + 1, a / 2 + 1))
    const gruppe111 = new THREE.Group()
    gruppe111.add(ebene111, label('(111)-Ebene', [a / 2 + 2.4, a / 2 + 2.4, a / 2], 'warm'))
    fcc.add(gruppe111)

    // --- bcc: kubisch raumzentriert (α-Fe, W, Cr, Mo) ---------------------------
    const bcc = new THREE.Group()
    bcc.position.set(0, 0, 0)
    const b = 2.87 * 1.41 // gestreckt für vergleichbare Darstellung
    for (let x = 0; x <= 1; x++)
      for (let y = 0; y <= 1; y++)
        for (let z = 0; z <= 1; z++) bcc.add(atom([x * b, y * b, z * b], rAtom, 0x51cf66))
    const zentrum = atom([b / 2, b / 2, b / 2], rAtom, 0xff922b)
    bcc.add(zentrum)
    bcc.add(zelle(b))
    // Koordinationspolyeder: 8 nächste Nachbarn entlang der Raumdiagonalen
    for (let x = 0; x <= 1; x++)
      for (let y = 0; y <= 1; y++)
        for (let z = 0; z <= 1; z++)
          bcc.add(bond([b / 2, b / 2, b / 2], [x * b, y * b, z * b], { radius: 0.05, color: 0xff922b }))
    bcc.add(label('bcc – kubisch raumzentriert', [b / 2, b + 1.6, b / 2], 'accent'))
    bcc.add(label('KZ 8 · Packungsdichte 68,02 % · 2 Atome/Zelle', [b / 2, b + 0.7, b / 2], 'muted'))

    // --- Diamantstruktur (C, Si, Ge) --------------------------------------------
    const dia = new THREE.Group()
    dia.position.set(9, 0, 0)
    const d = 5.43 * 0.85 // Silizium, skaliert
    const basis = [
      [0, 0, 0], [0.5, 0.5, 0], [0.5, 0, 0.5], [0, 0.5, 0.5],
      [0.25, 0.25, 0.25], [0.75, 0.75, 0.25], [0.75, 0.25, 0.75], [0.25, 0.75, 0.75],
    ]
    const diaAtome = basis.map((p) => {
      const m = atom([p[0] * d, p[1] * d, p[2] * d], 0.75, p[0] % 0.5 === 0 ? 0x4dabf7 : 0xffd43b)
      dia.add(m)
      return { pos: V(p[0] * d, p[1] * d, p[2] * d), mesh: m }
    })
    // Tetraedrische sp³-Bindungen: Bindungslänge = √3/4 · a
    const bindungslaenge = (Math.sqrt(3) / 4) * d
    for (let i = 0; i < diaAtome.length; i++) {
      for (let j = i + 1; j < diaAtome.length; j++) {
        const dist = diaAtome[i].pos.distanceTo(diaAtome[j].pos)
        if (Math.abs(dist - bindungslaenge) < 0.05) {
          dia.add(bond(diaAtome[i].pos, diaAtome[j].pos, { radius: 0.12, color: 0xced4da }))
        }
      }
    }
    dia.add(zelle(d))
    dia.add(label('Diamantstruktur', [d / 2, d + 1.6, d / 2], 'accent'))
    dia.add(label('KZ 4 · Packungsdichte 34,01 % · 8 Atome/Zelle', [d / 2, d + 0.7, d / 2], 'muted'))
    dia.add(label('Tetraederwinkel 109,47°', [d / 2, -1.4, d / 2], 'muted'))

    // --- hcp: hexagonal dichteste Packung (Mg, Zn, Ti, Co) ----------------------
    const hcp = new THREE.Group()
    hcp.position.set(0, 0, 14)
    const rh = 1.6
    const lagen = [
      { y: 0, off: [0, 0], color: 0x5b8def, name: 'A' },
      { y: 2.6, off: [rh, rh / Math.sqrt(3)], color: 0xff922b, name: 'B' },
      { y: 5.2, off: [0, 0], color: 0x5b8def, name: 'A' },
    ]
    lagen.forEach((lage) => {
      for (let i = -1; i <= 1; i++) {
        for (let j = -1; j <= 1; j++) {
          const x = i * 2 * rh + (j % 2 ? rh : 0) + lage.off[0]
          const z = j * rh * Math.sqrt(3) + lage.off[1]
          hcp.add(atom([x, lage.y, z], rh * 0.92, lage.color))
        }
      }
      hcp.add(label(`Lage ${lage.name}`, [-5.2, lage.y, 0], 'muted'))
    })
    hcp.add(label('hcp – Stapelfolge ABAB', [0, 7.4, 0], 'accent'))
    hcp.add(label('fcc entspricht ABCABC entlang [111]', [0, 6.5, 0], 'muted'))

    group.add(fcc, bcc, dia, hcp)

    return {
      group,
      camera: { position: [4, 14, 34], target: [0, 3, 5] },
      layers: [
        { id: 'fcc', name: 'fcc (kfz)', objects: [fcc] },
        { id: 'bcc', name: 'bcc (krz)', objects: [bcc] },
        { id: 'diamant', name: 'Diamantstruktur', objects: [dia] },
        { id: 'hcp', name: 'hcp (Stapelfolge)', objects: [hcp] },
        { id: 'ebene', name: '(111)-Netzebene', objects: [gruppe111] },
      ],
      update(t) {
        // Zentralatom im bcc pulsiert, um das Koordinationspolyeder zu betonen.
        const s = 1 + 0.12 * Math.sin(t * 2)
        zentrum.scale.setScalar(s)
        group.rotation.y = Math.sin(t * 0.15) * 0.25
      },
    }
  },

  info: {
    summary:
      'Über 90 % aller metallischen Elemente kristallisieren in einer der drei Strukturen fcc, bcc oder hcp. Die Packungsdichte bestimmt Dichte und Duktilität, die Zahl der Gleitsysteme die Umformbarkeit – deshalb ist Kupfer (fcc) duktil und Zink (hcp) spröde.',
    sections: [
      {
        title: 'Packungsdichte – Herleitung für fcc',
        body: [
          'In der fcc-Zelle berühren sich die Atome entlang der Flächendiagonale: 4r = √2·a, also r = √2a/4.',
          'Pro Zelle: 8 Ecken × 1/8 + 6 Flächen × 1/2 = 4 Atome.',
          'APF = 4·(4/3)πr³ / a³ = 4·(4/3)π(√2a/4)³ / a³ = π/(3√2) ≈ 0,7405.',
          'Für bcc berühren sich die Atome entlang der Raumdiagonale (4r = √3a), das ergibt π√3/8 ≈ 0,6802.',
        ],
      },
      {
        title: 'Dichteste Packungen und Stapelfolge',
        body: [
          'fcc und hcp haben beide die maximale Packungsdichte von 74,05 % (Kepler-Vermutung, 1998 von Hales bewiesen). Sie unterscheiden sich nur in der Stapelfolge dichtest gepackter Ebenen: ABCABC (fcc) gegenüber ABAB (hcp).',
          'Die dichtest gepackte Ebene ist im fcc die {111}-Ebene – im Modell orange eingeblendet. Sie ist zugleich die bevorzugte Gleitebene, denn Versetzungen bewegen sich am leichtesten dort, wo der Burgers-Vektor am kürzesten ist.',
          'fcc besitzt 12 Gleitsysteme ({111}⟨110⟩), bcc 48 (aber mit höherer Peierls-Spannung), hcp nur 3 primäre Basisgleitsysteme – daraus folgt direkt das unterschiedliche Verformungsverhalten (von-Mises-Kriterium: 5 unabhängige Gleitsysteme nötig).',
        ],
      },
      {
        title: 'Diamantstruktur und Halbleiter',
        body: [
          'Die Diamantstruktur ist ein fcc-Gitter mit zweiatomiger Basis bei (0,0,0) und (¼,¼,¼). Jedes Atom ist sp³-hybridisiert und tetraedrisch von vier Nachbarn umgeben (109,47°).',
          'Bindungslänge = √3·a/4. Für Silizium mit a = 5,431 Å ergibt das 2,35 Å.',
          'Die geringe Packungsdichte von nur 34 % ist der Preis für gerichtete kovalente Bindungen – sie erzeugen die Bandlücke (Si: 1,12 eV, Ge: 0,66 eV, C: 5,47 eV) und damit die gesamte Halbleitertechnik.',
        ],
      },
      {
        title: 'Beugung und Strukturaufklärung',
        body: [
          'Bragg-Bedingung: nλ = 2d·sin θ mit d_hkl = a/√(h²+k²+l²) für kubische Gitter.',
          'Auslöschungsregeln folgen aus dem Strukturfaktor: fcc zeigt Reflexe nur bei h,k,l alle gerade oder alle ungerade; bcc nur bei h+k+l gerade. So unterscheidet man die Strukturen im Diffraktogramm.',
          'Die Diamantstruktur zeigt zusätzlich das Fehlen von (200) – ein direkter Test der zweiatomigen Basis.',
        ],
      },
    ],
    facts: [
      { k: 'fcc: Packung / KZ', v: '74,05 % / 12' },
      { k: 'bcc: Packung / KZ', v: '68,02 % / 8' },
      { k: 'hcp: Packung / KZ', v: '74,05 % / 12' },
      { k: 'Diamant: Packung / KZ', v: '34,01 % / 4' },
      { k: 'Gitterkonstante Al (fcc)', v: '4,050 Å' },
      { k: 'Gitterkonstante α-Fe (bcc)', v: '2,866 Å' },
      { k: 'Gitterkonstante Si', v: '5,431 Å' },
      { k: 'ideales c/a (hcp)', v: '√(8/3) = 1,633' },
    ],
    exam: [
      'APF für fcc, bcc und Diamant selbstständig herleiten.',
      'Atome pro Elementarzelle korrekt abzählen (Ecken 1/8, Flächen 1/2, Kanten 1/4).',
      'Auslöschungsregeln aus dem Strukturfaktor F_hkl = Σ f_j·e^(2πi(hx+ky+lz)) ableiten.',
      'Warum ist hcp trotz gleicher Packungsdichte wie fcc deutlich spröder?',
    ],
  },
}
