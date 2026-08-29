import * as THREE from 'three'
import { atom, bond, CPK, glass, label, std, V } from '../../three/lib'

/**
 * Natriumchlorid-Struktur: zwei ineinandergestellte fcc-Untergitter,
 * Koordinationszahl 6:6, oktaedrische Koordination.
 * Maßstab: 1 Einheit = 100 pm.
 */
export default {
  id: 'ionengitter',
  name: 'Ionengitter NaCl',
  discipline: 'chemie',
  level: 'Bachelor',
  tagline: 'Koordinationszahl, Radienquotient und Gitterenergie',
  scale: '1 Einheit = 100 pm',

  build() {
    const group = new THREE.Group()
    const ionen = new THREE.Group()
    const kontakte = new THREE.Group()
    const oktaeder = new THREE.Group()
    const zelle = new THREE.Group()

    const d = 2.82 // Na–Cl-Abstand = a/2 = 282 pm
    const rNa = 1.02 // Ionenradius Na⁺ = 102 pm
    const rCl = 1.81 // Ionenradius Cl⁻ = 181 pm

    const natrium = []
    const chlorid = []
    const n = 2 // 2×2×2 Elementarzellen-Ausschnitt (5×5×5 Ionen)

    for (let i = 0; i <= n * 2; i++) {
      for (let j = 0; j <= n * 2; j++) {
        for (let k = 0; k <= n * 2; k++) {
          const pos = V((i - n) * d, (j - n) * d, (k - n) * d)
          const istNatrium = (i + j + k) % 2 === 1
          const m = atom(
            pos,
            istNatrium ? rNa * 0.62 : rCl * 0.62,
            istNatrium ? CPK.Na : CPK.Cl,
            { material: std(istNatrium ? CPK.Na : CPK.Cl, { roughness: 0.3, metalness: 0.15 }) },
          )
          m.userData.typ = istNatrium ? 'Na' : 'Cl'
          ionen.add(m)
          ;(istNatrium ? natrium : chlorid).push({ pos, mesh: m })
        }
      }
    }

    // Kontaktlinien nur zwischen nächsten Nachbarn (Na⁺–Cl⁻)
    natrium.forEach((na) => {
      chlorid.forEach((cl) => {
        if (Math.abs(na.pos.distanceTo(cl.pos) - d) < 0.01) {
          kontakte.add(bond(na.pos, cl.pos, { radius: 0.035, color: 0x868e96 }))
        }
      })
    })

    // Koordinationsoktaeder um ein zentrales Na⁺
    const zentrum = V(d, 0, 0)
    const oktaederEcken = [
      V(d + d, 0, 0), V(d - d, 0, 0), V(d, d, 0), V(d, -d, 0), V(d, 0, d), V(d, 0, -d),
    ]
    const oktGeo = new THREE.OctahedronGeometry(d, 0)
    const okt = new THREE.Mesh(oktGeo, glass(0xff922b, 0.24))
    okt.position.copy(zentrum)
    oktaeder.add(okt)
    oktaederEcken.forEach((e) => oktaeder.add(bond(zentrum, e, { radius: 0.05, color: 0xff922b })))
    oktaeder.add(label('oktaedrische Koordination: KZ 6', [d, d + 1.4, 0], 'warm'))

    // Elementarzellen-Kanten
    const kanten = [
      [[-d, -d, -d], [d, -d, -d]], [[d, -d, -d], [d, -d, d]], [[d, -d, d], [-d, -d, d]], [[-d, -d, d], [-d, -d, -d]],
      [[-d, d, -d], [d, d, -d]], [[d, d, -d], [d, d, d]], [[d, d, d], [-d, d, d]], [[-d, d, d], [-d, d, -d]],
      [[-d, -d, -d], [-d, d, -d]], [[d, -d, -d], [d, d, -d]], [[d, -d, d], [d, d, d]], [[-d, -d, d], [-d, d, d]],
    ]
    kanten.forEach(([a, b]) => zelle.add(bond(a, b, { radius: 0.045, color: 0xffd43b })))
    zelle.add(label('Elementarzelle a = 564 pm · Z = 4 Formeleinheiten', [0, d + 1.4, 0], 'accent'))

    const text = new THREE.Group()
    text.add(
      label('Na⁺ r = 102 pm', [-d * 2.4, -d * 2.2, 0], 'accent2'),
      label('Cl⁻ r = 181 pm', [d * 2.4, -d * 2.2, 0], 'green'),
      label('Radienquotient r₊/r₋ = 0,564 → Oktaederlücke (0,414–0,732)', [0, -d * 2.9, 0], 'muted'),
      label('Gitterenergie ΔH_G = −787 kJ/mol', [0, -d * 3.5, 0], 'muted'),
    )

    group.add(ionen, kontakte, oktaeder, zelle, text)

    return {
      group,
      camera: { position: [10, 9, 20], target: [0, 0, 0] },
      layers: [
        { id: 'ionen', name: 'Ionen', objects: [ionen] },
        { id: 'kontakte', name: 'Nächste-Nachbar-Kontakte', objects: [kontakte] },
        { id: 'oktaeder', name: 'Koordinationsoktaeder', objects: [oktaeder] },
        { id: 'zelle', name: 'Elementarzelle', objects: [zelle] },
        { id: 'text', name: 'Beschriftungen', objects: [text] },
      ],
      update(t) {
        group.rotation.y = t * 0.18
        // Gitterschwingung (Phonon): Ionen schwingen gegenphasig – Grundlage der Reststrahlbande.
        const amp = 0.05
        natrium.forEach(({ mesh, pos }) => {
          mesh.position.set(pos.x + Math.sin(t * 3) * amp, pos.y, pos.z)
        })
        chlorid.forEach(({ mesh, pos }) => {
          mesh.position.set(pos.x - Math.sin(t * 3) * amp * 0.55, pos.y, pos.z)
        })
        okt.material.opacity = 0.18 + 0.1 * Math.sin(t * 1.5)
      },
    }
  },

  info: {
    summary:
      'Die NaCl-Struktur ist der Prototyp des Ionenkristalls: zwei kubisch-flächenzentrierte Untergitter, um a/2 gegeneinander verschoben. Jedes Ion ist oktaedrisch von sechs Gegenionen umgeben. Der Kristall ist ein einziges Riesenmolekül – "NaCl-Moleküle" existieren nur in der Gasphase.',
    sections: [
      {
        title: 'Struktur und Abzählung',
        body: [
          'Cl⁻ bildet ein fcc-Gitter, Na⁺ besetzt alle Oktaederlücken (bzw. umgekehrt – die Struktur ist symmetrisch).',
          'Pro Elementarzelle: Cl⁻ = 8×1/8 + 6×1/2 = 4; Na⁺ = 12×1/4 + 1 = 4. Also Z = 4 Formeleinheiten NaCl.',
          'Der Na–Cl-Abstand ist a/2 = 282 pm, gleich der Summe der Ionenradien (102 + 181 = 283 pm) – eine schöne Bestätigung des Konzepts additiver Ionenradien nach Shannon.',
          'Dichteberechnung: ρ = Z·M/(N_A·a³) = 4·58,44/(6,022·10²³·(5,64·10⁻⁸ cm)³) ≈ 2,16 g/cm³ – exakt der Messwert.',
        ],
      },
      {
        title: 'Radienquotientenregel',
        body: [
          'Der Quotient r₊/r₋ bestimmt, welche Lücke ein Kation gerade noch stabil besetzen kann, ohne dass sich die Anionen berühren.',
          '0,225–0,414 → Tetraederlücke, KZ 4 (Zinkblende-Typ, z. B. ZnS); 0,414–0,732 → Oktaederlücke, KZ 6 (NaCl-Typ); 0,732–1,0 → Würfellücke, KZ 8 (CsCl-Typ).',
          'Für NaCl: 102/181 = 0,564 → KZ 6, korrekt vorhergesagt. Für CsCl: 167/181 = 0,92 → KZ 8, ebenfalls korrekt.',
          'Die Regel versagt jedoch häufig (etwa bei LiI), weil sie starre Kugeln und rein ionische Bindung annimmt – Polarisierbarkeit und kovalente Anteile werden ignoriert.',
        ],
      },
      {
        title: 'Gitterenergie',
        body: [
          'Born-Landé-Gleichung: E_G = −(N_A·M·z₊·z₋·e²)/(4πε₀·r₀)·(1 − 1/n), mit der Madelung-Konstante M und dem Born-Exponenten n (Abstoßungsterm).',
          'Die Madelung-Konstante folgt aus der unendlichen Summe der Coulomb-Beiträge aller Nachbarschalen: für den NaCl-Typ M = 1,74756, für CsCl 1,76267, für Zinkblende 1,63806.',
          'Experimentell zugänglich ist die Gitterenergie nicht direkt, sondern über den Born-Haber-Kreisprozess: Sublimation + Ionisierung + Dissoziation + Elektronenaffinität + Gitterenergie = Bildungsenthalpie.',
          'Für NaCl: ΔH_G = −787 kJ/mol. Diese hohe Energie erklärt Schmelzpunkt (801 °C), Härte und Sprödigkeit – bei Verschiebung um eine halbe Gitterkonstante stehen gleichnamige Ionen gegenüber, der Kristall spaltet entlang der {100}-Ebenen.',
        ],
      },
      {
        title: 'Eigenschaften und Anwendung',
        body: [
          'Elektrische Leitfähigkeit erst in Schmelze oder Lösung, da erst dann die Ionen beweglich sind. Im Festkörper liegt nur geringe Ionenleitung über Schottky-Defekte vor.',
          'Die hohe Löslichkeit in Wasser (358 g/L) trotz hoher Gitterenergie ergibt sich aus der fast gleich großen Hydratationsenthalpie (Na⁺ −406, Cl⁻ −363 kJ/mol, Summe −769 kJ/mol). Der Lösungsvorgang ist mit ΔH = +3,9 kJ/mol schwach endotherm und wird durch den Entropiegewinn getrieben.',
          'Reststrahlbande: Die gegenphasige Schwingung der Untergitter (im Modell animiert) ist IR-aktiv und liegt bei NaCl bei 61 µm – genutzt zur Charakterisierung optischer Kristalle.',
        ],
      },
    ],
    facts: [
      { k: 'Gitterkonstante a', v: '564,0 pm' },
      { k: 'Na–Cl-Abstand', v: '282,0 pm' },
      { k: 'Koordination', v: '6:6 (oktaedrisch)' },
      { k: 'Formeleinheiten Z', v: '4' },
      { k: 'Madelung-Konstante', v: '1,74756' },
      { k: 'Gitterenergie', v: '−787 kJ/mol' },
      { k: 'Schmelzpunkt', v: '801 °C' },
      { k: 'Dichte', v: '2,16 g/cm³' },
    ],
    exam: [
      'Born-Haber-Kreisprozess für NaCl vollständig aufstellen und Gitterenergie berechnen.',
      'Dichte aus Gitterkonstante und Z herleiten.',
      'Radienquotient bestimmen und Koordinationszahl vorhersagen; Grenzen der Regel diskutieren.',
      'Warum ist NaCl spröde, Kupfer aber duktil?',
    ],
  },
}
