/**
 * Erzeugt Bildschirmfotos der Website – eines je Modell, dazu einige Aufnahmen
 * der Bedienelemente.
 *
 *   npm run build && npm run preview     (in einem Terminal)
 *   npm run shots                        (in einem zweiten)
 *
 * Die Bilder landen in screenshots/ und werden von scripts/shots2pdf.py zu
 * einer PDF zusammengesetzt.
 *
 * Ohne GPU rendert Chromium per SwiftShader mit wenigen Bildern pro Sekunde.
 * Deshalb wird nach jedem Modellwechsel bewusst lange gewartet, damit die
 * Szene vollständig aufgebaut ist, bevor ausgelöst wird.
 */
import { chromium } from 'playwright'
import { mkdir, writeFile } from 'node:fs/promises'

const URL = process.env.SHOT_URL ?? 'http://localhost:4173/'
const ORDNER = 'screenshots'
const BREITE = 1600
const HOEHE = 1000
const WARTEZEIT = Number(process.env.SHOT_WAIT ?? 4500)

await mkdir(ORDNER, { recursive: true })

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || undefined,
  args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--no-sandbox'],
})
const page = await browser.newPage({
  viewport: { width: BREITE, height: HOEHE },
  deviceScaleFactor: 1.5, // schärfere Bilder für den Druck
})

await page.goto(URL, { waitUntil: 'domcontentloaded' })
await page.waitForTimeout(3000)

// Klicks direkt im DOM: Playwrights Actionability-Prüfung wartet auf stabile
// Frames und wäre bei Software-Rendering unnötig langsam.
const klick = (sel, i = 0) =>
  page.evaluate(([s, n]) => document.querySelectorAll(s)[n]?.click(), [sel, i])

const anzahl = await page.$$eval('.modell', (e) => e.length)
console.log(`${anzahl} Modelle gefunden`)

const verzeichnis = []

for (let i = 0; i < anzahl; i++) {
  await klick('.modell', i)
  await page.waitForTimeout(WARTEZEIT)

  const info = await page.evaluate(() => {
    const chip = document.querySelector('.chip')?.textContent?.trim() ?? ''
    return {
      titel: document.querySelector('.modell-kopf h2')?.textContent ?? '',
      untertitel: document.querySelector('.modell-kopf p')?.textContent ?? '',
      massstab: document.querySelector('.massstab')?.textContent ?? '',
      fach: chip,
      // Erster Absatz des Infopanels als Bildunterschrift
      text: document.querySelector('.panel-scroll .summary')?.textContent ?? '',
    }
  })

  const datei = `${ORDNER}/modell-${String(i + 1).padStart(2, '0')}.png`
  await page.screenshot({ path: datei })
  verzeichnis.push({ datei, art: 'modell', ...info })
  console.log(`  ${String(i + 1).padStart(2)}. ${info.titel}`)
}

// --- Aufnahmen einzelner Bedienelemente -------------------------------------
console.log('Bedienelemente:')

// Suche
await klick('.modell', 0)
await page.waitForTimeout(2500)
await page.fill('.suche input', 'Gegenstrom')
await page.waitForTimeout(1200)
await page.screenshot({ path: `${ORDNER}/ui-suche.png` })
verzeichnis.push({
  datei: `${ORDNER}/ui-suche.png`,
  art: 'ui',
  titel: 'Volltextsuche',
  text: 'Die Suche durchsucht nicht nur Modellnamen, sondern auch die vollständigen Fachtexte und Kennzahlen. Die Eingabe "Gegenstrom" findet das Nephron, obwohl das Wort im Titel nicht vorkommt.',
})
await page.fill('.suche input', '')
await page.waitForTimeout(800)

// Infopanel: Kennzahlen und Prüfungsfragen
const tabs = [
  ['Vertiefung', 'Vertiefungstexte', 'Der vollständige Fachtext, meist vier Abschnitte mit Herleitungen und Begründungen.'],
  ['Kennzahlen', 'Kennzahlen', 'Die prüfungsrelevanten Zahlenwerte jedes Modells als Tabelle.'],
  ['Prüfung', 'Prüfungsfragen', 'Typische Klausur- und Physikumsfragen zum jeweiligen Modell.'],
]
for (let t = 0; t < tabs.length; t++) {
  const [name, titel, text] = tabs[t]
  await klick('.tab', t + 1)
  await page.waitForTimeout(1500)
  const datei = `${ORDNER}/ui-tab-${t + 1}.png`
  await page.screenshot({ path: datei })
  verzeichnis.push({ datei, art: 'ui', titel, text })
  console.log(`  ${titel}`)
}
await klick('.tab', 0)

// Ebenen einzeln abschalten (am Benzol besonders anschaulich)
const benzolIndex = await page.evaluate(() =>
  [...document.querySelectorAll('.modell-name')].findIndex((e) =>
    e.textContent.includes('Benzol'),
  ),
)
if (benzolIndex >= 0) {
  await klick('.modell', benzolIndex)
  await page.waitForTimeout(4000)
  // π-System und p-Orbitale ausblenden – nur das σ-Gerüst bleibt
  await page.evaluate(() => {
    const namen = ['p_z-Orbitale', 'delokalisiertes π-System', 'Ringstrom']
    document.querySelectorAll('.layer').forEach((b) => {
      if (namen.some((n) => b.textContent.includes(n))) b.click()
    })
  })
  await page.waitForTimeout(3000)
  await page.screenshot({ path: `${ORDNER}/ui-ebenen.png` })
  verzeichnis.push({
    datei: `${ORDNER}/ui-ebenen.png`,
    art: 'ui',
    titel: 'Ebenen einzeln schalten',
    text: 'Jede Baugruppe lässt sich ein- und ausblenden. Hier am Benzol: nur das σ-Gerüst, ohne p-Orbitale und π-System – so wird sichtbar, was die Delokalisierung eigentlich hinzufügt.',
  })
  console.log('  Ebenen')
}

// --- Mobile Ansicht ----------------------------------------------------------
const handy = await browser.newPage({
  viewport: { width: 414, height: 896 },
  deviceScaleFactor: 2,
  isMobile: true,
  hasTouch: true,
})
await handy.goto(URL, { waitUntil: 'domcontentloaded' })
await handy.waitForTimeout(5000)

const handyKlick = (sel, i = 0) =>
  handy.evaluate(([s, n]) => document.querySelectorAll(s)[n]?.click(), [sel, i])

// Infopanel zuklappen – sonst verdeckt es auf dem schmalen Bildschirm das Modell
await handyKlick('.panel-schalter')
await handy.waitForTimeout(3500)
await handy.screenshot({ path: `${ORDNER}/ui-mobil.png` })
verzeichnis.push({
  datei: `${ORDNER}/ui-mobil.png`,
  art: 'mobil',
  titel: 'Auf dem Handy',
  text: 'Die Oberfläche passt sich an das schmale Format an. Das Infopanel lässt sich zur Seite klappen, damit das Modell die volle Breite bekommt; Drehen und Zoomen funktionieren per Finger. Als installierte PWA startet sie ohne Browserleiste.',
})

// Menü geöffnet: Navigation über alle Fachbereiche
await handyKlick('.burger')
await handy.waitForTimeout(2500)
await handy.screenshot({ path: `${ORDNER}/ui-mobil-menue.png` })
verzeichnis.push({
  datei: `${ORDNER}/ui-mobil-menue.png`,
  art: 'mobil',
  titel: 'Navigation auf dem Handy',
  text: 'Die Modellliste wird auf schmalen Bildschirmen zum ausklappbaren Menü, nach Fachbereichen gegliedert.',
})
console.log('  Mobile Ansicht (2 Aufnahmen)')

await writeFile(`${ORDNER}/verzeichnis.json`, JSON.stringify(verzeichnis, null, 2))
console.log(`\n${verzeichnis.length} Bilder in ${ORDNER}/`)

await browser.close()
