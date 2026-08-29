import * as THREE from 'three'
import { arrow, atom, bond, glass, glow, label, ring, std, tube, V } from '../../three/lib'

/**
 * Herz: vier Kammern, Klappenebene, Erregungsleitungssystem und Blutfluss.
 * Maßstab: 1 Einheit ≈ 1 cm.
 */
export default {
  id: 'herz',
  name: 'Herz – Anatomie & Erregungsleitung',
  discipline: 'medizin',
  level: 'Bachelor / Physikum',
  tagline: 'Kammern, Klappen, Reizleitung und Herzzyklus',
  scale: '1 Einheit ≈ 1 cm',

  build() {
    const group = new THREE.Group()
    const kammern = new THREE.Group()
    const klappen = new THREE.Group()
    const gefaesse = new THREE.Group()
    const leitung = new THREE.Group()
    const blut = new THREE.Group()
    const koronarien = new THREE.Group()
    const beschriftung = new THREE.Group()

    const venoes = 0x4263eb // sauerstoffarm
    const arteriell = 0xe03131 // sauerstoffreich

    // --- Vorhöfe -----------------------------------------------------------------
    const raMesh = new THREE.Mesh(new THREE.SphereGeometry(2.6, 32, 24), glass(venoes, 0.32))
    raMesh.position.set(-3.0, 4.2, 0)
    raMesh.scale.set(1, 0.85, 0.9)
    const laMesh = new THREE.Mesh(new THREE.SphereGeometry(2.4, 32, 24), glass(arteriell, 0.32))
    laMesh.position.set(3.0, 4.4, -0.5)
    laMesh.scale.set(1, 0.85, 0.9)
    kammern.add(raMesh, laMesh)

    // --- Ventrikel ----------------------------------------------------------------
    // Linker Ventrikel: Wanddicke 10–12 mm, rechter nur 3–5 mm
    const lvAussen = new THREE.Mesh(new THREE.SphereGeometry(4.0, 40, 32), std(arteriell, { roughness: 0.55, transparent: true, opacity: 0.32 }))
    lvAussen.position.set(2.0, -1.6, 0)
    lvAussen.scale.set(1, 1.35, 1)
    const lvInnen = new THREE.Mesh(new THREE.SphereGeometry(2.7, 32, 24), glass(0xffa8a8, 0.25))
    lvInnen.position.copy(lvAussen.position)
    lvInnen.scale.set(1, 1.35, 1)

    const rvAussen = new THREE.Mesh(new THREE.SphereGeometry(3.5, 40, 32), std(venoes, { roughness: 0.55, transparent: true, opacity: 0.3 }))
    rvAussen.position.set(-2.8, -1.4, 0.4)
    rvAussen.scale.set(0.95, 1.3, 0.95)
    const rvInnen = new THREE.Mesh(new THREE.SphereGeometry(2.8, 32, 24), glass(0x91a7ff, 0.25))
    rvInnen.position.copy(rvAussen.position)
    rvInnen.scale.set(0.95, 1.3, 0.95)
    kammern.add(lvAussen, lvInnen, rvAussen, rvInnen)

    // Septum interventriculare
    const septum = new THREE.Mesh(new THREE.BoxGeometry(0.5, 7.5, 5.0), std(0xc92a2a, { roughness: 0.6 }))
    septum.position.set(-0.4, -1.5, 0)
    kammern.add(septum)

    // --- Herzklappen ---------------------------------------------------------------
    const klappe = (pos, radius, farbe, name) => {
      const g = new THREE.Group()
      const r = ring(radius, 0.12, farbe)
      r.rotation.x = Math.PI / 2
      g.add(r)
      // Segel / Taschen
      for (let i = 0; i < 3; i++) {
        const a = (i / 3) * Math.PI * 2
        const segel = new THREE.Mesh(
          new THREE.CircleGeometry(radius * 0.72, 16, 0, Math.PI),
          std(farbe, { side: THREE.DoubleSide, roughness: 0.4, transparent: true, opacity: 0.85 }),
        )
        segel.position.set(Math.cos(a) * radius * 0.42, 0, Math.sin(a) * radius * 0.42)
        segel.rotation.x = -Math.PI / 2
        segel.rotation.z = a
        segel.userData.basis = a
        g.add(segel)
      }
      g.position.set(...pos)
      g.userData.name = name
      return g
    }

    const trikuspidal = klappe([-2.8, 1.9, 0.2], 1.5, 0x74c0fc, 'Trikuspidalklappe')
    const mitral = klappe([2.6, 2.0, -0.2], 1.3, 0xffa8a8, 'Mitralklappe')
    const pulmonal = klappe([-2.2, 5.2, 1.6], 1.0, 0x4dabf7, 'Pulmonalklappe')
    const aorten = klappe([1.4, 5.4, 0.4], 1.1, 0xff8787, 'Aortenklappe')
    klappen.add(trikuspidal, mitral, pulmonal, aorten)
    const alleKlappen = [trikuspidal, mitral, pulmonal, aorten]

    // --- Große Gefäße ---------------------------------------------------------------
    const aorta = tube(
      [V(1.4, 5.4, 0.4), V(1.6, 8.5, 0.2), V(0.5, 11.0, -0.8), V(-2.5, 11.5, -1.5), V(-3.5, 8.0, -2.0)],
      1.0,
      std(arteriell, { roughness: 0.5 }),
    )
    const truncus = tube(
      [V(-2.2, 5.2, 1.6), V(-2.6, 8.0, 1.8), V(-4.5, 9.5, 1.0)],
      0.85,
      std(venoes, { roughness: 0.5 }),
    )
    const vcs = tube([V(-3.2, 6.6, -0.5), V(-3.4, 10.5, -1.0)], 0.75, std(venoes, { roughness: 0.5 }))
    const vci = tube([V(-3.2, 2.2, -1.5), V(-3.4, -2.0, -2.5)], 0.75, std(venoes, { roughness: 0.5 }))
    gefaesse.add(aorta, truncus, vcs, vci)

    // --- Koronararterien ------------------------------------------------------------
    const lad = tube(
      [V(1.0, 5.0, 1.0), V(0.2, 2.5, 2.8), V(-0.2, -1.0, 3.2), V(-0.4, -4.5, 2.2)],
      0.22,
      std(0xfa5252, { roughness: 0.4 }),
    )
    const rca = tube(
      [V(1.2, 5.0, 0.2), V(-2.0, 3.5, 2.2), V(-4.5, 0.5, 1.5), V(-3.5, -3.5, 0.8)],
      0.22,
      std(0xfa5252, { roughness: 0.4 }),
    )
    const rcx = tube(
      [V(1.6, 5.0, 0.0), V(4.0, 3.0, -1.5), V(5.0, -0.5, -2.0)],
      0.2,
      std(0xfa5252, { roughness: 0.4 }),
    )
    koronarien.add(lad, rca, rcx)

    // --- Erregungsleitungssystem ----------------------------------------------------
    const sinusknoten = atom([-4.4, 5.6, -0.6], 0.42, 0xffd43b, { material: glow(0xffd43b, 1) })
    const avKnoten = atom([-0.6, 2.4, 0], 0.36, 0xffd43b, { material: glow(0xffd43b, 1) })
    leitung.add(sinusknoten, avKnoten)

    const hisBuendel = tube([V(-0.6, 2.4, 0), V(-0.5, 0.8, 0)], 0.14, glow(0xffd43b, 0.6))
    const tawaraLinks = tube([V(-0.5, 0.8, 0), V(1.5, -2.0, 1.0), V(3.0, -5.0, 0.5)], 0.11, glow(0xffd43b, 0.6))
    const tawaraRechts = tube([V(-0.5, 0.8, 0), V(-2.0, -2.0, 1.2), V(-3.5, -5.0, 0.6)], 0.11, glow(0xffd43b, 0.6))
    leitung.add(hisBuendel, tawaraLinks, tawaraRechts)

    // Purkinje-Fasern
    const purkinje = []
    for (let i = 0; i < 14; i++) {
      const links = i % 2 === 0
      const basis = links ? V(3.0, -5.0, 0.5) : V(-3.5, -5.0, 0.6)
      const a = (i / 14) * Math.PI * 2
      const ende = basis.clone().add(V(Math.cos(a) * 1.8, -1.2 - Math.random() * 0.8, Math.sin(a) * 1.6))
      const f = bond(basis, ende, { radius: 0.06, material: glow(0xffd43b, 0.5) })
      leitung.add(f)
      purkinje.push(f)
    }

    // --- Blutfluss als bewegte Partikel ---------------------------------------------
    const bahnRechts = [
      V(-3.4, 9.0, -1.0), V(-3.2, 6.0, -0.5), V(-3.0, 4.2, 0), V(-2.8, 1.9, 0.2),
      V(-2.8, -2.5, 0.4), V(-2.4, 3.0, 1.2), V(-2.2, 5.2, 1.6), V(-4.0, 9.0, 1.4),
    ]
    const bahnLinks = [
      V(5.5, 6.5, -1.5), V(3.0, 4.4, -0.5), V(2.6, 2.0, -0.2), V(2.0, -3.0, 0),
      V(1.8, 3.0, 0.6), V(1.4, 5.4, 0.4), V(1.0, 9.5, -0.5), V(-3.0, 11.4, -1.6),
    ]

    const partikel = []
    for (let i = 0; i < 26; i++) {
      const rechtsHerz = i % 2 === 0
      const p = atom([0, 0, 0], 0.22, rechtsHerz ? venoes : arteriell, {
        material: glow(rechtsHerz ? venoes : arteriell, 0.6),
        segments: 10,
      })
      p.userData = { bahn: rechtsHerz ? bahnRechts : bahnLinks, offset: (i / 26) % 1 }
      blut.add(p)
      partikel.push(p)
    }

    // --- Beschriftungen ---------------------------------------------------------------
    const marken = [
      ['Rechter Vorhof', [-6.2, 5.4, 0], 'cold'],
      ['Linker Vorhof', [6.2, 5.6, 0], 'hot'],
      ['Rechter Ventrikel – Wand 3–5 mm', [-7.5, -2.5, 0], 'cold'],
      ['Linker Ventrikel – Wand 10–12 mm', [7.5, -2.5, 0], 'hot'],
      ['Sinusknoten – 60–100/min', [-7.5, 7.2, 0], 'warm'],
      ['AV-Knoten – Verzögerung ~100 ms', [-4.5, 1.4, 2.5], 'warm'],
      ['His-Bündel & Tawara-Schenkel', [4.5, -0.5, 3.0], 'warm'],
      ['Purkinje-Fasern – 2–4 m/s', [0, -8.5, 2.0], 'warm'],
      ['Aorta', [-4.5, 12.0, -2.0], 'hot'],
      ['Truncus pulmonalis', [-6.5, 10.0, 1.0], 'cold'],
      ['V. cava superior', [-4.5, 11.0, -1.0], 'cold'],
      ['RIVA / LAD', [-1.5, -6.0, 3.0], 'hot'],
      ['Septum interventriculare', [-0.4, -7.5, 0], 'muted'],
    ]
    marken.forEach(([text, pos, tone]) => beschriftung.add(label(text, pos, tone)))

    const zyklus = new THREE.Group()
    zyklus.add(
      label('HZV = HF × SV = 70/min × 70 ml ≈ 5 l/min   ·   EF = SV/EDV = 55–70 %', [0, -11, 0], 'muted'),
    )

    group.add(kammern, klappen, gefaesse, leitung, koronarien, blut, beschriftung, zyklus)

    return {
      group,
      camera: { position: [2, 3, 34], target: [0, 1, 0] },
      layers: [
        { id: 'kammern', name: 'Herzkammern', objects: [kammern] },
        { id: 'klappen', name: 'Herzklappen', objects: [klappen] },
        { id: 'gefaesse', name: 'Große Gefäße', objects: [gefaesse] },
        { id: 'koronarien', name: 'Koronararterien', objects: [koronarien] },
        { id: 'leitung', name: 'Erregungsleitung', objects: [leitung] },
        { id: 'blut', name: 'Blutfluss', objects: [blut] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung] },
      ],
      update(t) {
        // Herzzyklus: 1 Umlauf ≈ 0,8 s bei 75/min. Hier verlangsamt dargestellt.
        const zyklusdauer = 2.4
        const phase = (t % zyklusdauer) / zyklusdauer // 0 = Beginn Systole

        // Systole ca. 1/3, Diastole ca. 2/3 des Zyklus
        const systole = phase < 0.35
        const kontraktion = systole ? Math.sin((phase / 0.35) * Math.PI) : 0

        // Ventrikel kontrahieren, Vorhöfe kontrahieren kurz davor (Vorhofpfropfung)
        const vSkala = 1 - kontraktion * 0.16
        lvAussen.scale.set(vSkala, 1.35 * vSkala, vSkala)
        lvInnen.scale.set(vSkala * 0.85, 1.35 * vSkala * 0.85, vSkala * 0.85)
        rvAussen.scale.set(0.95 * vSkala, 1.3 * vSkala, 0.95 * vSkala)
        rvInnen.scale.set(0.95 * vSkala * 0.9, 1.3 * vSkala * 0.9, 0.95 * vSkala * 0.9)

        const vorhof = phase > 0.85 ? Math.sin(((phase - 0.85) / 0.15) * Math.PI) : 0
        const aSkala = 1 - vorhof * 0.14
        raMesh.scale.set(aSkala, 0.85 * aSkala, 0.9 * aSkala)
        laMesh.scale.set(aSkala, 0.85 * aSkala, 0.9 * aSkala)

        // Klappen: AV-Klappen in der Systole zu, Taschenklappen offen
        const avOffen = !systole ? 1 : 0
        const taschenOffen = systole ? 1 : 0
        ;[trikuspidal, mitral].forEach((k) => {
          k.children.forEach((c) => {
            if (c.userData.basis !== undefined) c.rotation.x = -Math.PI / 2 + avOffen * 0.9
          })
        })
        ;[pulmonal, aorten].forEach((k) => {
          k.children.forEach((c) => {
            if (c.userData.basis !== undefined) c.rotation.x = -Math.PI / 2 + taschenOffen * 0.9
          })
        })

        // Erregungsausbreitung: Sinus → AV (mit Verzögerung) → His → Purkinje
        const erregung = (verzoegerung) => {
          const p = (phase - verzoegerung + 1) % 1
          return p < 0.12 ? 1 - p / 0.12 : 0
        }
        sinusknoten.material.emissiveIntensity = 0.4 + erregung(0.86) * 1.6
        avKnoten.material.emissiveIntensity = 0.4 + erregung(0.94) * 1.6
        hisBuendel.material.emissiveIntensity = 0.3 + erregung(0.99) * 1.4
        tawaraLinks.material.emissiveIntensity = 0.3 + erregung(0.01) * 1.4
        tawaraRechts.material.emissiveIntensity = 0.3 + erregung(0.01) * 1.4
        purkinje.forEach((f) => {
          f.material.emissiveIntensity = 0.25 + erregung(0.03) * 1.3
        })

        // Blutpartikel laufen ihre Bahn ab, in der Systole schneller
        const tempo = systole ? 0.32 : 0.12
        partikel.forEach((p) => {
          p.userData.offset = (p.userData.offset + tempo * 0.016) % 1
          const bahn = p.userData.bahn
          const f = p.userData.offset * (bahn.length - 1)
          const idx = Math.min(bahn.length - 2, Math.floor(f))
          p.position.lerpVectors(bahn[idx], bahn[idx + 1], f - idx)
        })
      },
    }
  },

  info: {
    summary:
      'Das Herz ist eine Doppelpumpe: Der rechte Ventrikel fördert gegen den Niederdruck des Lungenkreislaufs (25/10 mmHg), der linke gegen den Hochdruck des Körperkreislaufs (120/80 mmHg). Beide fördern pro Schlag exakt dasselbe Volumen – daraus erklärt sich die unterschiedliche Wanddicke bei identischem Schlagvolumen.',
    sections: [
      {
        title: 'Erregungsbildung und -leitung',
        body: [
          'Der Sinusknoten (Nodus sinuatrialis) im rechten Vorhof ist der primäre Schrittmacher mit 60–100 Impulsen/min. Seine Zellen besitzen kein stabiles Ruhepotential, sondern eine langsame diastolische Depolarisation über den Funny-Strom I_f (HCN-Kanäle) – Angriffspunkt von Ivabradin.',
          'Der AV-Knoten ist die einzige elektrische Verbindung zwischen Vorhöfen und Kammern (das Herzskelett isoliert sonst vollständig). Seine Leitungsverzögerung von etwa 100 ms erlaubt die vollständige Vorhofkontraktion vor der Kammersystole – sie entspricht der PQ-Zeit im EKG (120–200 ms).',
          'Sekundäre Schrittmacher: AV-Knoten 40–60/min, Tawara-Schenkel und Purkinje-Fasern 20–40/min. Diese hierarchische Absicherung verhindert Asystolie bei Ausfall übergeordneter Zentren.',
          'Leitungsgeschwindigkeiten: Vorhofmyokard 1 m/s, AV-Knoten nur 0,05 m/s (Verzögerungsstelle), His-Purkinje-System 2–4 m/s, Arbeitsmyokard 1 m/s. Die schnelle Purkinje-Leitung sorgt für nahezu simultane Kontraktion beider Ventrikel.',
        ],
      },
      {
        title: 'Herzzyklus',
        body: [
          'Vier Phasen: Anspannungsphase (isovolumetrische Kontraktion, alle Klappen zu), Austreibungsphase, Entspannungsphase (isovolumetrische Relaxation), Füllungsphase.',
          'Die AV-Klappen (Trikuspidal- und Mitralklappe) schließen zu Beginn der Systole – das erzeugt den 1. Herzton. Die Taschenklappen (Pulmonal- und Aortenklappe) schließen am Ende der Systole – der 2. Herzton.',
          'Kennzahlen: EDV ≈ 120 ml, ESV ≈ 50 ml, SV ≈ 70 ml, EF = SV/EDV = 55–70 %. HZV = HF × SV ≈ 5 l/min in Ruhe, unter maximaler Belastung bis 25 l/min.',
          'Etwa 80 % der Ventrikelfüllung erfolgen passiv; die Vorhofkontraktion trägt nur die restlichen 20 % bei. Deshalb wird Vorhofflimmern in Ruhe oft gut toleriert, unter Belastung aber nicht.',
        ],
      },
      {
        title: 'Koronarperfusion',
        body: [
          'Besonderheit: Der linke Ventrikel wird fast ausschließlich in der Diastole durchblutet, weil die intramurale Wandspannung während der Systole die Gefäße komprimiert. Tachykardie verkürzt vor allem die Diastole – deshalb tritt Angina pectoris unter Belastung auf.',
          'Versorgungsgebiete: RIVA/LAD → Vorderwand und Septum; RCX → Lateralwand; RCA → Hinterwand, rechter Ventrikel und bei ~90 % der Menschen auch der AV-Knoten. Ein RCA-Verschluss geht daher häufig mit Bradykardie und AV-Block einher.',
          'Die myokardiale O₂-Ausschöpfung beträgt bereits in Ruhe 70–80 % (gegenüber 25 % im Körperkreislauf). Mehrbedarf kann fast nur über gesteigerte Durchblutung gedeckt werden – die Koronarreserve ist der limitierende Faktor.',
        ],
      },
      {
        title: 'Klinische Bezüge',
        body: [
          'Der Frank-Starling-Mechanismus koppelt Schlagvolumen an die Vordehnung: eine erhöhte Vorlast steigert die Kontraktionskraft. Damit gleichen beide Ventrikel ihre Fördervolumina automatisch an.',
          'STEMI-Lokalisation im EKG: V1–V4 → Vorderwand (LAD), II/III/aVF → Hinterwand (RCA), I/aVL/V5–V6 → Lateralwand (RCX).',
          'Klappenvitien: Aortenstenose führt zur konzentrischen Hypertrophie (Drucklast), Mitralinsuffizienz zur exzentrischen Dilatation (Volumenlast). Die klassische Trias der Aortenstenose lautet Angina, Synkope, Dyspnoe.',
          'Herzinsuffizienz wird nach EF eingeteilt: HFrEF (≤ 40 %), HFmrEF (41–49 %), HFpEF (≥ 50 %) – mit unterschiedlichen Therapiekonzepten.',
        ],
      },
    ],
    facts: [
      { k: 'Schlagvolumen', v: '~70 ml' },
      { k: 'Herzzeitvolumen (Ruhe)', v: '~5 l/min' },
      { k: 'Ejektionsfraktion', v: '55–70 %' },
      { k: 'Wanddicke LV / RV', v: '10–12 mm / 3–5 mm' },
      { k: 'Sinusknoten-Frequenz', v: '60–100/min' },
      { k: 'AV-Verzögerung', v: '~100 ms (PQ 120–200 ms)' },
      { k: 'Purkinje-Leitung', v: '2–4 m/s' },
      { k: 'Koronardurchblutung', v: '250 ml/min (5 % HZV)' },
    ],
    exam: [
      'Herzzyklus in vier Phasen mit Klappenstellungen und Drücken beschreiben.',
      'Warum wird der linke Ventrikel nur diastolisch perfundiert?',
      'Frank-Starling-Mechanismus erklären und im Druck-Volumen-Diagramm einzeichnen.',
      'EKG-Ableitungen den Koronararterien zuordnen (STEMI-Lokalisation).',
      'Warum ist die AV-Knoten-Verzögerung funktionell notwendig?',
    ],
  },
}
