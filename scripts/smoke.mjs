/**
 * Smoke-Test: öffnet jedes Modell in einem echten Browser, schaltet Ebenen und
 * Textbereiche durch und sammelt dabei alle Konsolen- und Laufzeitfehler ein.
 *
 * Voraussetzung: ein laufender Server unter http://localhost:4173
 *   npm run build && npm run preview
 *   npm run smoke
 *
 * Zwei Eigenheiten sind Absicht:
 * 1. Ohne GPU rendert Chromium per SwiftShader mit nur wenigen Bildern pro
 *    Sekunde. Playwrights Actionability-Prüfung wartet auf stabile Frames und
 *    bräuchte dann zig Sekunden pro Klick – deshalb wird direkt im DOM geklickt.
 * 2. Die Animation läuft nur kurz an, damit update() jedes Modells tatsächlich
 *    ausgeführt wird, ohne den Testlauf unnötig zu verlangsamen.
 */
import { chromium } from 'playwright'

const URL = process.env.SMOKE_URL ?? 'http://localhost:4173/'

const browser = await chromium.launch({
  // In Umgebungen ohne GPU auf Software-Rendering ausweichen.
  executablePath: process.env.CHROMIUM_PATH || undefined,
  args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--no-sandbox'],
})
const page = await browser.newPage({ viewport: { width: 800, height: 560 } })

const fehler = []
page.on('console', (m) => {
  if (m.type() === 'error') fehler.push(`[console] ${m.text()}`)
})
page.on('pageerror', (e) => fehler.push(`[pageerror] ${e.message}`))

await page.goto(URL, { waitUntil: 'domcontentloaded' })
await page.waitForTimeout(1500)

const anzahl = await page.$$eval('.modell', (e) => e.length)
console.log(`Modelle in der Liste: ${anzahl}`)

const klick = (sel, i = 0) =>
  page.evaluate(([s, n]) => document.querySelectorAll(s)[n]?.click(), [sel, i])

for (let i = 0; i < anzahl; i++) {
  const vorher = fehler.length
  await klick('.modell', i)
  await page.waitForTimeout(900) // Aufbau + einige Animationsframes

  const stand = await page.evaluate(() => ({
    titel: document.querySelector('.modell-kopf h2')?.textContent ?? '?',
    ebenen: document.querySelectorAll('.layer').length,
    labels: document.querySelectorAll('.scene-label').length,
  }))

  // Alle vier Textbereiche des Infopanels rendern lassen
  const tabs = await page.$$eval('.tab', (e) => e.length)
  for (let k = 0; k < tabs; k++) {
    await klick('.tab', k)
    await page.waitForTimeout(40)
  }
  await klick('.tab', 0)

  // Erste Ebene aus- und wieder einschalten
  await klick('.layer', 0)
  await page.waitForTimeout(120)
  await klick('.layer', 0)

  const neu = fehler.length - vorher
  console.log(
    `${String(i + 1).padStart(2)}. ${stand.titel.padEnd(34)} Ebenen:${String(stand.ebenen).padStart(2)}` +
      `  Labels:${String(stand.labels).padStart(3)}  ${neu ? '❌ ' + neu + ' Fehler' : '✓'}`,
  )
}

// Tastatursteuerung prüfen
for (const taste of ['Space', 'r', 'l', 'i', 'ArrowDown', 'ArrowUp']) {
  await page.keyboard.press(taste)
  await page.waitForTimeout(120)
}

// Suche prüfen
await page.fill('.suche input', 'Gegenstrom')
await page.waitForTimeout(300)
const suchTreffer = await page.$$eval('.modell', (e) => e.length)
console.log(`\nSuche "Gegenstrom" → ${suchTreffer} Treffer`)

await page.fill('.suche input', 'Josephson')
await page.waitForTimeout(300)
console.log(`Suche "Josephson" → ${await page.$$eval('.modell', (e) => e.length)} Treffer`)

await page.fill('.suche input', '')
await page.waitForTimeout(300)

console.log(`\n--- Fehler gesamt: ${fehler.length} ---`)
fehler.slice(0, 25).forEach((f) => console.log(f))

await browser.close()
process.exit(fehler.length ? 1 : 0)
