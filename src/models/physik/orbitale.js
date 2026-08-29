import * as THREE from 'three'
import { atom, glow, label, pointCloud, rng, V } from '../../three/lib'

/**
 * Wasserstoff-Orbitale, direkt aus den analytischen Lösungen der
 * Schrödinger-Gleichung durch Monte-Carlo-Sampling von |ψ|² erzeugt.
 * Maßstab: 1 Einheit = 1 Bohr-Radius a₀ = 52,9 pm.
 */

// Radialteile R_nl(r) in atomaren Einheiten (Z = 1, r in a₀), Normierung weggelassen.
const R = {
  '1s': (r) => 2 * Math.exp(-r),
  '2s': (r) => (1 / (2 * Math.SQRT2)) * (2 - r) * Math.exp(-r / 2),
  '2p': (r) => (1 / (2 * Math.sqrt(6))) * r * Math.exp(-r / 2),
  '3s': (r) => (2 / (81 * Math.sqrt(3))) * (27 - 18 * r + 2 * r * r) * Math.exp(-r / 3),
  '3d': (r) => (4 / (81 * Math.sqrt(30))) * r * r * Math.exp(-r / 3),
}

// Winkelteile (reelle Kugelflächenfunktionen), Normierung weggelassen.
const Y = {
  s: () => 1,
  pz: (ct) => ct,
  dz2: (ct) => 3 * ct * ct - 1,
  dx2y2: (ct, phi) => (1 - ct * ct) * Math.cos(2 * phi),
}

/**
 * Sampelt |ψ|² per Rejection-Sampling in Kugelkoordinaten.
 *
 * Direkt im Würfel zu verwerfen wäre extrem ineffizient – bei 3s/3d liegt die
 * Dichte in einem winzigen Bruchteil des umschließenden Volumens. Stattdessen
 * werden r gleichverteilt, cos θ gleichverteilt und φ gleichverteilt gezogen und
 * gegen das Gewicht r²·|ψ|² getestet. Der Faktor r² ist das Volumenelement
 * (dV = r² dr d(cos θ) dφ) und liefert damit dieselbe räumliche Verteilung –
 * nur mit um Größenordnungen höherer Akzeptanzrate.
 */
function sampleOrbital({ radial, angular, extent, count, seed, posColor, negColor }) {
  const rand = rng(seed)
  const positions = []
  const colors = []
  const pos = new THREE.Color(posColor)
  const neg = new THREE.Color(negColor)

  const gewicht = (r, ct, phi) => {
    const psi = radial(r) * angular(ct, phi)
    return { w: r * r * psi * psi, psi }
  }

  // Maximum des Gewichts abschätzen, mit Sicherheitszuschlag gegen Unterschätzung.
  let max = 0
  for (let i = 0; i < 20000; i++) {
    const { w } = gewicht(rand() * extent, rand() * 2 - 1, rand() * Math.PI * 2)
    if (w > max) max = w
  }
  max *= 1.15
  if (max <= 0) return { positions, colors }

  let tries = 0
  const maxTries = count * 200
  while (positions.length < count * 3 && tries < maxTries) {
    tries++
    const r = rand() * extent
    const ct = rand() * 2 - 1
    const phi = rand() * Math.PI * 2
    const { w, psi } = gewicht(r, ct, phi)
    if (rand() * max > w) continue

    const st = Math.sqrt(Math.max(0, 1 - ct * ct))
    // y ist die Quantisierungsachse (z-Achse der Physik), damit p_z senkrecht steht.
    positions.push(r * st * Math.cos(phi), r * ct, r * st * Math.sin(phi))
    const c = psi >= 0 ? pos : neg
    colors.push(c.r, c.g, c.b)
  }
  return { positions, colors }
}

function buildOrbital(name, cfg) {
  const { positions, colors } = sampleOrbital(cfg)
  const cloud = pointCloud(positions, colors, cfg.size ?? 0.09, { opacity: 0.55 })
  const g = new THREE.Group()
  g.position.set(...cfg.offset)
  g.add(cloud)
  g.add(atom([0, 0, 0], 0.16, 0xffffff, { material: glow(0xffe066, 0.9) }))
  g.add(label(name, [0, cfg.extent * 0.62, 0], cfg.tone ?? 'accent'))
  g.add(label(cfg.note, [0, -cfg.extent * 0.62, 0], 'muted'))
  return g
}

export default {
  id: 'orbitale',
  name: 'Wasserstoff-Orbitale',
  discipline: 'physik',
  level: 'Bachelor',
  tagline: '|ψ|² aus den exakten Lösungen der Schrödinger-Gleichung',
  scale: '1 Einheit = 1 a₀ = 52,9 pm',

  build() {
    const group = new THREE.Group()
    const POS = 0x4dabf7 // ψ > 0
    const NEG = 0xff6b6b // ψ < 0

    const orbitale = [
      buildOrbital('1s', {
        radial: R['1s'], angular: Y.s, extent: 5, count: 9000, seed: 11,
        offset: [-16, 0, 0], posColor: POS, negColor: NEG,
        note: 'n=1, l=0 · keine Knoten',
      }),
      buildOrbital('2s', {
        radial: R['2s'], angular: Y.s, extent: 12, count: 11000, seed: 23,
        offset: [-6, 0, 0], posColor: POS, negColor: NEG, size: 0.12,
        note: 'n=2, l=0 · 1 Radialknoten bei r = 2a₀',
      }),
      buildOrbital('2p_z', {
        radial: R['2p'], angular: Y.pz, extent: 13, count: 11000, seed: 37,
        offset: [4, 0, 0], posColor: POS, negColor: NEG, size: 0.12,
        note: 'n=2, l=1 · Knotenebene z=0',
      }),
      buildOrbital('3d_z²', {
        radial: R['3d'], angular: Y.dz2, extent: 22, count: 13000, seed: 41,
        offset: [16, 0, 0], posColor: POS, negColor: NEG, size: 0.16,
        note: 'n=3, l=2 · 2 konische Knotenflächen',
      }),
      buildOrbital('3d_x²−y²', {
        radial: R['3d'], angular: Y.dx2y2, extent: 22, count: 13000, seed: 53,
        offset: [16, 0, 26], posColor: POS, negColor: NEG, size: 0.16,
        note: 'n=3, l=2 · vier Keulen in der xz-Ebene',
      }),
      buildOrbital('3s', {
        radial: R['3s'], angular: Y.s, extent: 26, count: 13000, seed: 67,
        offset: [-6, 0, 26], posColor: POS, negColor: NEG, size: 0.16,
        note: 'n=3, l=0 · 2 Radialknoten',
      }),
    ]

    const gruppen = { '1s': orbitale[0], '2s': orbitale[1], '2p': orbitale[2], '3d': new THREE.Group(), '3s': orbitale[5] }
    gruppen['3d'].add(orbitale[3], orbitale[4])
    Object.values(gruppen).forEach((g) => group.add(g))

    const legende = new THREE.Group()
    legende.add(
      label('blau: ψ > 0   ·   rot: ψ < 0   ·   Punktdichte ∝ |ψ|²', [0, -14, 13], 'muted'),
      label('E_n = −13,6 eV / n²   ·   Radialknoten: n − l − 1   ·   Winkelknoten: l', [0, -17, 13], 'muted'),
    )
    group.add(legende)

    return {
      group,
      camera: { position: [0, 22, 62], target: [0, 0, 10] },
      layers: [
        { id: '1s', name: '1s', objects: [gruppen['1s']] },
        { id: '2s', name: '2s', objects: [gruppen['2s']] },
        { id: '2p', name: '2p_z', objects: [gruppen['2p']] },
        { id: '3s', name: '3s', objects: [gruppen['3s']] },
        { id: '3d', name: '3d', objects: [gruppen['3d']] },
        { id: 'legende', name: 'Legende', objects: [legende] },
      ],
      update(t) {
        // Langsame Eigenrotation macht die Knotenflächen räumlich erfassbar.
        orbitale.forEach((o, i) => {
          o.rotation.y = t * 0.12 * (1 + i * 0.05)
        })
      },
    }
  },

  info: {
    summary:
      'Die Punktwolken sind keine künstlerische Darstellung: Jeder Punkt wurde per Rejection-Sampling aus der exakten Wahrscheinlichkeitsdichte |ψ_nlm(r,θ,φ)|² des Wasserstoffatoms gezogen. Die Punktdichte entspricht damit direkt der Aufenthaltswahrscheinlichkeit, die Farbe dem Vorzeichen der Wellenfunktion.',
    sections: [
      {
        title: 'Separationsansatz',
        body: [
          'Wegen des kugelsymmetrischen Coulomb-Potentials separiert die Schrödinger-Gleichung: ψ_nlm(r,θ,φ) = R_nl(r) · Y_lm(θ,φ).',
          'Der Radialteil R_nl enthält die zugeordneten Laguerre-Polynome, der Winkelteil Y_lm die Kugelflächenfunktionen. Für die Darstellung werden die reellen Linearkombinationen verwendet (p_x, p_y, p_z statt m = −1, 0, +1).',
          'Beispiel 2p: R₂₁(r) ∝ r·e^(−r/2a₀), Y₁₀ ∝ cos θ. Das Produkt verschwindet in der Ebene z = 0 – genau die sichtbare Knotenebene.',
        ],
      },
      {
        title: 'Knotenstruktur',
        body: [
          'Gesamtzahl der Knotenflächen: n − 1. Davon sind l winkelabhängig (Ebenen/Kegel) und n − l − 1 radial (Kugelschalen).',
          '1s: keine Knoten. 2s: eine Knotenkugel bei r = 2a₀. 2p: eine Knotenebene. 3d: zwei Winkelknoten, kein Radialknoten.',
          'An einem Knoten ist die Aufenthaltswahrscheinlichkeit exakt null – im Modell als sichtbare Lücke in der Punktwolke erkennbar.',
        ],
      },
      {
        title: 'Energie und Entartung',
        body: [
          'E_n = −(m_e e⁴)/(8ε₀²h²n²) = −13,606 eV/n². Beim reinen Coulomb-Problem hängt die Energie nur von n ab: 2s und 2p sind entartet (zufällige Entartung der 1/r-Symmetrie, SO(4)).',
          'In Mehrelektronenatomen hebt die Abschirmung diese Entartung auf – daher die Reihenfolge 2s < 2p und die (n+l)-Regel.',
          'Relativistische Korrekturen und Spin-Bahn-Kopplung liefern die Feinstruktur (Größenordnung α² ≈ 5·10⁻⁵ relativ), die Hyperfeinstruktur zusätzlich die berühmte 21-cm-Linie.',
        ],
      },
      {
        title: 'Radiale Aufenthaltswahrscheinlichkeit',
        body: [
          'Wichtige Unterscheidung: |ψ|² ist maximal am Kern (für s-Orbitale), aber die radiale Verteilungsfunktion P(r) = 4πr²|R_nl(r)|² hat ihr Maximum beim Bohr-Radius a₀ – weil das Volumenelement mit r² wächst.',
          'Der Erwartungswert ⟨r⟩ = (a₀/2)·[3n² − l(l+1)] liegt stets über dem Maximum von P(r).',
        ],
      },
    ],
    facts: [
      { k: 'Bohr-Radius a₀', v: '52,918 pm' },
      { k: 'Grundzustandsenergie', v: '−13,606 eV' },
      { k: 'Rydberg-Konstante', v: '1,097·10⁷ m⁻¹' },
      { k: 'Knotenflächen gesamt', v: 'n − 1' },
      { k: 'Radialknoten', v: 'n − l − 1' },
      { k: 'Entartungsgrad (ohne Spin)', v: 'n²' },
      { k: 'Ionisierungsenergie H', v: '13,6 eV = 1312 kJ/mol' },
      { k: 'Feinstrukturkonstante α', v: '1/137,036' },
    ],
    exam: [
      'Warum ist das Maximum von P(r) = 4πr²|R|² bei a₀, während |ψ|² am Kern maximal ist?',
      'Knotenzahl aus n und l bestimmen und im Bild wiedererkennen.',
      'Warum sind 2s und 2p im H-Atom entartet, in Li aber nicht?',
      'Auswahlregeln für Dipolübergänge: Δl = ±1, Δm = 0, ±1 – Begründung über das Übergangsmatrixelement.',
    ],
  },
}
