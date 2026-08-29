import * as THREE from 'three'
import { atom, bond, CPK, label, std, V } from '../../three/lib'

/**
 * Konformationsanalyse des Cyclohexans: Sesselform, Ringinversion und
 * der Wechsel axial ⇄ äquatorial. Maßstab: 1 Einheit = 1 Å.
 */
export default {
  id: 'cyclohexan',
  name: 'Cyclohexan – Konformationsanalyse',
  discipline: 'chemie',
  level: 'Bachelor',
  tagline: 'Sessel, Ringinversion und A-Werte',
  scale: '1 Einheit = 1 Å',

  build() {
    const group = new THREE.Group()
    const sessel = new THREE.Group()
    const axialG = new THREE.Group()
    const aequatorialG = new THREE.Group()
    const wanne = new THREE.Group()
    const methyl = new THREE.Group()

    const rRing = 1.46 // Ringradius in Å
    const A0 = 0.25 // Faltungsamplitude → C–C = 1,54 Å
    const cMat = std(CPK.C, { roughness: 0.35 })
    const hAxMat = std(0xff6b6b, { roughness: 0.3 })
    const hEqMat = std(0x4dabf7, { roughness: 0.3 })

    // --- Sessel: 6 C, je 1 axiales und 1 äquatoriales H -------------------------
    const cAtome = []
    const hAxial = []
    const hAequatorial = []
    const cBindungen = []
    const axBindungen = []
    const eqBindungen = []

    for (let i = 0; i < 6; i++) {
      const th = (i / 6) * Math.PI * 2
      const s = i % 2 === 0 ? 1 : -1
      const c = atom([Math.cos(th) * rRing, A0 * s, Math.sin(th) * rRing], 0.33, CPK.C, { material: cMat })
      c.userData = { th, s }
      sessel.add(c)
      cAtome.push(c)

      const ha = atom([0, 0, 0], 0.19, 0xff6b6b, { material: hAxMat })
      const he = atom([0, 0, 0], 0.19, 0x4dabf7, { material: hEqMat })
      axialG.add(ha)
      aequatorialG.add(he)
      hAxial.push(ha)
      hAequatorial.push(he)
    }

    // Bindungen werden pro Frame neu ausgerichtet – daher als Platzhalter erzeugt.
    for (let i = 0; i < 6; i++) {
      const b = bond([0, 0, 0], [0, 1, 0], { radius: 0.09, color: 0x868e96 })
      sessel.add(b)
      cBindungen.push(b)
      const ba = bond([0, 0, 0], [0, 1, 0], { radius: 0.06, color: 0xff8787 })
      axialG.add(ba)
      axBindungen.push(ba)
      const be = bond([0, 0, 0], [0, 1, 0], { radius: 0.06, color: 0x74c0fc })
      aequatorialG.add(be)
      eqBindungen.push(be)
    }

    const setzeBindung = (mesh, a, b, r) => {
      const dir = new THREE.Vector3().subVectors(b, a)
      const len = dir.length()
      mesh.scale.set(1, len, 1)
      mesh.position.copy(a).addScaledVector(dir, 0.5)
      mesh.quaternion.setFromUnitVectors(V(0, 1, 0), dir.normalize())
    }

    // --- Wannenform als Vergleich (statisch, energetisch ungünstig) -------------
    wanne.position.set(6.5, 0, 0)
    const wPos = []
    for (let i = 0; i < 6; i++) {
      const th = (i / 6) * Math.PI * 2
      // Wanne: C1 und C4 nach oben, Rest planar
      const y = i === 0 || i === 3 ? 0.65 : 0
      wPos.push(V(Math.cos(th) * rRing, y, Math.sin(th) * rRing))
    }
    wPos.forEach((p, i) => {
      wanne.add(atom(p, 0.33, CPK.C, { material: cMat }))
      wanne.add(bond(p, wPos[(i + 1) % 6], { radius: 0.09, color: 0x868e96 }))
    })
    // Flagpole-Wechselwirkung zwischen C1 und C4
    wanne.add(atom([wPos[0].x, wPos[0].y + 1.05, wPos[0].z], 0.19, 0xffd43b, { material: std(0xffd43b) }))
    wanne.add(atom([wPos[3].x, wPos[3].y + 1.05, wPos[3].z], 0.19, 0xffd43b, { material: std(0xffd43b) }))
    wanne.add(
      bond([wPos[0].x, wPos[0].y + 1.05, wPos[0].z], [wPos[3].x, wPos[3].y + 1.05, wPos[3].z], {
        radius: 0.025,
        color: 0xffd43b,
      }),
    )
    wanne.add(
      label('Wanne: +27 kJ/mol', [0, 2.4, 0], 'warm'),
      label('Flagpole-Abstoßung C1/C4 · ekliptische Bindungen', [0, 1.85, 0], 'muted'),
    )

    // --- Methylcyclohexan: axial vs. äquatorial (A-Wert) ------------------------
    methyl.position.set(-6.5, 0, 0)
    for (let i = 0; i < 6; i++) {
      const th = (i / 6) * Math.PI * 2
      const s = i % 2 === 0 ? 1 : -1
      const p = V(Math.cos(th) * rRing, A0 * s, Math.sin(th) * rRing)
      methyl.add(atom(p, 0.3, CPK.C, { material: cMat }))
      const th2 = ((i + 1) / 6) * Math.PI * 2
      const s2 = (i + 1) % 2 === 0 ? 1 : -1
      methyl.add(
        bond(p, V(Math.cos(th2) * rRing, A0 * s2, Math.sin(th2) * rRing), { radius: 0.09, color: 0x868e96 }),
      )
    }
    // Axiale Methylgruppe an C1 mit den beiden 1,3-diaxialen H
    const c1 = V(rRing, A0, 0)
    const me = V(rRing, A0 + 1.53, 0)
    methyl.add(atom(me, 0.3, CPK.C, { material: std(0x51cf66) }))
    methyl.add(bond(c1, me, { radius: 0.09, color: 0x51cf66 }))
    ;[2, 4].forEach((i) => {
      const th = (i / 6) * Math.PI * 2
      const p = V(Math.cos(th) * rRing, A0 + 1.09, Math.sin(th) * rRing)
      methyl.add(atom(p, 0.19, 0xff6b6b, { material: hAxMat }))
      methyl.add(bond(me, p, { radius: 0.02, color: 0xff6b6b }))
    })
    methyl.add(
      label('axiale Methylgruppe', [0, 2.8, 0], 'green'),
      label('1,3-diaxiale Wechselwirkung: A-Wert 7,3 kJ/mol', [0, 2.2, 0], 'muted'),
      label('Gleichgewicht 95 : 5 zugunsten äquatorial', [0, -2.2, 0], 'muted'),
    )

    const legende = new THREE.Group()
    legende.add(
      label('rot = axial   ·   blau = äquatorial', [0, 2.9, 0], 'muted'),
      label('Ringinversion: ΔG‡ = 45 kJ/mol · ~10⁵ Inversionen pro Sekunde bei 25 °C', [0, -2.6, 0], 'warm'),
      label('Bei −90 °C im ¹H-NMR einfrierbar → zwei getrennte Signalsätze', [0, -3.2, 0], 'muted'),
    )

    group.add(sessel, axialG, aequatorialG, wanne, methyl, legende)

    return {
      group,
      camera: { position: [0, 5, 15], target: [0, 0, 0] },
      layers: [
        { id: 'sessel', name: 'Sessel-Ringgerüst', objects: [sessel] },
        { id: 'axial', name: 'axiale H (rot)', objects: [axialG] },
        { id: 'aequatorial', name: 'äquatoriale H (blau)', objects: [aequatorialG] },
        { id: 'wanne', name: 'Wannenform', objects: [wanne] },
        { id: 'methyl', name: 'Methylcyclohexan', objects: [methyl] },
        { id: 'legende', name: 'Legende', objects: [legende] },
      ],
      update(t) {
        // Ringinversion: die Faltungsamplitude kehrt ihr Vorzeichen um.
        // Axiale und äquatoriale Positionen tauschen dabei die Rolle.
        const A = A0 * Math.cos(t * 0.55)
        const positionen = []

        cAtome.forEach((c, i) => {
          const { th, s } = c.userData
          const p = V(Math.cos(th) * rRing, A * s, Math.sin(th) * rRing)
          c.position.copy(p)
          positionen.push(p)
        })

        for (let i = 0; i < 6; i++) {
          setzeBindung(cBindungen[i], positionen[i], positionen[(i + 1) % 6])

          const { th, s } = cAtome[i].userData
          const vorzeichen = A >= 0 ? s : -s
          const radial = V(Math.cos(th), 0, Math.sin(th))

          // Axial: senkrecht zur mittleren Ringebene
          const axDir = V(0, vorzeichen, 0)
          const axPos = positionen[i].clone().addScaledVector(axDir, 1.09)
          hAxial[i].position.copy(axPos)
          setzeBindung(axBindungen[i], positionen[i], axPos)

          // Äquatorial: überwiegend radial nach außen, leicht gegenläufig geneigt
          const eqDir = radial.clone().multiplyScalar(0.94).add(V(0, -vorzeichen * 0.34, 0)).normalize()
          const eqPos = positionen[i].clone().addScaledVector(eqDir, 1.09)
          hAequatorial[i].position.copy(eqPos)
          setzeBindung(eqBindungen[i], positionen[i], eqPos)
        }

        group.rotation.y = Math.sin(t * 0.2) * 0.5
      },
    }
  },

  info: {
    summary:
      'Cyclohexan ist nicht planar. Die Sesselkonformation ist praktisch spannungsfrei: alle Bindungswinkel liegen bei 111° (nahe am Tetraederwinkel) und alle Bindungen sind gestaffelt. Der Ring klappt bei Raumtemperatur etwa 10⁵-mal pro Sekunde um – dabei tauschen axiale und äquatoriale Positionen vollständig ihre Rollen.',
    sections: [
      {
        title: 'Warum kein planares Sechseck?',
        body: [
          'Ein planares Cyclohexan hätte Innenwinkel von 120° – nur 10,5° über dem Tetraederwinkel, die Baeyer-Ringspannung wäre also klein.',
          'Der eigentliche Grund für die Faltung ist die Pitzer-Spannung: Im planaren Ring wären alle 12 C–H-Bindungen ekliptisch, was etwa 6 × 12 kJ/mol an Torsionsspannung kostet.',
          'Die Sesselform löst beides: Bindungswinkel 111,4°, alle Torsionswinkel ±55° (nahezu perfekt gestaffelt). Die Gesamtspannungsenergie ist praktisch null – Cyclohexan ist der stabilste Cycloalkan-Ring.',
        ],
      },
      {
        title: 'Axial und äquatorial',
        body: [
          'Jedes C-Atom trägt ein axiales H (parallel zur C₃-Hauptachse, abwechselnd nach oben und unten) und ein äquatoriales H (nach außen geneigt).',
          'Bei der Ringinversion werden alle axialen Positionen äquatorial und umgekehrt – im Modell direkt beobachtbar. Die Konfiguration ändert sich dabei nicht, nur die Konformation.',
          'Der reale Inversionspfad läuft über Halbsessel (Übergangszustand, +45 kJ/mol) und Twist-Boat (Zwischenprodukt, +23 kJ/mol), nicht über die planare Form. Die Animation zeigt vereinfacht die reine Amplitudenumkehr, um den axial/äquatorial-Tausch klar sichtbar zu machen.',
          'Im ¹H-NMR ist die Inversion bei 25 °C zu schnell: man sieht ein einziges gemitteltes Signal. Unter −90 °C friert sie ein und liefert zwei getrennte Signalsätze – ein Standardbeispiel für dynamische NMR-Spektroskopie.',
        ],
      },
      {
        title: 'A-Werte und Substituenteneffekte',
        body: [
          'Ein axialer Substituent leidet unter 1,3-diaxialer Wechselwirkung mit den beiden axialen H an C3 und C5 (im Modell links dargestellt). Deshalb bevorzugen Substituenten die äquatoriale Position.',
          'Der A-Wert quantifiziert diese Präferenz: ΔG° für den Übergang axial → äquatorial. CH₃: 7,3 kJ/mol; iPr: 9,2; tBu: > 20; OH: 2,2–4,2; F: nur 0,6.',
          'Aus ΔG° = −RT·ln K folgt für Methylcyclohexan K ≈ 19, also ein Gleichgewicht von etwa 95:5 zugunsten äquatorial.',
          'Bei tert-Butyl ist die Präferenz so groß, dass der Ring praktisch fixiert ist – deshalb dient die tBu-Gruppe als konformativer Anker in Mechanismusstudien.',
        ],
      },
      {
        title: 'Konsequenzen für die Reaktivität',
        body: [
          'E2-Eliminierungen erfordern eine antiperiplanare Anordnung von H und Abgangsgruppe. Am Cyclohexanring bedeutet das: beide müssen axial stehen (trans-diaxial).',
          'Klassisches Beispiel: Menthylchlorid und Neomenthylchlorid eliminieren mit stark unterschiedlicher Geschwindigkeit und liefern verschiedene Produkte, weil nur bestimmte Konformere die trans-diaxiale Anordnung erreichen.',
          'Auch die SN2-Reaktivität und die Geschwindigkeit von Veresterungen hängen von der axialen/äquatorialen Lage der Gruppe ab – axiale Gruppen sind sterisch abgeschirmt.',
        ],
      },
    ],
    facts: [
      { k: 'C–C-Bindungslänge', v: '154 pm' },
      { k: 'Bindungswinkel (Sessel)', v: '111,4°' },
      { k: 'Torsionswinkel', v: '±55°' },
      { k: 'Inversionsbarriere ΔG‡', v: '45 kJ/mol' },
      { k: 'Twist-Boat', v: '+23 kJ/mol' },
      { k: 'Wanne', v: '+27 kJ/mol' },
      { k: 'Inversionsrate (25 °C)', v: '~10⁵ s⁻¹' },
      { k: 'A-Wert CH₃', v: '7,3 kJ/mol (95:5)' },
    ],
    exam: [
      'Baeyer- gegen Pitzer-Spannung abgrenzen: Warum ist der planare Ring wirklich ungünstig?',
      'Aus dem A-Wert die Gleichgewichtslage berechnen (ΔG° = −RT ln K).',
      'Beide Sesselkonformere von cis- und trans-1,2-Dimethylcyclohexan zeichnen und die stabilere bestimmen.',
      'Warum verlangt die E2-Eliminierung am Cyclohexan eine trans-diaxiale Anordnung?',
    ],
  },
}
