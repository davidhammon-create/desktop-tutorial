import * as THREE from 'three'
import { CSS2DObject } from 'three/examples/jsm/renderers/CSS2DRenderer.js'

/**
 * Gemeinsame Bausteine für alle Modelle.
 * Konvention: 1 Szeneneinheit entspricht der im jeweiligen Modell dokumentierten
 * physikalischen Länge (z. B. 1 Einheit = 1 Å). Jedes Modell nennt seinen Maßstab.
 */

export const V = (x = 0, y = 0, z = 0) => new THREE.Vector3(x, y, z)

/** CPK-Farbschema (Corey–Pauling–Koltun), wie in der Strukturchemie üblich. */
export const CPK = {
  H: 0xf5f6fa,
  C: 0x3d4451,
  N: 0x3b5bdb,
  O: 0xe03131,
  P: 0xf59f00,
  S: 0xfcc419,
  Na: 0x9775fa,
  Cl: 0x51cf66,
  Fe: 0xe8590c,
  Ca: 0x40c057,
  Mg: 0x82c91e,
  Cu: 0xd9480f,
}

/** Kovalente Radien in pm (Cordero et al. 2008) – für maßstäbliche Kugeln. */
export const R_COV = { H: 31, C: 76, N: 71, O: 66, P: 107, S: 105 }

export const UI = {
  accent: 0x5b8def,
  accent2: 0x9775fa,
  warm: 0xff922b,
  hot: 0xe03131,
  cool: 0x22b8cf,
  green: 0x51cf66,
  metal: 0x8d99ae,
  dark: 0x1b1f2a,
}

export function std(color, o = {}) {
  return new THREE.MeshStandardMaterial({
    color,
    metalness: 0.2,
    roughness: 0.45,
    ...o,
  })
}

export function metal(color, o = {}) {
  return std(color, { metalness: 0.85, roughness: 0.25, ...o })
}

export function glow(color, intensity = 0.6, o = {}) {
  return std(color, { emissive: color, emissiveIntensity: intensity, ...o })
}

export function glass(color, opacity = 0.18, o = {}) {
  return std(color, {
    transparent: true,
    opacity,
    roughness: 0.1,
    metalness: 0,
    side: THREE.DoubleSide,
    depthWrite: false,
    ...o,
  })
}

/** Kugel an Position; Radius in Szeneneinheiten. */
export function atom(position, radius, color, o = {}) {
  const m = new THREE.Mesh(
    new THREE.SphereGeometry(radius, o.segments ?? 32, o.segments ?? 24),
    o.material ?? std(color, o.mat ?? {}),
  )
  m.position.copy(Array.isArray(position) ? V(...position) : position)
  m.castShadow = true
  m.receiveShadow = true
  return m
}

/** Zylinder korrekt zwischen zwei Punkten ausgerichtet (Bindung, Kabel, Faser). */
export function bond(a, b, o = {}) {
  const from = Array.isArray(a) ? V(...a) : a
  const to = Array.isArray(b) ? V(...b) : b
  const dir = new THREE.Vector3().subVectors(to, from)
  const len = dir.length()
  if (len < 1e-6) return new THREE.Object3D()
  const r = o.radius ?? 0.08
  const mesh = new THREE.Mesh(
    new THREE.CylinderGeometry(o.radiusTop ?? r, r, len, o.segments ?? 16, 1, o.open ?? false),
    o.material ?? std(o.color ?? UI.metal, o.mat ?? {}),
  )
  mesh.position.copy(from).addScaledVector(dir, 0.5)
  mesh.quaternion.setFromUnitVectors(V(0, 1, 0), dir.normalize())
  mesh.castShadow = true
  return mesh
}

/** Doppel-/Dreifachbindung: n parallel versetzte Zylinder. */
export function multiBond(a, b, n = 2, o = {}) {
  const from = Array.isArray(a) ? V(...a) : a
  const to = Array.isArray(b) ? V(...b) : b
  const axis = new THREE.Vector3().subVectors(to, from).normalize()
  let perp = new THREE.Vector3(0, 1, 0).cross(axis)
  if (perp.lengthSq() < 1e-6) perp = new THREE.Vector3(1, 0, 0).cross(axis)
  perp.normalize().multiplyScalar(o.gap ?? 0.12)
  const g = new THREE.Group()
  for (let i = 0; i < n; i++) {
    const t = n === 1 ? 0 : i - (n - 1) / 2
    const off = perp.clone().multiplyScalar(t)
    g.add(bond(from.clone().add(off), to.clone().add(off), { ...o, radius: o.radius ?? 0.05 }))
  }
  return g
}

/** Glatter Schlauch entlang einer Punktfolge (Rückgrat, Gefäß, Tubulus). */
export function tube(points, radius, material, o = {}) {
  const curve = new THREE.CatmullRomCurve3(
    points.map((p) => (Array.isArray(p) ? V(...p) : p)),
    o.closed ?? false,
    o.curveType ?? 'catmullrom',
    o.tension ?? 0.5,
  )
  const mesh = new THREE.Mesh(
    new THREE.TubeGeometry(curve, o.tubularSegments ?? Math.max(64, points.length * 8), radius, o.radialSegments ?? 16, o.closed ?? false),
    material,
  )
  mesh.castShadow = true
  mesh.userData.curve = curve
  return mesh
}

/** Pfeil mit Schaft und Spitze (Vektorfelder, Flussrichtungen). */
export function arrow(from, to, color, o = {}) {
  const a = Array.isArray(from) ? V(...from) : from
  const b = Array.isArray(to) ? V(...to) : to
  const dir = new THREE.Vector3().subVectors(b, a)
  const len = dir.length()
  if (len < 1e-6) return new THREE.Object3D()
  const headLen = Math.min(o.headLength ?? len * 0.28, len * 0.6)
  const shaftR = o.radius ?? len * 0.035
  const g = new THREE.Group()
  const mat = o.material ?? std(color, { emissive: color, emissiveIntensity: 0.25 })
  const shaft = new THREE.Mesh(new THREE.CylinderGeometry(shaftR, shaftR, len - headLen, 12), mat)
  shaft.position.set(0, (len - headLen) / 2, 0)
  const head = new THREE.Mesh(new THREE.ConeGeometry(shaftR * (o.headWidth ?? 2.4), headLen, 16), mat)
  head.position.set(0, len - headLen / 2, 0)
  g.add(shaft, head)
  g.position.copy(a)
  g.quaternion.setFromUnitVectors(V(0, 1, 0), dir.normalize())
  return g
}

/** Beschriftung, die als HTML über der Szene schwebt und mit dem Modell mitdreht. */
export function label(text, position, tone = 'default') {
  const el = document.createElement('div')
  el.className = `scene-label tone-${tone}`
  el.textContent = text
  const obj = new CSS2DObject(el)
  obj.position.copy(Array.isArray(position) ? V(...position) : position)
  obj.userData.isLabel = true
  obj.center.set(0.5, 1)
  return obj
}

/** Dünner Verbindungsstrich von einem Bauteil zu seiner Beschriftung. */
export function leader(from, to, color = 0x8d99ae) {
  const geo = new THREE.BufferGeometry().setFromPoints([
    Array.isArray(from) ? V(...from) : from,
    Array.isArray(to) ? V(...to) : to,
  ])
  return new THREE.Line(geo, new THREE.LineBasicMaterial({ color, transparent: true, opacity: 0.55 }))
}

/** Ring / Torus, z. B. für Orbitalbahnen oder Membranöffnungen. */
export function ring(radius, thickness, color, o = {}) {
  return new THREE.Mesh(
    new THREE.TorusGeometry(radius, thickness, o.radialSegments ?? 16, o.tubularSegments ?? 96, o.arc ?? Math.PI * 2),
    o.material ?? std(color, o.mat ?? {}),
  )
}

/** Punktwolke aus Positionen + Farben (Orbitale, Konzentrationsfelder). */
export function pointCloud(positions, colors, size = 0.06, o = {}) {
  const geo = new THREE.BufferGeometry()
  geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3))
  geo.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3))
  return new THREE.Points(
    geo,
    new THREE.PointsMaterial({
      size,
      vertexColors: true,
      transparent: true,
      opacity: o.opacity ?? 0.75,
      depthWrite: false,
      blending: o.blending ?? THREE.AdditiveBlending,
      sizeAttenuation: true,
    }),
  )
}

/** Deterministischer PRNG – reproduzierbare "Zufalls"-Verteilungen. */
export function rng(seed = 1) {
  let s = seed >>> 0
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0
    return s / 4294967296
  }
}

/** Gleichmäßig verteilte Richtungen auf der Kugel (Fibonacci-Spirale). */
export function fibonacciSphere(n, radius = 1) {
  const pts = []
  const phi = Math.PI * (3 - Math.sqrt(5))
  for (let i = 0; i < n; i++) {
    const y = 1 - (i / (n - 1 || 1)) * 2
    const r = Math.sqrt(Math.max(0, 1 - y * y))
    const th = phi * i
    pts.push(V(Math.cos(th) * r * radius, y * radius, Math.sin(th) * r * radius))
  }
  return pts
}

/** Halber Orbitallappen (Keulenform) – für Hybrid- und p-Orbitale. */
export function lobe(length, width, color, o = {}) {
  const pts = []
  const steps = 24
  for (let i = 0; i <= steps; i++) {
    const t = i / steps
    const r = Math.sin(Math.PI * t) ** 0.85 * width * (0.35 + 0.65 * t)
    pts.push(new THREE.Vector2(Math.max(0.001, r), t * length))
  }
  const geo = new THREE.LatheGeometry(pts, o.segments ?? 32)
  return new THREE.Mesh(geo, o.material ?? std(color, { transparent: true, opacity: o.opacity ?? 0.45, roughness: 0.3, side: THREE.DoubleSide, ...(o.mat ?? {}) }))
}

/**
 * Ebene Lipiddoppelschicht als Ausschnitt (Kopfgruppen + Fettsäureschwänze).
 *
 * Eine Doppelschicht besteht schnell aus mehreren tausend Lipiden. Als einzelne
 * Meshes wären das ebenso viele Draw Calls – deshalb zwei InstancedMesh-Objekte
 * (Köpfe, Schwänze), die die gesamte Schicht in zwei Draw Calls zeichnen.
 */
export function lipidBilayer(width, depth, o = {}) {
  const g = new THREE.Group()
  const spacing = o.spacing ?? 0.55
  const headR = o.headRadius ?? 0.22
  const half = o.thickness ?? 1.1
  const tailLen = half - 0.08

  const positionen = []
  for (let x = -width / 2; x <= width / 2 + 1e-9; x += spacing) {
    for (let z = -depth / 2; z <= depth / 2 + 1e-9; z += spacing) {
      positionen.push([x, z, 1], [x, z, -1])
    }
  }

  const koepfe = new THREE.InstancedMesh(
    new THREE.SphereGeometry(headR, 10, 8),
    std(o.headColor ?? 0x4dabf7, { roughness: 0.35 }),
    positionen.length,
  )
  const schwaenze = new THREE.InstancedMesh(
    new THREE.CylinderGeometry(0.05, 0.05, tailLen, 6),
    std(o.tailColor ?? 0xf1c40f, { roughness: 0.6, transparent: true, opacity: 0.75 }),
    positionen.length,
  )

  const m = new THREE.Matrix4()
  positionen.forEach(([x, z, sign], i) => {
    m.makeTranslation(x, sign * half, z)
    koepfe.setMatrixAt(i, m)
    // Schwanz reicht von der Kopfgruppe bis zur Mittelebene
    m.makeTranslation(x, sign * (0.08 + tailLen / 2), z)
    schwaenze.setMatrixAt(i, m)
  })
  koepfe.instanceMatrix.needsUpdate = true
  schwaenze.instanceMatrix.needsUpdate = true
  koepfe.castShadow = true

  g.add(koepfe, schwaenze)
  return g
}

/** Alle Geometrien/Materialien eines Teilbaums freigeben (Modellwechsel). */
export function disposeTree(root) {
  root.traverse((obj) => {
    if (obj.geometry) obj.geometry.dispose()
    if (obj.material) {
      const mats = Array.isArray(obj.material) ? obj.material : [obj.material]
      mats.forEach((m) => {
        Object.values(m).forEach((v) => {
          if (v && v.isTexture) v.dispose()
        })
        m.dispose()
      })
    }
    if (obj.element && obj.element.parentNode) obj.element.parentNode.removeChild(obj.element)
  })
}

export { THREE }
