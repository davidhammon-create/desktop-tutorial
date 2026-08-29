import * as THREE from 'three'
import { atom, bond, CPK, glass, glow, label, lobe, multiBond, ring, std, V } from '../../three/lib'

/**
 * Benzol: σ-Gerüst, sechs p_z-Orbitale und das delokalisierte π-System.
 * Maßstab: 1 Einheit = 100 pm (1 Å).
 */
export default {
  id: 'benzol',
  name: 'Benzol & aromatisches π-System',
  discipline: 'chemie',
  level: 'Bachelor',
  tagline: 'Delokalisierung, Hückel-Regel und Ringstrom',
  scale: '1 Einheit = 1 Å',

  build() {
    const group = new THREE.Group()
    const sigma = new THREE.Group()
    const pOrbitale = new THREE.Group()
    const piWolke = new THREE.Group()
    const ringstrom = new THREE.Group()
    const beschriftung = new THREE.Group()

    const rC = 1.399 // C–C-Bindungslänge in Å (alle gleich – zentraler Befund!)
    const kohlenstoffe = []
    const wasserstoffe = []

    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * Math.PI * 2
      const c = V(Math.cos(a) * rC, 0, Math.sin(a) * rC)
      kohlenstoffe.push(c)
      // C–H-Bindungslänge 108,4 pm, radial nach außen
      const h = V(Math.cos(a) * (rC + 1.084), 0, Math.sin(a) * (rC + 1.084))
      wasserstoffe.push(h)
    }

    kohlenstoffe.forEach((c, i) => {
      sigma.add(atom(c, 0.32, CPK.C, { material: std(CPK.C, { roughness: 0.35 }) }))
      sigma.add(atom(wasserstoffe[i], 0.19, CPK.H, { material: std(CPK.H, { roughness: 0.3 }) }))
      sigma.add(bond(c, wasserstoffe[i], { radius: 0.075, color: 0xadb5bd }))
      sigma.add(bond(c, kohlenstoffe[(i + 1) % 6], { radius: 0.105, color: 0x868e96 }))
    })

    // --- p_z-Orbitale: je ein Lappen ober- und unterhalb der Ringebene ----------
    const lappen = []
    kohlenstoffe.forEach((c) => {
      const oben = lobe(1.5, 0.42, 0x4dabf7, { opacity: 0.4 })
      oben.position.copy(c)
      const unten = lobe(1.5, 0.42, 0xff6b6b, { opacity: 0.4 })
      unten.position.copy(c)
      unten.rotation.x = Math.PI
      pOrbitale.add(oben, unten)
      lappen.push(oben, unten)
    })

    // --- Delokalisierte π-Wolke: zwei Torusringe statt lokalisierter Doppelbindungen
    const oben = ring(rC, 0.46, 0x4dabf7, { material: glass(0x4dabf7, 0.3) })
    oben.rotation.x = Math.PI / 2
    oben.position.y = 0.72
    const unten = ring(rC, 0.46, 0xff6b6b, { material: glass(0xff6b6b, 0.3) })
    unten.rotation.x = Math.PI / 2
    unten.position.y = -0.72
    piWolke.add(oben, unten)

    // --- Diamagnetischer Ringstrom (NMR-Entschirmung) ---------------------------
    const stromPunkte = []
    for (let i = 0; i < 24; i++) {
      const s = atom([0, 0, 0], 0.09, 0xffd43b, { material: glow(0xffd43b, 1.0), segments: 10 })
      s.userData.phase = (i / 24) * Math.PI * 2
      s.userData.lage = i % 2 === 0 ? 0.72 : -0.72
      ringstrom.add(s)
      stromPunkte.push(s)
    }
    ringstrom.add(label('Diamagnetischer Ringstrom → δ(¹H) = 7,26 ppm', [0, 2.9, 0], 'warm'))

    beschriftung.add(
      label('C–C: 139,9 pm – einheitlich (weder 154 noch 134 pm)', [0, -2.4, 0], 'muted'),
      label('D₆ₕ · planar · 6 π-Elektronen · Hückel 4n+2 mit n=1', [0, -3.2, 0], 'muted'),
      label('p_z-Orbitale senkrecht zur Ringebene', [0, 2.2, 3.6], 'accent'),
    )

    group.add(sigma, pOrbitale, piWolke, ringstrom, beschriftung)

    return {
      group,
      camera: { position: [0, 5.5, 11], target: [0, 0, 0] },
      layers: [
        { id: 'sigma', name: 'σ-Gerüst (sp²)', objects: [sigma] },
        { id: 'p', name: 'p_z-Orbitale', objects: [pOrbitale] },
        { id: 'pi', name: 'delokalisiertes π-System', objects: [piWolke] },
        { id: 'strom', name: 'Ringstrom', objects: [ringstrom] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung] },
      ],
      update(t) {
        // Elektronen zirkulieren – Bild der Delokalisierung.
        stromPunkte.forEach((s) => {
          const a = s.userData.phase + t * 1.4
          s.position.set(Math.cos(a) * rC, s.userData.lage, Math.sin(a) * rC)
        })
        // π-Wolke atmet leicht, p-Orbitale pulsieren gegenphasig.
        const p = 1 + 0.05 * Math.sin(t * 1.6)
        oben.scale.setScalar(p)
        unten.scale.setScalar(p)
        lappen.forEach((l, i) => {
          l.material.opacity = 0.28 + 0.14 * Math.sin(t * 1.6 + (i % 2) * Math.PI)
        })
        group.rotation.y = t * 0.15
      },
    }
  },

  info: {
    summary:
      'Benzol ist das Referenzsystem der Aromatizität. Die entscheidende experimentelle Beobachtung: Alle sechs C–C-Bindungen sind exakt gleich lang (139,9 pm) – ein Zwischenwert zwischen Einfach- (154 pm) und Doppelbindung (134 pm). Kekulés alternierende Struktur beschreibt daher keine reale Verbindung, sondern nur eine Grenzformel.',
    sections: [
      {
        title: 'Bindungssituation',
        body: [
          'Jedes C-Atom ist sp²-hybridisiert: drei σ-Bindungen (zwei zu C, eine zu H) in einer Ebene mit 120°-Winkeln. Das verbleibende p_z-Orbital steht senkrecht dazu.',
          'Die sechs p_z-Orbitale überlappen seitlich zu einem ringförmig delokalisierten π-System – im Modell als Doppel-Torus über und unter der Ringebene dargestellt.',
          'MO-theoretisch entstehen aus sechs p_z-AOs sechs π-MOs: ein bindendes (ψ₁, nicht entartet), zwei entartete bindende (ψ₂, ψ₃), zwei entartete antibindende (ψ₄, ψ₅) und ein antibindendes (ψ₆). Die sechs π-Elektronen füllen genau die drei bindenden MOs – eine geschlossene Schale.',
        ],
      },
      {
        title: 'Hückel-Regel und Aromatizität',
        body: [
          'Ein cyclisch konjugiertes, planares System ist aromatisch, wenn es (4n+2) π-Elektronen besitzt. Benzol: n = 1 → 6 Elektronen.',
          'Das Frost-Kreis-Diagramm liefert die Orbitalenergien graphisch: Man zeichnet das Polygon mit einer Ecke nach unten in einen Kreis vom Radius 2β; die Ecken markieren die Energieniveaus E = α + 2β·cos(2πk/N).',
          'Antiaromatisch sind Systeme mit 4n π-Elektronen (Cyclobutadien, Cyclooctatetraen-Dianion-Gegenbeispiele). Cyclooctatetraen weicht der Antiaromatizität durch eine wannenförmige, nichtplanare Struktur aus.',
          'Mesomerie-/Resonanzenergie des Benzols: ca. 150 kJ/mol. Bestimmt aus Hydrierwärmen: Cyclohexen −120 kJ/mol, hypothetisches "Cyclohexatrien" also −360, gemessen für Benzol jedoch nur −208 kJ/mol.',
        ],
      },
      {
        title: 'Ringstrom und NMR-Nachweis',
        body: [
          'Im äußeren Magnetfeld induziert das delokalisierte π-System einen diamagnetischen Ringstrom. Dieser erzeugt ein Gegenfeld, das die Protonen am Ringrand entschirmt.',
          'Folge: aromatische Protonen erscheinen im ¹H-NMR stark tieffeldverschoben bei δ = 7,26 ppm (Benzol), gegenüber δ ≈ 5,3 ppm für gewöhnliche Alkene.',
          'Protonen oberhalb der Ringebene würden umgekehrt abgeschirmt – im [18]Annulen misst man tatsächlich δ = −3 ppm für die inneren Protonen. Das ist der direkteste experimentelle Beleg für den Ringstrom.',
        ],
      },
      {
        title: 'Reaktivität',
        body: [
          'Aromaten reagieren bevorzugt in elektrophiler aromatischer Substitution (SEAr), nicht in Addition – denn nur die Substitution erhält das aromatische System.',
          'Mechanismus: Angriff des Elektrophils → σ-Komplex (Wheland-Intermediat, Aromatizität kurzzeitig aufgehoben, geschwindigkeitsbestimmend) → Rearomatisierung durch Protonenverlust.',
          'Substituenteneffekte: +M/+I-Gruppen (–OH, –NH₂, –CH₃) aktivieren und dirigieren ortho/para; −M-Gruppen (–NO₂, –CN, –COOH) desaktivieren und dirigieren meta. Halogene sind der Sonderfall: desaktivierend (−I) aber ortho/para-dirigierend (+M).',
        ],
      },
    ],
    facts: [
      { k: 'C–C-Bindungslänge', v: '139,9 pm (einheitlich)' },
      { k: 'C–H-Bindungslänge', v: '108,4 pm' },
      { k: 'Bindungswinkel', v: '120° (sp²)' },
      { k: 'Punktgruppe', v: 'D₆ₕ' },
      { k: 'Resonanzenergie', v: '≈ 150 kJ/mol' },
      { k: 'π-Elektronen', v: '6 (Hückel: 4n+2, n=1)' },
      { k: '¹H-NMR-Verschiebung', v: 'δ = 7,26 ppm' },
      { k: 'Hydrierwärme', v: '−208 kJ/mol' },
    ],
    exam: [
      'Frost-Kreis für Benzol, Cyclobutadien und Cyclopentadienyl-Anion zeichnen.',
      'Resonanzenergie aus Hydrierwärmen berechnen.',
      'Warum ist das Cyclopentadienyl-Anion aromatisch, das Kation aber antiaromatisch?',
      'SEAr-Mechanismus mit Energieprofil; warum ist die Rearomatisierung schnell?',
    ],
  },
}
