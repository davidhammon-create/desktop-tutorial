import * as THREE from 'three'
import { arrow, atom, bond, glass, glow, label, rng, std, tube, V } from '../../three/lib'

/**
 * Alveole und Blut-Luft-Schranke: Gasaustausch nach dem Fick'schen Gesetz,
 * Kapillarnetz, Erythrozytenpassage und Surfactant.
 * Maßstab: 1 Einheit ≈ 10 µm.
 */
export default {
  id: 'alveole',
  name: 'Alveole & Gasaustausch',
  discipline: 'medizin',
  level: 'Bachelor / Physikum',
  tagline: 'Blut-Luft-Schranke, Diffusion und Surfactant',
  scale: '1 Einheit ≈ 10 µm',

  build() {
    const group = new THREE.Group()
    const alveolen = new THREE.Group()
    const kapillaren = new THREE.Group()
    const erythrozyten = new THREE.Group()
    const gase = new THREE.Group()
    const surfactant = new THREE.Group()
    const beschriftung = new THREE.Group()
    const zufall = rng(101)

    // --- Alveolarsack mit mehreren Alveolen --------------------------------------
    const alveolePositionen = [
      { p: V(0, 3, 0), r: 6.5 },
      { p: V(-9, 6, -3), r: 4.5 },
      { p: V(9, 5.5, -2), r: 4.8 },
      { p: V(-6, -3, -4), r: 4.0 },
      { p: V(7, -3.5, -3), r: 4.2 },
    ]

    alveolePositionen.forEach((a, i) => {
      const wand = new THREE.Mesh(
        new THREE.SphereGeometry(a.r, 36, 28),
        glass(0xffd8a8, i === 0 ? 0.14 : 0.1),
      )
      wand.position.copy(a.p)
      alveolen.add(wand)
      // Innenauskleidung (Alveolarepithel Typ I – extrem flach, 0,1 µm)
      const innen = new THREE.Mesh(
        new THREE.SphereGeometry(a.r - 0.25, 36, 28),
        glass(0xffa94d, 0.08),
      )
      innen.position.copy(a.p)
      alveolen.add(innen)
    })

    // Bronchiolus respiratorius
    const bronchiolus = tube(
      [V(-20, 12, 0), V(-14, 9, 0), V(-8, 7, 0), V(-3, 5, 0)],
      1.8,
      std(0xffc078, { roughness: 0.5, transparent: true, opacity: 0.55 }),
    )
    alveolen.add(bronchiolus)
    beschriftung.add(
      label('Bronchiolus respiratorius', [-21, 15, 0], 'warm'),
      label('Alveole – Ø 200–300 µm', [0, 11, 0], 'warm'),
      label('300 Mio. Alveolen · 70–140 m² Austauschfläche', [0, 9.8, 0], 'muted'),
    )

    // --- Typ-II-Pneumozyten und Surfactant ---------------------------------------
    const typ2Zellen = []
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * Math.PI * 2
      const p = V(Math.cos(a) * 6.2, 3 + Math.sin(a * 1.7) * 2.5, Math.sin(a) * 6.2)
      const z = atom(p, 0.9, 0x51cf66, { material: std(0x51cf66, { roughness: 0.45 }) })
      surfactant.add(z)
      typ2Zellen.push(z)
      // Lamellenkörperchen
      for (let k = 0; k < 3; k++) {
        surfactant.add(
          atom(p.clone().add(V((zufall() - 0.5) * 1.2, (zufall() - 0.5) * 1.2, (zufall() - 0.5) * 1.2)), 0.24, 0x8ce99a, {
            material: glow(0x8ce99a, 0.4),
            segments: 8,
          }),
        )
      }
    }
    // Surfactant-Film auf der Innenoberfläche
    const film = new THREE.Mesh(new THREE.SphereGeometry(6.3, 36, 28), glass(0x8ce99a, 0.12))
    film.position.copy(alveolePositionen[0].p)
    surfactant.add(film)
    beschriftung.add(
      label('Typ-II-Pneumozyt – Surfactant (DPPC)', [10, 8, 4], 'green'),
      label('senkt Oberflächenspannung 70 → 5–30 mN/m', [10, 7, 4], 'muted'),
    )

    // --- Kapillarnetz über der Alveolenoberfläche ---------------------------------
    const kapillarBahnen = []
    for (let i = 0; i < 7; i++) {
      const phi0 = (i / 7) * Math.PI
      const pts = []
      for (let j = 0; j <= 16; j++) {
        const th = (j / 16) * Math.PI * 2
        const r = 6.9
        const phi = phi0 + Math.sin(th * 2) * 0.28
        pts.push(
          V(
            Math.sin(phi) * Math.cos(th) * r,
            3 + Math.cos(phi) * r,
            Math.sin(phi) * Math.sin(th) * r,
          ),
        )
      }
      kapillaren.add(tube(pts, 0.45, std(0xe03131, { roughness: 0.45, transparent: true, opacity: 0.75 }), { tubularSegments: 140 }))
      kapillarBahnen.push(pts)
    }
    beschriftung.add(
      label('Lungenkapillare – Ø 8 µm', [-12, -6, 4], 'hot'),
      label('Kontaktzeit 0,75 s (Ruhe) – Sättigung nach 0,25 s', [-12, -7, 4], 'muted'),
    )

    // --- Erythrozyten (bikonkav, Ø 7,5 µm) ----------------------------------------
    const eryListe = []
    for (let i = 0; i < 24; i++) {
      const bahn = kapillarBahnen[i % kapillarBahnen.length]
      const geo = new THREE.TorusGeometry(0.36, 0.2, 8, 16)
      const ery = new THREE.Mesh(geo, std(0x862e2e, { roughness: 0.5 }))
      ery.userData = { bahn, offset: zufall(), gesaettigt: 0 }
      erythrozyten.add(ery)
      eryListe.push(ery)
    }

    // --- Gasmoleküle: O₂ hinein, CO₂ hinaus ---------------------------------------
    const o2Liste = []
    const co2Liste = []
    for (let i = 0; i < 26; i++) {
      const o2 = atom([0, 0, 0], 0.28, 0x4dabf7, { material: glow(0x4dabf7, 0.8), segments: 8 })
      o2.userData = { phase: zufall(), richtung: zufall() * Math.PI * 2, hoehe: zufall() * Math.PI }
      gase.add(o2)
      o2Liste.push(o2)

      const co2 = atom([0, 0, 0], 0.3, 0x868e96, { material: glow(0xadb5bd, 0.5), segments: 8 })
      co2.userData = { phase: zufall(), richtung: zufall() * Math.PI * 2, hoehe: zufall() * Math.PI }
      gase.add(co2)
      co2Liste.push(co2)
    }

    // --- Blut-Luft-Schranke im Detailausschnitt ------------------------------------
    const schranke = new THREE.Group()
    schranke.position.set(0, -14, 0)
    const schichten = [
      { y: 0, dicke: 0.5, farbe: 0xffa94d, name: 'Surfactant-Film' },
      { y: -0.9, dicke: 0.6, farbe: 0xffd8a8, name: 'Alveolarepithel Typ I (0,1 µm)' },
      { y: -1.8, dicke: 0.5, farbe: 0xd0bfff, name: 'gemeinsame Basalmembran' },
      { y: -2.7, dicke: 0.6, farbe: 0xffc9c9, name: 'Kapillarendothel' },
    ]
    schichten.forEach((s) => {
      const platte = new THREE.Mesh(new THREE.BoxGeometry(18, s.dicke, 6), std(s.farbe, { roughness: 0.5 }))
      platte.position.y = s.y
      schranke.add(platte)
      schranke.add(label(s.name, [11.5, s.y, 0], 'muted'))
    })
    schranke.add(
      label('Blut-Luft-Schranke: 0,2–0,6 µm', [0, 1.4, 0], 'accent'),
      label("Fick: V̇gas = (A/d) · D · (P₁ − P₂)", [0, -4.4, 0], 'warm'),
      label('D ∝ Löslichkeit/√M → CO₂ diffundiert 20× schneller als O₂', [0, -5.4, 0], 'muted'),
    )
    // Diffusionspfeile durch die Schranke
    const diffPfeile = []
    for (let i = 0; i < 5; i++) {
      const x = -6 + i * 3
      const a = arrow([x, 0.6, 0], [x, -3.4, 0], 0x4dabf7, { radius: 0.09 })
      schranke.add(a)
      diffPfeile.push(a)
    }

    const partialdruecke = new THREE.Group()
    partialdruecke.add(
      label('Alveolarluft: pO₂ 100 mmHg · pCO₂ 40 mmHg', [0, -21, 0], 'muted'),
      label('gemischtvenös: pO₂ 40 · pCO₂ 46   →   arterialisiert: pO₂ 100 · pCO₂ 40', [0, -22.2, 0], 'muted'),
    )

    group.add(alveolen, kapillaren, erythrozyten, gase, surfactant, schranke, beschriftung, partialdruecke)

    return {
      group,
      camera: { position: [0, -3, 48], target: [0, -3, 0] },
      layers: [
        { id: 'alveolen', name: 'Alveolen & Bronchiolus', objects: [alveolen] },
        { id: 'kapillaren', name: 'Kapillarnetz', objects: [kapillaren] },
        { id: 'ery', name: 'Erythrozyten', objects: [erythrozyten] },
        { id: 'gase', name: 'O₂ / CO₂-Diffusion', objects: [gase] },
        { id: 'surfactant', name: 'Surfactant & Typ-II-Zellen', objects: [surfactant] },
        { id: 'schranke', name: 'Blut-Luft-Schranke', objects: [schranke] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung, partialdruecke] },
      ],
      update(t) {
        // Atemzyklus: 4 s pro Atemzug (15/min)
        const atem = Math.sin(t * 0.5)
        const skala = 1 + atem * 0.06
        alveolen.children.forEach((m) => m.scale.setScalar(skala))
        film.scale.setScalar(skala)

        // Erythrozyten passieren die Kapillare und sättigen sich dabei auf
        eryListe.forEach((ery) => {
          ery.userData.offset = (ery.userData.offset + 0.0022) % 1
          const bahn = ery.userData.bahn
          const f = ery.userData.offset * (bahn.length - 1)
          const idx = Math.min(bahn.length - 2, Math.floor(f))
          ery.position.lerpVectors(bahn[idx], bahn[idx + 1], f - idx)
          ery.lookAt(bahn[Math.min(bahn.length - 1, idx + 1)])
          // Farbwechsel dunkelrot → hellrot: Sättigung nach ~1/3 der Strecke
          const saettigung = Math.min(1, ery.userData.offset * 3)
          ery.material.color.setRGB(0.35 + saettigung * 0.5, 0.12 + saettigung * 0.06, 0.12 + saettigung * 0.1)
        })

        // O₂ von der Alveole zur Kapillare, CO₂ umgekehrt
        o2Liste.forEach((o) => {
          const f = (t * 0.3 + o.userData.phase) % 1
          const r = 6.5 - f * 1.2
          const th = o.userData.richtung
          const ph = o.userData.hoehe
          o.position.set(
            Math.sin(ph) * Math.cos(th) * r * (1 - f * 0.02),
            3 + Math.cos(ph) * r,
            Math.sin(ph) * Math.sin(th) * r,
          )
          o.material.opacity = 1 - f * 0.3
        })
        co2Liste.forEach((c) => {
          const f = (t * 0.3 + c.userData.phase) % 1
          const r = 5.3 + f * 1.2
          const th = c.userData.richtung
          const ph = c.userData.hoehe
          c.position.set(
            Math.sin(ph) * Math.cos(th) * r,
            3 + Math.cos(ph) * r,
            Math.sin(ph) * Math.sin(th) * r,
          )
        })

        diffPfeile.forEach((a, i) => {
          a.scale.setScalar(0.75 + 0.3 * Math.sin(t * 2.5 + i * 0.7))
        })

        typ2Zellen.forEach((z, i) => {
          z.scale.setScalar(1 + 0.08 * Math.sin(t * 1.5 + i))
        })
      },
    }
  },

  info: {
    summary:
      'Der Gasaustausch ist reine passive Diffusion – die Lunge verbraucht dafür keine Energie. Möglich wird das durch eine extreme Geometrie: 70–140 m² Austauschfläche (etwa eine Tennisplatzhälfte) bei einer Barriere von nur 0,2–0,6 µm Dicke, dünner als ein Hundertstel eines Haares.',
    sections: [
      {
        title: "Fick'sches Diffusionsgesetz",
        body: [
          'V̇gas = (A/d) · D · (P₁ − P₂). Der Gasfluss steigt mit Fläche und Partialdruckdifferenz und sinkt mit der Diffusionsstrecke.',
          'Der Diffusionskoeffizient D ist proportional zur Löslichkeit und umgekehrt proportional zur Wurzel der Molmasse. CO₂ ist etwa 24-mal besser löslich als O₂ und diffundiert daher rund 20-mal schneller – obwohl seine Partialdruckdifferenz mit nur 6 mmHg viel kleiner ist als die von O₂ (60 mmHg).',
          'Klinische Konsequenz: Diffusionsstörungen (Fibrose, Ödem) führen zuerst zur Hypoxämie, während die CO₂-Elimination lange normal bleibt. Eine Hyperkapnie ist fast immer Zeichen einer Ventilationsstörung, nicht einer Diffusionsstörung.',
        ],
      },
      {
        title: 'Blut-Luft-Schranke',
        body: [
          'Vier Schichten: Surfactant-Film, Alveolarepithel Typ I (nur 0,1 µm dick, bedeckt aber 95 % der Fläche), gemeinsame Basalmembran und Kapillarendothel.',
          'Typ-I-Pneumozyten sind hochspezialisiert und teilungsunfähig; nach Schädigung differenzieren sich Typ-II-Zellen zu Typ-I-Zellen um – sie sind die Stammzellreserve des Alveolarepithels.',
          'Die Kontaktzeit eines Erythrozyten in der Lungenkapillare beträgt in Ruhe etwa 0,75 s. Der Druckausgleich für O₂ ist bereits nach 0,25 s abgeschlossen – es besteht also eine dreifache Sicherheitsreserve. Erst unter starker Belastung (Kontaktzeit auf 0,25 s verkürzt) wird das relevant, weshalb sich Diffusionsstörungen zuerst unter Belastung zeigen.',
        ],
      },
      {
        title: 'Surfactant und Oberflächenspannung',
        body: [
          'Laplace-Gesetz für die Alveole (eine Grenzfläche): P = 2σ/r. Ohne Surfactant hätten kleine Alveolen einen höheren Innendruck und würden sich in große entleeren – die Lunge kollabierte.',
          'Surfactant besteht zu ~90 % aus Lipiden (v. a. Dipalmitoylphosphatidylcholin, DPPC) und zu ~10 % aus Proteinen (SP-A bis SP-D). Es senkt die Oberflächenspannung von 70 mN/m (reines Wasser) auf 5–30 mN/m.',
          'Entscheidend ist die Dynamik: Bei Exspiration rücken die Moleküle enger zusammen und senken die Spannung stärker – kleine Alveolen werden dadurch überproportional stabilisiert. Das verhindert den Alveolarkollaps und erhöht die Compliance erheblich.',
          'Klinik: Die Surfactant-Produktion beginnt in SSW 24 und ist ab SSW 35 ausreichend. Frühgeborene entwickeln sonst ein Atemnotsyndrom (IRDS) – Prophylaxe durch antenatale Glukokortikoide, Therapie durch Surfactant-Substitution.',
        ],
      },
      {
        title: 'Ventilations-Perfusions-Verhältnis',
        body: [
          'Global gilt V̇/Q̇ ≈ 0,8 (4,2 l/min Ventilation zu 5 l/min Perfusion). Regional bestehen jedoch erhebliche Unterschiede.',
          'Im Stehen sind Spitzenfelder hoch ventiliert, aber schlecht perfundiert (V̇/Q̇ ≈ 3), basale Felder umgekehrt (V̇/Q̇ ≈ 0,6). Ursache ist die Schwerkraft (West-Zonen I–III).',
          'Zwei Extremfälle: V̇/Q̇ = ∞ bedeutet Totraum (ventiliert, nicht perfundiert – z. B. Lungenembolie); V̇/Q̇ = 0 bedeutet Shunt (perfundiert, nicht ventiliert – z. B. Atelektase, Pneumonie).',
          'Ein Shunt lässt sich durch O₂-Gabe kaum korrigieren, eine Diffusionsstörung dagegen gut – das ist ein wichtiges differentialdiagnostisches Kriterium.',
          'Die hypoxische pulmonale Vasokonstriktion (Euler-Liljestrand-Mechanismus) ist eine Besonderheit der Lunge: Bei alveolärer Hypoxie verengen sich die Gefäße und lenken das Blut in besser belüftete Bezirke – im Körperkreislauf wäre das genau umgekehrt.',
        ],
      },
    ],
    facts: [
      { k: 'Alveolenzahl', v: '~300 Millionen' },
      { k: 'Austauschfläche', v: '70–140 m²' },
      { k: 'Blut-Luft-Schranke', v: '0,2–0,6 µm' },
      { k: 'Alveolendurchmesser', v: '200–300 µm' },
      { k: 'pO₂ / pCO₂ alveolär', v: '100 / 40 mmHg' },
      { k: 'pO₂ / pCO₂ venös', v: '40 / 46 mmHg' },
      { k: 'Kontaktzeit (Ruhe)', v: '0,75 s' },
      { k: 'V̇/Q̇ global', v: '≈ 0,8' },
    ],
    exam: [
      "Fick'sches Gesetz anwenden und erklären, warum CO₂ trotz kleiner Druckdifferenz gut eliminiert wird.",
      'Vier Schichten der Blut-Luft-Schranke benennen.',
      'Laplace-Gesetz und die Rolle des Surfactants für kleine Alveolen erklären.',
      'Shunt gegen Totraum abgrenzen; Verhalten unter O₂-Gabe.',
      'Euler-Liljestrand-Mechanismus und seinen physiologischen Sinn beschreiben.',
    ],
  },
}
