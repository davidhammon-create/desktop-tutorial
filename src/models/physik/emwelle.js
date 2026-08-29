import * as THREE from 'three'
import { arrow, bond, glow, label, std, V } from '../../three/lib'

/**
 * Ebene elektromagnetische Welle im Vakuum: E ⊥ B ⊥ k, Poynting-Vektor,
 * Phasengleichheit von E und B. Maßstab: 1 Einheit = λ/8.
 */
export default {
  id: 'emwelle',
  name: 'Elektromagnetische Welle',
  discipline: 'physik',
  level: 'Bachelor',
  tagline: 'E- und B-Feld, Poynting-Vektor und Polarisation',
  scale: '1 Einheit = λ/8',

  build() {
    const group = new THREE.Group()
    const eFeld = new THREE.Group()
    const bFeld = new THREE.Group()
    const poynting = new THREE.Group()
    const achsen = new THREE.Group()
    const zirkular = new THREE.Group()

    const N = 60
    const laenge = 40
    const amp = 4
    const k = (2 * Math.PI) / (laenge / 2.5) // Wellenzahl

    // --- Ausbreitungsachse -------------------------------------------------------
    achsen.add(bond([-laenge / 2, 0, 0], [laenge / 2 + 3, 0, 0], { radius: 0.06, color: 0x868e96 }))
    achsen.add(arrow([laenge / 2 + 3, 0, 0], [laenge / 2 + 5, 0, 0], 0xced4da, { radius: 0.12 }))
    achsen.add(label('Ausbreitungsrichtung k', [laenge / 2 + 6.5, 0, 0], 'muted'))
    achsen.add(label('E (elektrisch)', [-laenge / 2 - 1, amp + 1.5, 0], 'hot'))
    achsen.add(label('B (magnetisch)', [-laenge / 2 - 1, 0, amp + 2], 'accent'))

    // --- Feldvektoren als diskrete Pfeile ----------------------------------------
    const eVektoren = []
    const bVektoren = []
    const eMat = glow(0xff6b6b, 0.45)
    const bMat = glow(0x4dabf7, 0.45)

    for (let i = 0; i < N; i++) {
      const x = -laenge / 2 + (i / (N - 1)) * laenge
      const e = new THREE.Mesh(new THREE.CylinderGeometry(0.09, 0.09, 1, 8), eMat)
      e.userData.x = x
      eFeld.add(e)
      eVektoren.push(e)

      const b = new THREE.Mesh(new THREE.CylinderGeometry(0.09, 0.09, 1, 8), bMat)
      b.userData.x = x
      bFeld.add(b)
      bVektoren.push(b)
    }

    // Einhüllende Kurven, damit die Sinusform sofort erkennbar ist
    const eKurve = new THREE.Line(
      new THREE.BufferGeometry(),
      new THREE.LineBasicMaterial({ color: 0xff6b6b }),
    )
    const bKurve = new THREE.Line(
      new THREE.BufferGeometry(),
      new THREE.LineBasicMaterial({ color: 0x4dabf7 }),
    )
    eFeld.add(eKurve)
    bFeld.add(bKurve)

    // --- Poynting-Vektor S = (1/µ₀)·E × B ---------------------------------------
    const sPfeile = []
    for (let i = 0; i < 10; i++) {
      const x = -laenge / 2 + (i / 9) * laenge
      const p = arrow([x, 0, 0], [x + 2.4, 0, 0], 0x51cf66, { radius: 0.07 })
      p.userData.x = x
      poynting.add(p)
      sPfeile.push(p)
    }
    poynting.add(label('S = (1/µ₀)·E × B  (Energiefluss)', [0, -amp - 2.5, 0], 'green'))

    // --- Zirkulare Polarisation als Vergleich (versetzt dargestellt) -------------
    const zirkPunkte = []
    for (let i = 0; i < 40; i++) {
      const s = new THREE.Mesh(new THREE.SphereGeometry(0.16, 12, 10), glow(0x9775fa, 0.6))
      s.userData.x = -laenge / 2 + (i / 39) * laenge
      zirkular.add(s)
      zirkPunkte.push(s)
    }
    zirkular.position.z = -16
    zirkular.add(label('Zirkulare Polarisation (E_y und E_z um 90° phasenverschoben)', [0, amp + 2, 0], 'accent2'))

    group.add(achsen, eFeld, bFeld, poynting, zirkular)

    const gleichung = new THREE.Group()
    gleichung.add(
      label('E(x,t) = E₀·sin(kx − ωt)·ŷ      B(x,t) = (E₀/c)·sin(kx − ωt)·ẑ', [0, -amp - 4.5, 0], 'muted'),
      label('c = 1/√(ε₀µ₀) = 299 792 458 m/s      |E|/|B| = c', [0, -amp - 6, 0], 'muted'),
    )
    group.add(gleichung)

    return {
      group,
      camera: { position: [0, 14, 46], target: [0, -1, -6] },
      layers: [
        { id: 'e', name: 'E-Feld', objects: [eFeld] },
        { id: 'b', name: 'B-Feld', objects: [bFeld] },
        { id: 'poynting', name: 'Poynting-Vektor', objects: [poynting] },
        { id: 'zirkular', name: 'Zirkulare Polarisation', objects: [zirkular] },
        { id: 'achsen', name: 'Achsen & Beschriftung', objects: [achsen] },
        { id: 'gleichung', name: 'Wellengleichung', objects: [gleichung] },
      ],
      update(t) {
        const omega = 2.2
        const ePts = []
        const bPts = []

        eVektoren.forEach((mesh, i) => {
          const x = mesh.userData.x
          const val = Math.sin(k * x - omega * t) * amp
          mesh.scale.y = Math.max(0.001, Math.abs(val))
          mesh.position.set(x, val / 2, 0)
          ePts.push(V(x, val, 0))
        })
        eKurve.geometry.setFromPoints(ePts)

        // B ist in Phase mit E (im Vakuum!), aber um 90° im Raum gedreht.
        bVektoren.forEach((mesh, i) => {
          const x = mesh.userData.x
          const val = Math.sin(k * x - omega * t) * amp * 0.75
          mesh.scale.y = Math.max(0.001, Math.abs(val))
          mesh.position.set(x, 0, val / 2)
          mesh.rotation.x = Math.PI / 2
          bPts.push(V(x, 0, val))
        })
        bKurve.geometry.setFromPoints(bPts)

        // S ∝ E×B ∝ sin², also stets positiv – die Energie fließt nur vorwärts.
        sPfeile.forEach((p) => {
          const s = Math.sin(k * p.userData.x - omega * t) ** 2
          p.scale.setScalar(0.25 + s * 1.1)
        })

        // Zirkular: E_y = cos, E_z = sin → Spirale
        zirkPunkte.forEach((s) => {
          const ph = k * s.userData.x - omega * t
          s.position.set(s.userData.x, Math.cos(ph) * amp * 0.8, Math.sin(ph) * amp * 0.8)
        })
      },
    }
  },

  info: {
    summary:
      'Eine ebene elektromagnetische Welle im Vakuum ist die einfachste nichttriviale Lösung der Maxwell-Gleichungen. Entscheidend und oft falsch erinnert: E und B schwingen in Phase (nicht um 90° versetzt) – die 90°-Beziehung ist rein räumlich, nicht zeitlich.',
    sections: [
      {
        title: 'Von Maxwell zur Wellengleichung',
        body: [
          'Im ladungs- und stromfreien Vakuum lauten die Maxwell-Gleichungen: ∇·E = 0, ∇·B = 0, ∇×E = −∂B/∂t, ∇×B = µ₀ε₀·∂E/∂t.',
          'Bildet man die Rotation der dritten Gleichung und setzt die vierte ein, folgt mit ∇×(∇×E) = ∇(∇·E) − ∇²E direkt: ∇²E = µ₀ε₀·∂²E/∂t².',
          'Das ist die Wellengleichung mit Ausbreitungsgeschwindigkeit c = 1/√(ε₀µ₀). Maxwell berechnete diesen Wert 1862 und erkannte, dass Licht eine elektromagnetische Welle sein muss – eine der größten Vereinheitlichungen der Physik.',
        ],
      },
      {
        title: 'Transversalität und Phasenbeziehung',
        body: [
          'Aus ∇·E = 0 folgt für eine ebene Welle k·E₀ = 0: das E-Feld steht senkrecht zur Ausbreitungsrichtung. Gleiches gilt für B. Elektromagnetische Wellen sind rein transversal – deshalb sind sie polarisierbar.',
          'Aus ∇×E = −∂B/∂t folgt k×E₀ = ω·B₀, also |B₀| = |E₀|/c und B ⊥ E. Die drei Vektoren E, B, k bilden in dieser Reihenfolge ein Rechtssystem.',
          'Weil beide Felder denselben Sinusfaktor sin(kx − ωt) tragen, erreichen sie gleichzeitig ihr Maximum. (In einem leitfähigen Medium ist das anders – dort eilt B dem E-Feld nach.)',
        ],
      },
      {
        title: 'Energie und Impuls',
        body: [
          'Energiedichte: u = ½ε₀E² + B²/(2µ₀). Wegen B = E/c tragen elektrisches und magnetisches Feld exakt gleich viel bei.',
          'Poynting-Vektor S = (1/µ₀)·E × B gibt Betrag und Richtung des Energieflusses. Er ist ∝ sin², also nie negativ – Energie fließt stets in k-Richtung.',
          'Zeitmittel (Intensität): I = ⟨S⟩ = ½ε₀cE₀² = E₀²/(2µ₀c). Für Sonnenlicht an der Erdoberfläche gilt I ≈ 1 kW/m², daraus E₀ ≈ 870 V/m.',
          'Der Impulsfluss erzeugt Strahlungsdruck p = I/c (bzw. 2I/c bei vollständiger Reflexion) – Grundlage von Sonnensegeln und optischen Pinzetten.',
        ],
      },
      {
        title: 'Polarisation',
        body: [
          'Linear: E-Feld schwingt in einer festen Ebene. Zirkular: zwei senkrechte Komponenten gleicher Amplitude mit 90° Phasendifferenz – die Feldspitze beschreibt eine Schraubenlinie (im Modell violett dargestellt).',
          'Zirkular polarisierte Photonen tragen den Spin ±ħ entlang k; das ist die klassische Entsprechung des Photonenspins 1.',
          'Elliptische Polarisation ist der allgemeine Fall; lineare und zirkulare sind Spezialfälle. Beschreibung über Jones-Vektoren oder Stokes-Parameter.',
        ],
      },
    ],
    facts: [
      { k: 'Lichtgeschwindigkeit c', v: '299 792 458 m/s (exakt)' },
      { k: 'ε₀', v: '8,854·10⁻¹² F/m' },
      { k: 'µ₀', v: '1,257·10⁻⁶ H/m' },
      { k: 'Vakuum-Wellenwiderstand', v: 'Z₀ = √(µ₀/ε₀) = 376,73 Ω' },
      { k: '|E|/|B|', v: '= c' },
      { k: 'Intensität', v: 'I = ½ε₀cE₀²' },
      { k: 'Solarkonstante', v: '1361 W/m²' },
      { k: 'Strahlungsdruck (Absorption)', v: 'p = I/c' },
    ],
    exam: [
      'Wellengleichung aus den Maxwell-Gleichungen herleiten (Rotation der Rotation).',
      'Warum sind E und B in Phase? Häufiger Fehler in Klausuren.',
      'Aus I = 1 kW/m² die Feldamplituden E₀ und B₀ berechnen.',
      'Transversalität aus ∇·E = 0 begründen.',
    ],
  },
}
