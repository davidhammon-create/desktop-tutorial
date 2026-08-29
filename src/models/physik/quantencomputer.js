import * as THREE from 'three'
import { atom, bond, glow, glass, label, leader, metal, std, ring, UI, V } from '../../three/lib'

/**
 * Supraleitender Quantencomputer (Transmon-Architektur, IBM/Google-Bauart).
 * Maßstab: 1 Einheit ≈ 5 cm. Kryostat-Höhe real ≈ 2 m.
 */
export default {
  id: 'quantencomputer',
  name: 'Quantencomputer (Transmon)',
  discipline: 'physik',
  level: 'Master',
  tagline: 'Kryostat, Josephson-Qubit und Bloch-Kugel',
  scale: '1 Einheit ≈ 5 cm',

  build() {
    const group = new THREE.Group()
    const kryostat = new THREE.Group()
    const verkabelung = new THREE.Group()
    const chip = new THREE.Group()
    const bloch = new THREE.Group()
    const beschriftung = new THREE.Group()

    // --- Kühlstufen des Mischkryostaten (Temperaturen realer 3He/4He-Anlagen) ---
    const stufen = [
      { y: 9, r: 6.0, T: '300 K', c: 0x868e96, note: 'Raumtemperatur-Flansch' },
      { y: 6, r: 5.2, T: '50 K', c: 0x74c0fc, note: 'Pulsrohrkühler, 1. Stufe' },
      { y: 3, r: 4.4, T: '4 K', c: 0x4dabf7, note: 'Pulsrohrkühler, 2. Stufe' },
      { y: 0.5, r: 3.6, T: '800 mK', c: 0x4c6ef5, note: 'Still (Verdampfer)' },
      { y: -2, r: 2.8, T: '100 mK', c: 0x7048e8, note: 'Kaltplatte' },
      { y: -4.5, r: 2.0, T: '10 mK', c: 0xd0bfff, note: 'Mischkammer' },
    ]

    stufen.forEach((s, i) => {
      const platte = new THREE.Mesh(
        new THREE.CylinderGeometry(s.r, s.r, 0.28, 64),
        metal(s.c, { roughness: 0.35 }),
      )
      platte.position.y = s.y
      platte.castShadow = true
      platte.receiveShadow = true
      kryostat.add(platte)

      // Tragstangen zur nächsten Stufe
      if (i < stufen.length - 1) {
        const next = stufen[i + 1]
        for (let k = 0; k < 3; k++) {
          const a = (k / 3) * Math.PI * 2
          kryostat.add(
            bond(
              [Math.cos(a) * (s.r - 0.6), s.y, Math.sin(a) * (s.r - 0.6)],
              [Math.cos(a) * (next.r - 0.5), next.y, Math.sin(a) * (next.r - 0.5)],
              { radius: 0.09, color: 0xadb5bd },
            ),
          )
        }
      }

      const l = label(`${s.T} · ${s.note}`, [s.r + 0.4, s.y + 0.5, 0], i >= 4 ? 'cold' : 'default')
      beschriftung.add(l, leader([s.r, s.y, 0], [s.r + 0.4, s.y + 0.45, 0]))
    })

    // --- Koaxiale Mikrowellenleitungen mit Attenuatoren --------------------------
    // Dämpfung pro Stufe (20/10/6 dB) unterdrückt thermisches Rauschen der warmen Stufen.
    const daempfung = [20, 10, 6, 3]
    for (let n = 0; n < 8; n++) {
      const a = (n / 8) * Math.PI * 2
      const rad = 1.3
      const x = Math.cos(a) * rad
      const z = Math.sin(a) * rad
      verkabelung.add(
        bond([x, 9, z], [x, -4.5, z], { radius: 0.055, color: 0xffd43b, segments: 10 }),
      )
      daempfung.forEach((db, i) => {
        const y = stufen[i + 1].y
        const att = new THREE.Mesh(
          new THREE.CylinderGeometry(0.14, 0.14, 0.5, 12),
          metal(0xced4da, { roughness: 0.4 }),
        )
        att.position.set(x, y, z)
        verkabelung.add(att)
        if (n === 0) {
          beschriftung.add(label(`−${db} dB`, [x - 0.2, y + 0.1, z], 'muted'))
        }
      })
    }

    // --- Quantenchip an der Mischkammer -----------------------------------------
    const traeger = new THREE.Mesh(new THREE.BoxGeometry(3.2, 0.16, 3.2), metal(0xffd43b, { roughness: 0.3 }))
    traeger.position.y = -5.6
    chip.add(traeger)

    const substrat = new THREE.Mesh(
      new THREE.BoxGeometry(2.6, 0.12, 2.6),
      std(0x212529, { roughness: 0.25, metalness: 0.5 }),
    )
    substrat.position.y = -5.44
    chip.add(substrat)

    // 3×3-Gitter aus Transmon-Qubits (feste Kopplung über Resonatoren)
    const qubits = []
    for (let i = 0; i < 3; i++) {
      for (let j = 0; j < 3; j++) {
        const x = (i - 1) * 0.8
        const z = (j - 1) * 0.8
        // Kreuzförmige Transmon-Insel ("Xmon"-Geometrie)
        const arm1 = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.03, 0.12), glow(0x5b8def, 0.5))
        const arm2 = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.03, 0.5), glow(0x5b8def, 0.5))
        arm1.position.set(x, -5.36, z)
        arm2.position.set(x, -5.36, z)
        chip.add(arm1, arm2)
        qubits.push(arm1, arm2)

        // Josephson-Kontakt: zwei Supraleiter, getrennt durch ~1–2 nm Al2O3
        const jj = atom([x + 0.28, -5.34, z + 0.28], 0.06, 0xff922b, { material: glow(0xff922b, 1.0) })
        chip.add(jj)
        qubits.push(jj)

        // Auslese-Resonator (λ/4-Leitung, mäanderförmig)
        for (let m = 0; m < 4; m++) {
          const seg = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.02, 0.04), std(0x9775fa))
          seg.position.set(x + (m % 2 === 0 ? 0.1 : -0.1), -5.36, z + 0.34 + m * 0.05)
          chip.add(seg)
        }
      }
    }

    // Abschirmgehäuse (µ-Metall gegen Magnetfelder)
    const shield = new THREE.Mesh(
      new THREE.CylinderGeometry(2.4, 2.4, 2.4, 48, 1, true),
      glass(0x74c0fc, 0.1),
    )
    shield.position.y = -5.2
    chip.add(shield)

    beschriftung.add(
      label('Quantenchip: 9 Transmon-Qubits', [0, -6.4, 2.2], 'accent'),
      label('Josephson-Kontakt (Al/AlOₓ/Al)', [2.0, -5.0, 1.6], 'warm'),
      label('λ/4-Auslese-Resonator', [-2.2, -5.6, 1.2], 'accent2'),
    )

    // --- Bloch-Kugel: Zustandsraum eines einzelnen Qubits ------------------------
    const blochX = 9
    const kugel = new THREE.Mesh(new THREE.SphereGeometry(2.2, 48, 32), glass(0x5b8def, 0.12))
    kugel.position.set(blochX, 0, 0)
    bloch.add(kugel)

    const aequator = ring(2.2, 0.02, 0xced4da)
    aequator.rotation.x = Math.PI / 2
    aequator.position.set(blochX, 0, 0)
    const meridian = ring(2.2, 0.02, 0xced4da)
    meridian.position.set(blochX, 0, 0)
    bloch.add(aequator, meridian)

    const achse = (dir, color) =>
      bond(
        [blochX - dir[0] * 2.5, -dir[1] * 2.5, -dir[2] * 2.5],
        [blochX + dir[0] * 2.5, dir[1] * 2.5, dir[2] * 2.5],
        { radius: 0.02, color },
      )
    bloch.add(achse([1, 0, 0], 0x868e96), achse([0, 1, 0], 0x868e96), achse([0, 0, 1], 0x868e96))

    const zustand = bond([blochX, 0, 0], [blochX, 2.2, 0], { radius: 0.07, material: glow(0xff922b, 0.8) })
    const spitze = atom([blochX, 2.2, 0], 0.16, 0xff922b, { material: glow(0xff922b, 1.0) })
    bloch.add(zustand, spitze)

    beschriftung.add(
      label('|0⟩', [blochX, 2.9, 0], 'accent'),
      label('|1⟩', [blochX, -2.6, 0], 'accent'),
      label('Bloch-Kugel: |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩', [blochX, -3.6, 0], 'muted'),
    )

    group.add(kryostat, verkabelung, chip, bloch, beschriftung)

    // --- Animation ---------------------------------------------------------------
    // Rabi-Oszillation: der Zustandsvektor präzediert und nutiert auf der Bloch-Kugel.
    return {
      group,
      camera: { position: [14, 6, 30], target: [3, 0, 0] },
      layers: [
        { id: 'kryostat', name: 'Kryostat-Stufen', objects: [kryostat] },
        { id: 'verkabelung', name: 'Mikrowellen-Verkabelung', objects: [verkabelung] },
        { id: 'chip', name: 'Quantenchip', objects: [chip] },
        { id: 'bloch', name: 'Bloch-Kugel', objects: [bloch] },
        { id: 'beschriftung', name: 'Beschriftungen', objects: [beschriftung] },
      ],
      update(t) {
        const theta = (t * 0.6) % (Math.PI * 2)
        const phi = t * 1.7
        const r = 2.2
        const p = V(
          blochX + r * Math.sin(theta) * Math.cos(phi),
          r * Math.cos(theta),
          r * Math.sin(theta) * Math.sin(phi),
        )
        spitze.position.copy(p)
        const dir = new THREE.Vector3(p.x - blochX, p.y, p.z)
        zustand.position.set(blochX + dir.x / 2, dir.y / 2, dir.z / 2)
        zustand.quaternion.setFromUnitVectors(V(0, 1, 0), dir.clone().normalize())

        // Qubits pulsieren mit der Besetzungswahrscheinlichkeit |c1|² = sin²(θ/2)
        const p1 = Math.sin(theta / 2) ** 2
        qubits.forEach((q, i) => {
          if (q.material?.emissiveIntensity !== undefined) {
            q.material.emissiveIntensity = 0.3 + p1 * (0.9 + 0.3 * Math.sin(t * 3 + i))
          }
        })
      },
    }
  },

  info: {
    summary:
      'Supraleitende Transmon-Qubits sind derzeit die verbreitetste Plattform für Quantenprozessoren. Ein Qubit ist hier ein nichtlinearer LC-Schwingkreis, dessen Nichtlinearität von einem Josephson-Kontakt stammt – erst sie macht die untersten beiden Energieniveaus adressierbar, ohne höhere Zustände anzuregen.',
    sections: [
      {
        title: 'Physikalisches Prinzip',
        body: [
          'Ein Josephson-Kontakt (zwei Supraleiter, getrennt durch eine ~1–2 nm dünne Al₂O₃-Barriere) verhält sich wie eine nichtlineare Induktivität. Zusammen mit einer Shunt-Kapazität entsteht ein anharmonischer Oszillator mit Hamiltonian H = 4E_C n² − E_J cos φ.',
          'Im Transmon-Regime gilt E_J/E_C ≳ 50. Dadurch wird die Empfindlichkeit gegenüber Ladungsrauschen exponentiell unterdrückt (die Ladungsdispersion fällt wie e^(−√(8E_J/E_C))), auf Kosten einer reduzierten Anharmonizität α/2π ≈ −200 bis −300 MHz.',
          'Die Übergangsfrequenz f₀₁ ≈ (√(8E_J E_C) − E_C)/h liegt typischerweise bei 4–6 GHz – bewusst im Mikrowellenbereich, weil dort kommerzielle Elektronik existiert und ħω ≫ k_BT bei 10 mK erfüllt ist.',
        ],
      },
      {
        title: 'Warum 10 Millikelvin?',
        body: [
          'Damit das Qubit im Grundzustand startet, muss die thermische Energie klein gegen den Niveauabstand sein: k_B T ≪ h f₀₁. Bei f₀₁ = 5 GHz entspricht h f₀₁ einer Temperatur von ≈ 240 mK.',
          'Bei 10 mK ergibt sich eine thermische Restbesetzung von P₁ = e^(−hf/k_BT) ≈ e^(−24) ≈ 4·10⁻¹¹ – praktisch perfekte Initialisierung.',
          'Erreicht wird das mit einem ³He/⁴He-Mischkryostaten: Unterhalb von 870 mK trennt sich das Isotopengemisch in eine ³He-reiche und eine ³He-arme Phase. Das Verdünnen von ³He über die Phasengrenze ist endotherm und funktioniert – anders als Verdampfungskühlung – bis hinab zu wenigen mK.',
        ],
      },
      {
        title: 'Ansteuerung und Auslese',
        body: [
          'Einzelqubit-Gatter sind kalibrierte Mikrowellenpulse (Rabi-Oszillation, typ. 20–50 ns). Der Zustandsvektor rotiert dabei auf der Bloch-Kugel – im Modell rechts animiert.',
          'Zwei-Qubit-Gatter (CZ, iSWAP, Cross-Resonance) nutzen die Kopplung benachbarter Qubits über gemeinsame Resonatoren oder abstimmbare Koppler.',
          'Ausgelesen wird dispersiv: Ein λ/4-Resonator ist an das Qubit gekoppelt, seine Resonanzfrequenz verschiebt sich um ±χ je nach Qubit-Zustand. Ein schwacher Messton tastet diese Verschiebung ab, ohne das Qubit direkt zu stören (Quantum Non-Demolition).',
          'Die Dämpfungsglieder (−20/−10/−6/−3 dB) auf den Kühlstufen sind essenziell: Sie thermalisieren das Rauschen der 300-K-Elektronik stufenweise herunter, sonst würde Schwarzkörperstrahlung die Qubits anregen.',
        ],
      },
      {
        title: 'Dekohärenz – der limitierende Faktor',
        body: [
          'T₁ (Energierelaxation) und T₂ (Phasenkohärenz) liegen bei heutigen Transmons typischerweise bei 100–300 µs. Es gilt stets 1/T₂ = 1/(2T₁) + 1/T_φ.',
          'Hauptverlustkanäle: dielektrische Verluste durch Zwei-Niveau-Systeme (TLS) an Oberflächen und Grenzflächen, quasiteilchenbedingte Verluste sowie der Purcell-Effekt über den Auslese-Resonator (mit Purcell-Filtern unterdrückt).',
          'Die Fehlerrate pro Gatter (~10⁻³) liegt noch über der Schwelle für praktische Fehlerkorrektur; der Surface Code benötigt etwa 10³–10⁴ physikalische Qubits pro logischem Qubit.',
        ],
      },
    ],
    facts: [
      { k: 'Qubit-Frequenz f₀₁', v: '4–6 GHz' },
      { k: 'Verhältnis E_J/E_C', v: '≳ 50 (Transmon-Regime)' },
      { k: 'Anharmonizität α/2π', v: '−200 bis −300 MHz' },
      { k: 'Basistemperatur', v: '10–20 mK' },
      { k: 'Kohärenzzeit T₁ / T₂', v: '100–300 µs' },
      { k: 'Gatterdauer (1 Qubit)', v: '20–50 ns' },
      { k: 'Gatterfehler', v: '~10⁻³ (2-Qubit)' },
      { k: 'Josephson-Barriere', v: '1–2 nm Al₂O₃' },
    ],
    exam: [
      'Warum ist Anharmonizität für ein Qubit zwingend nötig? (Ein harmonischer Oszillator hat äquidistante Niveaus – ein Puls, der 0→1 treibt, treibt auch 1→2.)',
      'Herleitung von P₁ = e^(−hf/k_BT) und Abschätzung der nötigen Temperatur.',
      'Unterschied zwischen T₁, T₂ und T₂* sowie deren Messung (Rabi, Ramsey, Hahn-Echo).',
      'Prinzip der dispersiven Auslese und Bedeutung des QND-Charakters.',
    ],
  },
}
