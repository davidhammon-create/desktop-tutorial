import * as THREE from 'three'
import { atom, bond, glow, label, std, tube, V } from '../../three/lib'

/**
 * B-DNA mit den realen Helixparametern nach Watson/Crick und Franklins
 * Röntgendaten: 10,5 bp pro Windung, 3,4 Å Anstieg, 20 Å Durchmesser.
 * Die beiden Stränge stehen NICHT um 180°, sondern um ca. 140° versetzt –
 * daraus ergeben sich große und kleine Furche.
 * Maßstab: 1 Einheit = 1 Å.
 */
export default {
  id: 'dna',
  name: 'B-DNA Doppelhelix',
  discipline: 'biologie',
  level: 'Bachelor',
  tagline: 'Helixparameter, Furchen und Basenpaarung',
  scale: '1 Einheit = 1 Å',

  build() {
    const group = new THREE.Group()
    const rueckgrat = new THREE.Group()
    const basen = new THREE.Group()
    const furchen = new THREE.Group()
    const beschriftung = new THREE.Group()

    // --- Reale B-DNA-Parameter ---------------------------------------------------
    const bpProWindung = 10.5
    const anstieg = 3.4 // Å pro Basenpaar
    const radius = 9.0 // Å (Rückgrat-Phosphat vom Helixzentrum)
    const versatz = (140 * Math.PI) / 180 // Strangversatz → asymmetrische Furchen
    const anzahlBp = 22 // gut 2 volle Windungen
    const twist = (2 * Math.PI) / bpProWindung

    const strang1 = []
    const strang2 = []
    const sequenz = 'ATGCGATTACGCTAGCTAAGCT'

    // Basenpaare: A–T mit 2 H-Brücken, G–C mit 3
    const komplement = { A: 'T', T: 'A', G: 'C', C: 'G' }
    const basenFarbe = { A: 0x51cf66, T: 0xff6b6b, G: 0x4dabf7, C: 0xffd43b }
    const hBruecken = { A: 2, T: 2, G: 3, C: 3 }

    const paare = []

    for (let i = 0; i < anzahlBp; i++) {
      const y = (i - anzahlBp / 2) * anstieg
      const w = i * twist
      const p1 = V(Math.cos(w) * radius, y, Math.sin(w) * radius)
      const p2 = V(Math.cos(w + versatz) * radius, y, Math.sin(w + versatz) * radius)
      strang1.push(p1)
      strang2.push(p2)

      const b1 = sequenz[i % sequenz.length]
      const b2 = komplement[b1]

      // Basen ragen vom Rückgrat zur Helixachse (Stapelabstand 3,4 Å)
      const in1 = p1.clone().multiplyScalar(0.42)
      in1.y = y
      const in2 = p2.clone().multiplyScalar(0.42)
      in2.y = y

      basen.add(bond(p1, in1, { radius: 0.42, color: basenFarbe[b1] }))
      basen.add(bond(p2, in2, { radius: 0.42, color: basenFarbe[b2] }))

      // Wasserstoffbrücken als gestrichelte Linie (2 bzw. 3 Stränge)
      const n = hBruecken[b1]
      for (let h = 0; h < n; h++) {
        const off = (h - (n - 1) / 2) * 0.9
        const a = in1.clone()
        const b = in2.clone()
        a.y += off
        b.y += off
        basen.add(bond(a, b, { radius: 0.09, color: 0xffffff, material: glow(0xf8f9fa, 0.35) }))
      }

      paare.push({ b1, b2, y, in1, in2 })
    }

    // --- Zucker-Phosphat-Rückgrat als glatte Schläuche ---------------------------
    const s1 = tube(strang1, 1.5, std(0x9775fa, { roughness: 0.35, metalness: 0.2 }), {
      tubularSegments: 400,
    })
    const s2 = tube(strang2, 1.5, std(0x22b8cf, { roughness: 0.35, metalness: 0.2 }), {
      tubularSegments: 400,
    })
    rueckgrat.add(s1, s2)

    // Phosphatgruppen als Markierungen auf dem Rückgrat
    strang1.forEach((p) => rueckgrat.add(atom(p, 0.75, 0xff922b, { segments: 12 })))
    strang2.forEach((p) => rueckgrat.add(atom(p, 0.75, 0xff922b, { segments: 12 })))

    // --- Furchen kennzeichnen ----------------------------------------------------
    const oben = anzahlBp / 2
    furchen.add(
      label('große Furche (22 Å) – Bindungsstelle für Transkriptionsfaktoren', [14, 8, 0], 'warm'),
      label('kleine Furche (12 Å)', [14, -2, 0], 'accent'),
    )
    // Markierungsbögen
    for (let i = 0; i < 30; i++) {
      const f = i / 29
      const w = f * twist * 10.5 * 0.4
      const y = -6 + f * 12
      furchen.add(atom([Math.cos(w) * (radius + 2.2), y, Math.sin(w) * (radius + 2.2)], 0.35, 0xff922b))
    }

    beschriftung.add(
      label("5' → 3'", [radius + 3, anzahlBp * anstieg * 0.5 + 3, 0], 'accent2'),
      label("3' ← 5'", [-radius - 3, -anzahlBp * anstieg * 0.5 - 3, 0], 'cold'),
      label('antiparallel · rechtsgängig · 10,5 bp pro Windung', [0, -anzahlBp * anstieg * 0.5 - 7, 0], 'muted'),
      label('Ganghöhe 35,7 Å · Anstieg 3,4 Å/bp · Ø 20 Å', [0, -anzahlBp * anstieg * 0.5 - 10, 0], 'muted'),
      label('A–T: 2 H-Brücken (grün/rot)   ·   G–C: 3 H-Brücken (blau/gelb)', [0, -anzahlBp * anstieg * 0.5 - 13, 0], 'muted'),
    )

    group.add(rueckgrat, basen, furchen, beschriftung)

    return {
      group,
      camera: { position: [0, 6, 105], target: [0, 0, 0] },
      layers: [
        { id: 'rueckgrat', name: 'Zucker-Phosphat-Rückgrat', objects: [rueckgrat] },
        { id: 'basen', name: 'Basenpaare & H-Brücken', objects: [basen] },
        { id: 'furchen', name: 'Furchen-Markierung', objects: [furchen] },
        { id: 'text', name: 'Beschriftungen', objects: [beschriftung] },
      ],
      update(t) {
        group.rotation.y = t * 0.25
      },
    }
  },

  info: {
    summary:
      'Die B-DNA ist die unter physiologischen Bedingungen dominierende Form. Ihr entscheidendes Strukturmerkmal wird oft übersehen: Die beiden Stränge stehen nicht diametral gegenüber, sondern um etwa 140° versetzt. Genau daraus entstehen die ungleich breite große und kleine Furche – und damit die Möglichkeit, dass Proteine die Sequenz lesen, ohne die Doppelhelix zu öffnen.',
    sections: [
      {
        title: 'Helixparameter',
        body: [
          'B-DNA: rechtsgängig, 10,5 Basenpaare pro Windung, Anstieg 3,4 Å pro bp, Ganghöhe 35,7 Å, Durchmesser 20 Å.',
          'Die Basen stehen nahezu senkrecht zur Helixachse und stapeln sich im Abstand von 3,4 Å. Diese Basenstapelung (π-π-Wechselwirkung und hydrophober Effekt) liefert den Hauptteil der Stabilisierungsenergie – mehr als die Wasserstoffbrücken selbst.',
          'A-DNA (bei niedriger Luftfeuchtigkeit, RNA-DNA-Hybride): 11 bp/Windung, Basen um 20° geneigt, breitere und flachere Helix. Z-DNA: linksgängig, Zickzack-Rückgrat, bei alternierenden Purin-Pyrimidin-Sequenzen.',
        ],
      },
      {
        title: 'Basenpaarung',
        body: [
          'Watson-Crick-Paarung: A–T über zwei Wasserstoffbrücken, G–C über drei. Beide Paare haben identische Geometrie (Purin + Pyrimidin), weshalb der Helixdurchmesser sequenzunabhängig konstant bleibt.',
          'Der höhere GC-Gehalt erhöht die Schmelztemperatur. Faustformel für kurze Oligonukleotide: T_m ≈ 2 °C·(A+T) + 4 °C·(G+C) – Grundlage jedes Primerdesigns in der PCR.',
          'Chargaff-Regeln (1950) waren der entscheidende Hinweis: In jeder DNA gilt %A = %T und %G = %C. Watson und Crick erkannten daraus die komplementäre Paarung.',
        ],
      },
      {
        title: 'Antiparallelität und ihre Folgen',
        body: [
          "Die Stränge verlaufen gegenläufig: einer 5'→3', der andere 3'→5'. Die Nummerierung bezieht sich auf die Kohlenstoffatome der Desoxyribose.",
          "DNA-Polymerasen können ausschließlich in 5'→3'-Richtung synthetisieren und benötigen ein freies 3'-OH-Ende. Deshalb verläuft die Replikation asymmetrisch: Der Leitstrang wird kontinuierlich synthetisiert, der Folgestrang in Okazaki-Fragmenten (bei Eukaryoten 100–200 nt), die anschließend durch Ligase verknüpft werden.",
          "Daraus folgt auch das Endreplikationsproblem linearer Chromosomen – gelöst durch Telomere und Telomerase.",
        ],
      },
      {
        title: 'Furchen als Erkennungsstelle',
        body: [
          'Große Furche: 22 Å breit, 8,5 Å tief. Kleine Furche: 12 Å breit, 7,5 Å tief.',
          'In der großen Furche ist jedes Basenpaar durch sein Muster aus H-Brücken-Donoren, -Akzeptoren und Methylgruppen eindeutig identifizierbar – auch ohne Strangtrennung. Deshalb binden fast alle sequenzspezifischen DNA-bindenden Proteine (Zinkfinger, Helix-Turn-Helix, Leucin-Zipper) dort.',
          'Die kleine Furche liefert weniger Information, wird aber von Strukturproteinen und einigen Antibiotika/Farbstoffen genutzt (Netropsin, Hoechst 33258, DAPI).',
        ],
      },
      {
        title: 'Topologie',
        body: [
          'Es gilt Lk = Tw + Wr (Verwindungszahl = Twist + Writhe). Beim Entwinden durch Polymerasen entstehen Überspiralisierungen, die Topoisomerasen auflösen.',
          'Typ-I-Topoisomerasen schneiden einen Strang (ATP-unabhängig), Typ-II beide (ATP-abhängig, z. B. die bakterielle Gyrase).',
          'Klinisch relevant: Fluorchinolone hemmen die bakterielle Gyrase, Etoposid und Doxorubicin die humane Topoisomerase II – beides etablierte Wirkstoffklassen.',
        ],
      },
    ],
    facts: [
      { k: 'bp pro Windung (B-DNA)', v: '10,5' },
      { k: 'Anstieg pro bp', v: '3,4 Å' },
      { k: 'Ganghöhe', v: '35,7 Å' },
      { k: 'Durchmesser', v: '20 Å' },
      { k: 'Große / kleine Furche', v: '22 Å / 12 Å' },
      { k: 'A–T / G–C', v: '2 / 3 H-Brücken' },
      { k: 'Humanes Genom', v: '3,1·10⁹ bp, ~2 m pro Zelle' },
      { k: 'Ladung', v: '2 negative Ladungen pro bp' },
    ],
    exam: [
      'Warum ist der Helixdurchmesser sequenzunabhängig konstant?',
      'Antiparallelität begründen und daraus Leit-/Folgestrang ableiten.',
      'T_m-Abschätzung für ein gegebenes Oligonukleotid.',
      'Warum lesen Transkriptionsfaktoren bevorzugt in der großen Furche?',
      'Lk = Tw + Wr an einem Beispiel anwenden.',
    ],
  },
}
