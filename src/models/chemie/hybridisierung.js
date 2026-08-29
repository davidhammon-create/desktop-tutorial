import * as THREE from 'three'
import { atom, bond, CPK, glass, label, lobe, multiBond, std, V } from '../../three/lib'

/**
 * Hybridisierung am Kohlenstoff: sp³ (Methan), sp² (Ethen), sp (Ethin).
 * Zeigt Geometrie, Bindungswinkel, Bindungslängen und σ/π-Trennung.
 * Maßstab: 1 Einheit = 1 Å.
 */
export default {
  id: 'hybridisierung',
  name: 'Hybridisierung sp³ / sp² / sp',
  discipline: 'chemie',
  level: 'Bachelor',
  tagline: 'Geometrie, Bindungsordnung und σ/π-Aufteilung',
  scale: '1 Einheit = 1 Å',

  build() {
    const group = new THREE.Group()
    const gSp3 = new THREE.Group()
    const gSp2 = new THREE.Group()
    const gSp = new THREE.Group()
    const gOrbitale = new THREE.Group()

    const cMat = std(CPK.C, { roughness: 0.35 })
    const hMat = std(CPK.H, { roughness: 0.3 })

    // ---------------------------------------------------------------- sp³ Methan
    gSp3.position.set(-7, 0, 0)
    const cH4 = V(0, 0, 0)
    gSp3.add(atom(cH4, 0.35, CPK.C, { material: cMat }))
    // Tetraeder-Ecken: (1,1,1), (1,−1,−1), (−1,1,−1), (−1,−1,1) normiert × 1,09 Å
    const tetraeder = [
      V(1, 1, 1), V(1, -1, -1), V(-1, 1, -1), V(-1, -1, 1),
    ].map((v) => v.normalize().multiplyScalar(1.09))
    const sp3Lappen = []
    tetraeder.forEach((h) => {
      gSp3.add(atom(h, 0.2, CPK.H, { material: hMat }))
      gSp3.add(bond(cH4, h, { radius: 0.08, color: 0xadb5bd }))
      const l = lobe(1.35, 0.34, 0x51cf66, { opacity: 0.32 })
      l.quaternion.setFromUnitVectors(V(0, 1, 0), h.clone().normalize())
      gOrbitale.add(l)
      l.userData.parent = 'sp3'
      sp3Lappen.push(l)
    })
    gSp3.add(
      label('sp³ – Methan CH₄', [0, 2.4, 0], 'green'),
      label('Tetraeder · 109,47° · 4 σ-Bindungen', [0, 1.85, 0], 'muted'),
      label('C–H 109 pm · 25 % s-Anteil', [0, -2.2, 0], 'muted'),
    )

    // ---------------------------------------------------------------- sp² Ethen
    gSp2.position.set(0, 0, 0)
    const c1 = V(-0.669, 0, 0) // C=C: 133,9 pm
    const c2 = V(0.669, 0, 0)
    gSp2.add(atom(c1, 0.35, CPK.C, { material: cMat }), atom(c2, 0.35, CPK.C, { material: cMat }))
    gSp2.add(multiBond(c1, c2, 2, { radius: 0.07, color: 0x868e96, gap: 0.17 }))
    // H-Positionen: 120° in der Molekülebene, C–H 108,7 pm
    const ethenH = []
    ;[[-1, 1], [-1, -1], [1, 1], [1, -1]].forEach(([sx, sz]) => {
      const c = sx < 0 ? c1 : c2
      const w = (120 * Math.PI) / 180
      const dir = V(sx * Math.cos(w / 2), 0, sz * Math.sin(w / 2)).normalize()
      const h = c.clone().addScaledVector(dir, 1.087)
      ethenH.push(h)
      gSp2.add(atom(h, 0.2, CPK.H, { material: hMat }))
      gSp2.add(bond(c, h, { radius: 0.08, color: 0xadb5bd }))
    })
    // π-Bindung: p_z-Lappen ober- und unterhalb der Ebene
    const piEthen = new THREE.Group()
    ;[c1, c2].forEach((c) => {
      const o = lobe(1.25, 0.4, 0x4dabf7, { opacity: 0.38 })
      o.position.copy(c)
      const u = lobe(1.25, 0.4, 0xff6b6b, { opacity: 0.38 })
      u.position.copy(c)
      u.rotation.x = Math.PI
      piEthen.add(o, u)
    })
    gSp2.add(piEthen)
    gSp2.add(
      label('sp² – Ethen C₂H₄', [0, 2.4, 0], 'accent'),
      label('trigonal-planar · 120° · 1 σ + 1 π', [0, 1.85, 0], 'muted'),
      label('C=C 133,9 pm · 33 % s-Anteil · Rotation blockiert', [0, -2.2, 0], 'muted'),
    )

    // ---------------------------------------------------------------- sp Ethin
    gSp.position.set(7, 0, 0)
    const a1 = V(-0.6, 0, 0) // C≡C: 120,3 pm
    const a2 = V(0.6, 0, 0)
    gSp.add(atom(a1, 0.35, CPK.C, { material: cMat }), atom(a2, 0.35, CPK.C, { material: cMat }))
    gSp.add(multiBond(a1, a2, 3, { radius: 0.055, color: 0x868e96, gap: 0.16 }))
    const h1 = V(-1.66, 0, 0) // C–H 106,0 pm
    const h2 = V(1.66, 0, 0)
    gSp.add(atom(h1, 0.2, CPK.H, { material: hMat }), atom(h2, 0.2, CPK.H, { material: hMat }))
    gSp.add(bond(a1, h1, { radius: 0.08, color: 0xadb5bd }), bond(a2, h2, { radius: 0.08, color: 0xadb5bd }))
    // Zwei zueinander senkrechte π-Systeme → rotationssymmetrische Elektronenhülle
    const piEthin = new THREE.Group()
    const zylinder = new THREE.Mesh(
      new THREE.CylinderGeometry(0.55, 0.55, 1.2, 32, 1, true),
      glass(0x9775fa, 0.3),
    )
    zylinder.rotation.z = Math.PI / 2
    piEthin.add(zylinder)
    ;[a1, a2].forEach((c) => {
      ;[[0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]].forEach((d) => {
        const l = lobe(1.0, 0.32, d[1] !== 0 ? 0x4dabf7 : 0x9775fa, { opacity: 0.3 })
        l.position.copy(c)
        l.quaternion.setFromUnitVectors(V(0, 1, 0), V(...d))
        piEthin.add(l)
      })
    })
    gSp.add(piEthin)
    gSp.add(
      label('sp – Ethin C₂H₂', [0, 2.4, 0], 'accent2'),
      label('linear · 180° · 1 σ + 2 π', [0, 1.85, 0], 'muted'),
      label('C≡C 120,3 pm · 50 % s-Anteil · pK_s = 25', [0, -2.2, 0], 'muted'),
    )

    const vergleich = new THREE.Group()
    vergleich.add(
      label('Mehr s-Anteil → kürzere, stärkere Bindung und höhere C–H-Acidität', [0, -3.6, 0], 'warm'),
    )

    group.add(gSp3, gSp2, gSp, gOrbitale, vergleich)
    gOrbitale.position.copy(gSp3.position)

    return {
      group,
      camera: { position: [0, 4, 16], target: [0, 0, 0] },
      layers: [
        { id: 'sp3', name: 'sp³ (Methan)', objects: [gSp3, gOrbitale] },
        { id: 'sp2', name: 'sp² (Ethen)', objects: [gSp2] },
        { id: 'sp', name: 'sp (Ethin)', objects: [gSp] },
        { id: 'orbitale', name: 'sp³-Hybridorbitale', objects: [gOrbitale], on: false },
        { id: 'pi', name: 'π-Bindungen', objects: [piEthen, piEthin] },
        { id: 'vergleich', name: 'Vergleichstext', objects: [vergleich] },
      ],
      update(t) {
        gSp3.rotation.y = t * 0.3
        gOrbitale.rotation.y = t * 0.3
        gSp2.rotation.y = Math.sin(t * 0.4) * 0.7
        gSp.rotation.y = Math.sin(t * 0.4 + 1) * 0.7
        piEthen.children.forEach((l, i) => {
          if (l.material) l.material.opacity = 0.26 + 0.14 * Math.sin(t * 1.8 + i)
        })
      },
    }
  },

  info: {
    summary:
      'Hybridisierung ist kein physikalischer Prozess, sondern ein mathematisches Werkzeug: Man bildet Linearkombinationen aus s- und p-Atomorbitalen, um die experimentell beobachtete Molekülgeometrie im VB-Modell zu beschreiben. Der s-Anteil des Hybridorbitals steuert direkt Bindungslänge, Bindungsstärke und Acidität.',
    sections: [
      {
        title: 'Konstruktion der Hybridorbitale',
        body: [
          'sp³: 1 s + 3 p → 4 äquivalente Orbitale mit je 25 % s-Charakter, tetraedrisch angeordnet (109,47°). Der exakte Winkel folgt aus arccos(−1/3).',
          'sp²: 1 s + 2 p → 3 Orbitale mit 33 % s-Charakter, trigonal-planar (120°). Ein p-Orbital bleibt unhybridisiert und bildet die π-Bindung.',
          'sp: 1 s + 1 p → 2 Orbitale mit 50 % s-Charakter, linear (180°). Zwei p-Orbitale bleiben übrig und bilden zwei zueinander senkrechte π-Bindungen.',
          'Wichtig: Die Zahl der Orbitale bleibt erhalten. Aus vier AOs werden vier Hybridorbitale – Hybridisierung erzeugt keine neuen Zustände.',
        ],
      },
      {
        title: 'Konsequenzen des s-Anteils',
        body: [
          's-Orbitale sind kernnäher als p-Orbitale. Mehr s-Anteil bedeutet daher: kürzere Bindung, höhere Bindungsenergie und größere Elektronegativität des Kohlenstoffs.',
          'Bindungslängen: C–C 154 pm (sp³) > C=C 134 pm (sp²) > C≡C 120 pm (sp).',
          'C–H-Acidität steigt mit dem s-Anteil, weil das freie Elektronenpaar des Carbanions in einem kernnäheren Orbital besser stabilisiert wird: Ethan pK_s ≈ 50, Ethen ≈ 44, Ethin ≈ 25. Deshalb lässt sich Ethin mit NaNH₂ deprotonieren – Grundlage der Alkinylierung.',
        ],
      },
      {
        title: 'σ- und π-Bindungen',
        body: [
          'σ-Bindungen entstehen durch frontale Überlappung entlang der Kernverbindungsachse; sie sind rotationssymmetrisch, daher ist freie Drehung möglich.',
          'π-Bindungen entstehen durch seitliche p-Orbital-Überlappung. Sie besitzen eine Knotenebene, die die Kernachse enthält. Rotation würde die Überlappung zerstören – daher die Rotationsbarriere von ~270 kJ/mol bei Ethen und die daraus folgende E/Z-Isomerie.',
          'Eine Doppelbindung ist nicht doppelt so stark wie eine Einfachbindung: C–C 348 kJ/mol, C=C 614 kJ/mol. Die π-Bindung trägt also nur ~266 kJ/mol bei und ist damit die schwächere und reaktivere Komponente – deshalb greifen Elektrophile an der π-Bindung an.',
        ],
      },
      {
        title: 'Abgrenzung zum VSEPR- und MO-Modell',
        body: [
          'VSEPR sagt Geometrien allein aus der Abstoßung von Elektronenpaaren voraus und braucht keine Hybridisierung – oft schneller und für Hauptgruppenelemente zuverlässiger.',
          'Die MO-Theorie kommt vollständig ohne Hybridisierung aus und erklärt Phänomene, an denen das VB-Modell scheitert (Paramagnetismus von O₂, Photoelektronenspektren von Methan mit zwei getrennten Signalen statt einem).',
          'Für d-Block-Elemente ist das Konzept der sp³d/sp³d²-Hybridisierung heute überholt: Die d-Orbitale sind energetisch zu hoch; hypervalente Bindungen werden über 3-Zentren-4-Elektronen-Bindungen beschrieben.',
        ],
      },
    ],
    facts: [
      { k: 'sp³: Winkel / s-Anteil', v: '109,47° / 25 %' },
      { k: 'sp²: Winkel / s-Anteil', v: '120° / 33 %' },
      { k: 'sp: Winkel / s-Anteil', v: '180° / 50 %' },
      { k: 'C–C / C=C / C≡C', v: '154 / 133,9 / 120,3 pm' },
      { k: 'Bindungsenergien', v: '348 / 614 / 839 kJ/mol' },
      { k: 'Rotationsbarriere C=C', v: '≈ 270 kJ/mol' },
      { k: 'pK_s Ethan/Ethen/Ethin', v: '≈ 50 / 44 / 25' },
      { k: 'Rotationsbarriere Ethan', v: '12,5 kJ/mol' },
    ],
    exam: [
      'Tetraederwinkel 109,47° aus arccos(−1/3) herleiten.',
      'Warum steigt die C–H-Acidität mit dem s-Anteil?',
      'Warum ist eine π-Bindung schwächer als eine σ-Bindung?',
      'Hybridisierung in Allen (H₂C=C=CH₂) bestimmen – warum stehen die CH₂-Ebenen senkrecht zueinander?',
    ],
  },
}
