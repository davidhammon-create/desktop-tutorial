import React, { useEffect, useRef } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { CSS2DRenderer } from 'three/examples/jsm/renderers/CSS2DRenderer.js'
import { disposeTree } from './lib'

/**
 * Rendert genau ein Modell. Baut die Szene beim Modellwechsel vollständig neu auf
 * und gibt die alte Szene frei (Geometrien, Materialien, Label-DOM).
 */
export default function Viewer({ model, playing, showLabels, layers, speed, resetSignal, onBuilt }) {
  const hostRef = useRef(null)
  const stateRef = useRef({})

  // --- Einmaliges Setup von Renderer, Kamera, Licht, Controls ------------------
  useEffect(() => {
    const host = hostRef.current
    const scene = new THREE.Scene()
    scene.background = new THREE.Color(0x0a0d16)
    scene.fog = new THREE.FogExp2(0x0a0d16, 0.012)

    const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 4000)
    camera.position.set(0, 6, 24)

    const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' })
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.toneMapping = THREE.ACESFilmicToneMapping
    renderer.toneMappingExposure = 1.05
    host.appendChild(renderer.domElement)

    const labelRenderer = new CSS2DRenderer()
    labelRenderer.domElement.className = 'label-layer'
    host.appendChild(labelRenderer.domElement)

    const controls = new OrbitControls(camera, renderer.domElement)
    controls.enableDamping = true
    controls.dampingFactor = 0.06
    controls.rotateSpeed = 0.85
    controls.zoomSpeed = 0.9
    controls.panSpeed = 0.7
    controls.minDistance = 1.5
    controls.maxDistance = 900

    scene.add(new THREE.HemisphereLight(0xbcd4ff, 0x1a1a26, 0.85))
    const key = new THREE.DirectionalLight(0xffffff, 1.5)
    key.position.set(14, 20, 12)
    key.castShadow = true
    key.shadow.mapSize.set(1024, 1024)
    key.shadow.camera.near = 1
    key.shadow.camera.far = 120
    key.shadow.camera.left = -35
    key.shadow.camera.right = 35
    key.shadow.camera.top = 35
    key.shadow.camera.bottom = -35
    scene.add(key)
    const fill = new THREE.DirectionalLight(0x88aaff, 0.5)
    fill.position.set(-16, -6, -12)
    scene.add(fill)
    const rim = new THREE.PointLight(0x9775fa, 0.7, 200)
    rim.position.set(-14, 12, -18)
    scene.add(rim)

    const clock = new THREE.Clock()
    Object.assign(stateRef.current, { scene, camera, renderer, labelRenderer, controls, clock, host })

    const resize = () => {
      const w = host.clientWidth || 1
      const h = host.clientHeight || 1
      camera.aspect = w / h
      camera.updateProjectionMatrix()
      renderer.setSize(w, h)
      labelRenderer.setSize(w, h)
    }
    resize()
    const ro = new ResizeObserver(resize)
    ro.observe(host)

    let frame
    const loop = () => {
      frame = requestAnimationFrame(loop)
      const st = stateRef.current
      const dt = clock.getDelta()
      if (st.playing && st.built?.update) {
        st.time += dt * (st.speed ?? 1)
        try {
          st.built.update(st.time, dt * (st.speed ?? 1))
        } catch (err) {
          console.error('Animationsfehler im Modell:', err)
          st.built.update = null
        }
      }
      controls.update()
      renderer.render(scene, camera)
      labelRenderer.render(scene, camera)
    }
    st_init(stateRef.current)
    loop()

    return () => {
      cancelAnimationFrame(frame)
      ro.disconnect()
      controls.dispose()
      if (stateRef.current.root) disposeTree(stateRef.current.root)
      renderer.dispose()
      host.removeChild(renderer.domElement)
      host.removeChild(labelRenderer.domElement)
    }
  }, [])

  // --- Modellwechsel ----------------------------------------------------------
  useEffect(() => {
    const st = stateRef.current
    if (!st.scene || !model) return

    if (st.root) {
      st.scene.remove(st.root)
      disposeTree(st.root)
      st.root = null
      st.built = null
    }

    const root = new THREE.Group()
    let built
    try {
      built = model.build() ?? {}
    } catch (err) {
      console.error(`Modell "${model.id}" konnte nicht gebaut werden:`, err)
      built = { group: new THREE.Group() }
    }
    root.add(built.group)
    st.scene.add(root)
    st.root = root
    st.built = built
    st.time = 0

    const view = built.camera ?? {}
    const target = new THREE.Vector3(...(view.target ?? [0, 0, 0]))
    st.home = {
      position: new THREE.Vector3(...(view.position ?? [0, 8, 28])),
      target,
    }
    st.camera.position.copy(st.home.position)
    st.controls.target.copy(target)
    st.controls.update()

    onBuilt?.({
      layers: (built.layers ?? []).map((l) => ({ id: l.id, name: l.name, on: l.on !== false })),
      hasAnimation: typeof built.update === 'function',
    })

    return () => {}
  }, [model])

  // --- Steuerflags ohne Neuaufbau übernehmen ----------------------------------
  useEffect(() => {
    stateRef.current.playing = playing
    stateRef.current.speed = speed
  }, [playing, speed])

  useEffect(() => {
    const st = stateRef.current
    if (!st.root) return
    st.root.traverse((o) => {
      if (o.userData.isLabel) o.visible = showLabels
    })
  }, [showLabels, model])

  useEffect(() => {
    const st = stateRef.current
    if (!st.built?.layers) return
    st.built.layers.forEach((layer) => {
      const on = layers?.[layer.id]
      const visible = on === undefined ? layer.on !== false : on
      layer.objects?.forEach((o) => {
        o.visible = visible
      })
    })
  }, [layers, model])

  useEffect(() => {
    const st = stateRef.current
    if (!st.home || resetSignal === undefined) return
    st.camera.position.copy(st.home.position)
    st.controls.target.copy(st.home.target)
    st.controls.update()
    st.time = 0
  }, [resetSignal])

  return <div className="viewer-canvas" ref={hostRef} />
}

function st_init(st) {
  st.playing = true
  st.speed = 1
  st.time = 0
}
