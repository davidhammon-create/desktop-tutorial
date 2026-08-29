import * as THREE from 'three'
import { arrow, atom, bond, glass, glow, label, lipidBilayer, rng, std, tube, V } from '../../three/lib'

/**
 * Chemische Synapse: Aktionspotential, Ca²⁺-Einstrom, Vesikelfusion,
 * Transmitterdiffusion und postsynaptische Rezeptorbindung.
 * Maßstab: 1 Einheit ≈ 10 nm.
 */
export default {
  id: 'synapse',
  name: 'Chemische Synapse',
  discipline: 'medizin',
  level: 'Bachelor / Physikum',
  tagline: 'Erregungsübertragung von der Präsynapse zum Rezeptor',
  scale: '1 Einheit ≈ 10 nm',

  build() {
    const group = new THREE.Group()
    const axon = new THREE.Group()
    const praesynapse = new THREE.Group()
    const vesikelG = new THREE.Group()
    const spalt = new THREE.Group()
    const postsynapse = new THREE.Group()
    const kanaele = new THREE.Group()
    const beschriftung = new THREE.Group()
    const zufall = rng(29)

    // --- Axon mit Myelinscheide und Ranvier-Schnürringen ------------------------
    const axonPunkte = [V(-30, 8, 0), V(-20, 7, 0), V(-12, 5.5, 0), V(-6, 4, 0)]
    axon.add(tube(axonPunkte, 1.3, std(0xffd43b, { roughness: 0.5 }), { tubularSegments: 100 }))

    const myelin = []
    for (let i = 0; i < 4; i++) {
      const m = new THREE.Mesh(new THREE.CapsuleGeometry(2.2, 4.5, 8, 20), glass(0xf1f3f5, 0.5))
      const p = new THREE.Vector3().lerpVectors(axonPunkte[0], axonPunkte[3], (i + 0.5) / 4)
      m.position.copy(p)
      m.rotation.z = Math.PI / 2 - 0.12
      axon.add(m)
      myelin.push(m)
    }
    beschriftung.add(
      label('Myelinscheide – saltatorische Erregungsleitung', [-22, 12, 0], 'muted'),
      label('Ranvier-Schnürring: Nav1.6-Cluster', [-16, 2.5, 0], 'muted'),
    )

    // --- Präsynaptisches Endknöpfchen --------------------------------------------
    const endknopf = new THREE.Mesh(new THREE.SphereGeometry(7.5, 40, 32), glass(0xffd43b, 0.2))
    endknopf.position.set(0, 4, 0)
    endknopf.scale.set(1.1, 0.95, 1)
    praesynapse.add(endknopf)

    // Aktive Zone: Ort der Vesikelfusion
    const aktiveZone = new THREE.Mesh(new THREE.BoxGeometry(9, 0.4, 7), std(0xfa5252, { roughness: 0.4 }))
    aktiveZone.position.set(0, -2.6, 0)
    praesynapse.add(aktiveZone)

    // Spannungsabhängige Ca²⁺-Kanäle (P/Q-Typ, Cav2.1) in der aktiven Zone
    const caKanaele = []
    for (let i = 0; i < 6; i++) {
      const x = -3.5 + i * 1.4
      const k = new THREE.Mesh(new THREE.CylinderGeometry(0.45, 0.45, 1.4, 12), std(0x51cf66, { roughness: 0.4 }))
      k.position.set(x, -2.6, i % 2 ? 1.8 : -1.8)
      kanaele.add(k)
      caKanaele.push(k)
    }

    // Mitochondrium im Endknöpfchen (hoher ATP-Bedarf)
    const mito = new THREE.Mesh(new THREE.CapsuleGeometry(1.1, 2.6, 8, 16), std(0xe03131, { roughness: 0.5, transparent: true, opacity: 0.6 }))
    mito.position.set(-3.5, 6.5, 1.5)
    mito.rotation.z = 0.6
    praesynapse.add(mito)

    // --- Synaptische Vesikel (Ø 40 nm, je ~5000 Transmittermoleküle) ------------
    const vesikel = []
    for (let i = 0; i < 22; i++) {
      const bereitgestellt = i < 6 // Readily Releasable Pool an der aktiven Zone
      const v = new THREE.Mesh(new THREE.SphereGeometry(1.15, 20, 16), glass(0x9775fa, 0.55))
      const p = bereitgestellt
        ? V(-3.5 + (i % 6) * 1.4, -1.2, (i % 2 ? 1 : -1) * 1.4)
        : V((zufall() - 0.5) * 9, 3 + zufall() * 5, (zufall() - 0.5) * 7)
      v.position.copy(p)
      v.userData = { start: p.clone(), bereitgestellt, phase: zufall() * Math.PI * 2, index: i }
      vesikelG.add(v)
      vesikel.push(v)
    }
    beschriftung.add(
      label('synaptische Vesikel – Ø 40 nm, ~5000 Moleküle', [10, 8, 0], 'accent2'),
      label('aktive Zone mit Cav2.1-Kanälen', [10, -1.5, 0], 'green'),
    )

    // --- Synaptischer Spalt (20–40 nm) --------------------------------------------
    const spaltHoehe = -4.2
    spalt.add(
      label('synaptischer Spalt: 20–40 nm', [-13, -5.5, 0], 'warm'),
      label('Acetylcholinesterase – Abbau in < 1 ms', [13, -5.5, 0], 'warm'),
    )
    // Enzyme im Spalt
    for (let i = 0; i < 8; i++) {
      spalt.add(
        atom([(zufall() - 0.5) * 16, spaltHoehe - 0.4 + zufall() * 0.8, (zufall() - 0.5) * 6], 0.35, 0xff922b, {
          material: std(0xff922b, { roughness: 0.5 }),
        }),
      )
    }

    // --- Postsynaptische Membran mit Rezeptoren ------------------------------------
    const postMembran = lipidBilayer(26, 10, {
      spacing: 1.2,
      headRadius: 0.35,
      thickness: 0.9,
      headColor: 0x4dabf7,
      tailColor: 0xffe066,
    })
    postMembran.position.set(0, -7.5, 0)
    postsynapse.add(postMembran)

    // Ionotrope Rezeptoren (nAChR: pentamer, Kationenkanal)
    const rezeptoren = []
    for (let i = 0; i < 9; i++) {
      const x = -10 + i * 2.5
      const r = new THREE.Group()
      for (let k = 0; k < 5; k++) {
        const a = (k / 5) * Math.PI * 2
        const u = new THREE.Mesh(new THREE.CylinderGeometry(0.32, 0.32, 3.2, 10), std(0x4263eb, { roughness: 0.4 }))
        u.position.set(Math.cos(a) * 0.55, 0, Math.sin(a) * 0.55)
        r.add(u)
      }
      r.position.set(x, -7.5, 0)
      r.userData = { x, offen: 0 }
      postsynapse.add(r)
      rezeptoren.push(r)
    }

    // Postsynaptische Verdichtung (PSD-95 & Gerüstproteine)
    const psd = new THREE.Mesh(new THREE.BoxGeometry(24, 0.5, 8), std(0x862e9e, { roughness: 0.6 }))
    psd.position.set(0, -9.4, 0)
    postsynapse.add(psd)
    beschriftung.add(
      label('postsynaptische Verdichtung (PSD-95)', [0, -11.5, 0], 'accent2'),
      label('nAChR – ligandengesteuerter Kationenkanal', [-16, -8.5, 0], 'accent'),
    )

    // --- Transmittermoleküle im Spalt -----------------------------------------------
    const transmitter = []
    for (let i = 0; i < 60; i++) {
      const m = atom([0, 0, 0], 0.28, 0xffd43b, { material: glow(0xffd43b, 0.8), segments: 8 })
      m.userData = {
        vesikel: i % 6,
        streuung: V((zufall() - 0.5) * 2, 0, (zufall() - 0.5) * 2),
        ziel: rezeptoren[Math.floor(zufall() * rezeptoren.length)].position.clone(),
        verzug: zufall() * 0.25,
      }
      m.visible = false
      spalt.add(m)
      transmitter.push(m)
    }

    // --- Aktionspotential als wandernde Depolarisation -------------------------------
    const apMarker = new THREE.Mesh(new THREE.SphereGeometry(2.4, 20, 16), glow(0xff6b6b, 1.2))
    apMarker.material.transparent = true
    apMarker.material.opacity = 0.5
    axon.add(apMarker)

    const caIonen = []
    for (let i = 0; i < 14; i++) {
      const c = atom([0, 0, 0], 0.24, 0x51cf66, { material: glow(0x51cf66, 1.0), segments: 8 })
      c.userData = { kanal: i % caKanaele.length, verzug: zufall() * 0.15 }
      c.visible = false
      praesynapse.add(c)
      caIonen.push(c)
    }

    const phasen = new THREE.Group()
    phasen.add(
      label('1. AP erreicht Endknöpfchen → 2. Ca²⁺-Einstrom → 3. Vesikelfusion (SNARE)', [0, 14, 0], 'muted'),
      label('4. Transmitterdiffusion → 5. Rezeptorbindung → 6. EPSP · Latenz 0,5–1 ms', [0, 12.8, 0], 'muted'),
    )

    group.add(axon, praesynapse, vesikelG, spalt, postsynapse, kanaele, beschriftung, phasen)

    return {
      group,
      camera: { position: [0, 2, 46], target: [0, 0, 0] },
      layers: [
        { id: 'axon', name: 'Axon & Myelin', objects: [axon] },
        { id: 'prae', name: 'Präsynapse', objects: [praesynapse] },
        { id: 'vesikel', name: 'Vesikel', objects: [vesikelG] },
        { id: 'kanaele', name: 'Ca²⁺-Kanäle', objects: [kanaele] },
        { id: 'spalt', name: 'Synaptischer Spalt', objects: [spalt] },
        { id: 'post', name: 'Postsynapse & Rezeptoren', objects: [postsynapse] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung, phasen] },
      ],
      update(t) {
        const zyklus = 4.0
        const p = (t % zyklus) / zyklus

        // Phase 1: AP wandert das Axon entlang (0 – 0,25)
        if (p < 0.25) {
          const f = p / 0.25
          apMarker.visible = true
          const idx = Math.min(axonPunkte.length - 2, Math.floor(f * (axonPunkte.length - 1)))
          const lokal = f * (axonPunkte.length - 1) - idx
          apMarker.position.lerpVectors(axonPunkte[idx], axonPunkte[idx + 1], lokal)
          apMarker.material.opacity = 0.55
        } else {
          apMarker.visible = false
        }

        // Phase 2: Ca²⁺-Einstrom (0,25 – 0,4)
        const caPhase = (p - 0.25) / 0.15
        caKanaele.forEach((k, i) => {
          const offen = p >= 0.25 && p < 0.45
          k.scale.x = k.scale.z = offen ? 1.35 : 1
          k.material.color.setHex(offen ? 0x8ce99a : 0x51cf66)
        })
        caIonen.forEach((c) => {
          const f = caPhase - c.userData.verzug
          if (f > 0 && f < 1) {
            c.visible = true
            const k = caKanaele[c.userData.kanal]
            c.position.set(k.position.x, -2.6 + f * 3.5, k.position.z * (1 - f * 0.4))
          } else {
            c.visible = false
          }
        })

        // Phase 3: Vesikelfusion (0,35 – 0,5)
        vesikel.forEach((v) => {
          const s = v.userData.start
          if (v.userData.bereitgestellt) {
            const f = Math.max(0, Math.min(1, (p - 0.35) / 0.15))
            // Vesikel wandert zur aktiven Zone und verschmilzt (Radius geht gegen 0)
            v.position.set(s.x, s.y - f * 1.3, s.z * (1 - f))
            v.scale.setScalar(1 - f * 0.9)
            v.material.opacity = 0.55 * (1 - f * 0.8)
          } else {
            // Reservepool bewegt sich langsam
            v.position.set(
              s.x + Math.sin(t * 0.6 + v.userData.phase) * 0.5,
              s.y + Math.cos(t * 0.5 + v.userData.phase) * 0.5,
              s.z + Math.sin(t * 0.4 + v.userData.phase) * 0.4,
            )
          }
        })

        // Phase 4+5: Transmitterdiffusion und Rezeptorbindung (0,45 – 0,8)
        transmitter.forEach((m) => {
          const f = (p - 0.45 - m.userData.verzug) / 0.3
          if (f > 0 && f < 1) {
            m.visible = true
            const start = V(-3.5 + m.userData.vesikel * 1.4, -3.2, 0).add(m.userData.streuung)
            m.position.lerpVectors(start, m.userData.ziel, f)
            // Zufallsbewegung überlagert die Diffusion
            m.position.x += Math.sin(t * 8 + m.userData.vesikel) * 0.25 * (1 - f)
            m.position.z += Math.cos(t * 7 + m.userData.vesikel) * 0.25 * (1 - f)
          } else {
            m.visible = false
          }
        })

        // Rezeptoren öffnen sich nach Bindung
        rezeptoren.forEach((r, i) => {
          const aktiv = p > 0.6 && p < 0.85
          const s = aktiv ? 1 + 0.25 * Math.sin(t * 12 + i) : 1
          r.children.forEach((u, k) => {
            const a = (k / 5) * Math.PI * 2
            const spreizung = aktiv ? 0.85 : 0.55
            u.position.set(Math.cos(a) * spreizung, 0, Math.sin(a) * spreizung)
            u.material.color.setHex(aktiv ? 0x748ffc : 0x4263eb)
          })
        })
      },
    }
  },

  info: {
    summary:
      'Die chemische Synapse wandelt ein elektrisches Signal in ein chemisches und wieder zurück. Dieser Umweg kostet Zeit (synaptische Latenz 0,5–1 ms), ermöglicht aber Verstärkung, Umkehrung des Vorzeichens (Hemmung), Plastizität – und macht die Synapse zum wichtigsten pharmakologischen Angriffspunkt des Nervensystems.',
    sections: [
      {
        title: 'Ablauf der Übertragung',
        body: [
          '1. Das Aktionspotential erreicht das Endknöpfchen und depolarisiert dessen Membran.',
          '2. Spannungsabhängige Ca²⁺-Kanäle (P/Q-Typ, Cav2.1) öffnen. Die intrazelluläre Ca²⁺-Konzentration steigt lokal in Mikrodomänen von 100 nM auf über 10 µM.',
          '3. Ca²⁺ bindet an Synaptotagmin-1, den Calciumsensor. Der SNARE-Komplex aus Synaptobrevin (v-SNARE) sowie Syntaxin-1 und SNAP-25 (t-SNAREs) zieht Vesikel- und Plasmamembran zusammen und löst die Fusion aus.',
          '4. Der Transmitter diffundiert über den 20–40 nm breiten Spalt – bei dieser Distanz dauert das weniger als 0,1 ms.',
          '5. Bindung an postsynaptische Rezeptoren öffnet Ionenkanäle; es entsteht ein EPSP oder IPSP.',
          '6. Beendigung durch enzymatischen Abbau (Acetylcholinesterase), Wiederaufnahme (SERT, DAT, NET, EAAT) oder Diffusion.',
        ],
      },
      {
        title: 'Quantenhypothese',
        body: [
          'Katz und Fatt beobachteten an der neuromuskulären Endplatte spontane Miniatur-Endplattenpotentiale (MEPPs) von etwa 0,5 mV.',
          'Die Amplituden evozierter Potentiale sind immer ganzzahlige Vielfache dieses Werts. Schlussfolgerung: Transmitter wird in festen Paketen (Quanten) freigesetzt – ein Quantum entspricht einem Vesikel mit rund 5000 Molekülen.',
          'Die Freisetzung ist probabilistisch und folgt einer Binomial-/Poisson-Statistik: m = n · p, mit n freisetzbaren Vesikeln und Freisetzungswahrscheinlichkeit p. Genau an p greifen viele Formen der Kurzzeitplastizität an.',
        ],
      },
      {
        title: 'Rezeptortypen',
        body: [
          'Ionotrop: Rezeptor und Kanal sind dasselbe Protein, Wirkung innerhalb von Millisekunden. Beispiele: nAChR und AMPA/NMDA (erregend, Kationen), GABA_A und Glycin (hemmend, Cl⁻).',
          'Metabotrop: G-Protein-gekoppelt, Wirkung über Sekundenbotenstoffe, langsamer (100 ms bis Sekunden), dafür verstärkend und modulierend. Beispiele: mAChR, adrenerge, dopaminerge und Opioid-Rezeptoren.',
          'Der NMDA-Rezeptor ist ein Sonderfall und Koinzidenzdetektor: Er benötigt gleichzeitig Glutamatbindung und Depolarisation, um den Mg²⁺-Block zu entfernen. Der resultierende Ca²⁺-Einstrom ist die molekulare Grundlage der Langzeitpotenzierung (LTP) und damit des Lernens.',
        ],
      },
      {
        title: 'Pharmakologie und Pathologie',
        body: [
          'Botulinumtoxin spaltet SNAP-25 bzw. Synaptobrevin und blockiert die Freisetzung vollständig – daher schlaffe Lähmung. Tetanustoxin greift dieselben Proteine an, wirkt aber an hemmenden Renshaw-Zellen und führt so zu spastischer Lähmung.',
          'Cholinesterasehemmer (Neostigmin, Physostigmin, Organophosphate) verlängern die Transmitterwirkung – therapeutisch bei Myasthenia gravis, toxisch als Nervenkampfstoff.',
          'Myasthenia gravis: Autoantikörper gegen den nAChR führen zu belastungsabhängiger Muskelschwäche. Lambert-Eaton-Syndrom: Antikörper gegen präsynaptische Cav2.1-Kanäle, dadurch typischerweise Besserung nach kurzer Belastung.',
          'Psychopharmaka greifen fast ausschließlich synaptisch an: SSRI hemmen SERT, Benzodiazepine sind positive allosterische Modulatoren des GABA_A-Rezeptors, Levodopa ergänzt die Dopaminsynthese.',
        ],
      },
    ],
    facts: [
      { k: 'Synaptischer Spalt', v: '20–40 nm' },
      { k: 'Synaptische Latenz', v: '0,5–1 ms' },
      { k: 'Vesikeldurchmesser', v: '~40 nm' },
      { k: 'Moleküle pro Vesikel', v: '~5000' },
      { k: 'Ca²⁺: Ruhe → Mikrodomäne', v: '100 nM → > 10 µM' },
      { k: 'MEPP-Amplitude', v: '~0,5 mV' },
      { k: 'Synapsen pro Neuron (Kortex)', v: '~7000' },
      { k: 'Leitung: myelinisiert', v: 'bis 120 m/s' },
    ],
    exam: [
      'Sechs Schritte der synaptischen Übertragung in Reihenfolge und mit Zeitangaben nennen.',
      'Quantenhypothese und die Bedeutung der MEPPs erklären.',
      'Warum ist der NMDA-Rezeptor ein Koinzidenzdetektor?',
      'Botulinum- gegen Tetanustoxin abgrenzen: gleicher Mechanismus, gegensätzliche Klinik.',
      'EPSP und IPSP unterscheiden; räumliche und zeitliche Summation erklären.',
    ],
  },
}
