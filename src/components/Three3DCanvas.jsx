import React, { useEffect, useRef } from 'react'
import * as THREE from 'three'

export default function Three3DCanvas({ setupScene }) {
  const containerRef = useRef(null)
  const sceneRef = useRef(null)
  const cameraRef = useRef(null)
  const rendererRef = useRef(null)
  const controlsRef = useRef({
    isDragging: false,
    previousMousePosition: { x: 0, y: 0 },
    rotation: { x: 0, y: 0 }
  })

  useEffect(() => {
    if (!containerRef.current) return

    // Scene Setup
    const scene = new THREE.Scene()
    scene.background = new THREE.Color(0x1a1a2e)
    sceneRef.current = scene

    // Camera
    const width = containerRef.current.clientWidth
    const height = containerRef.current.clientHeight
    const camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000)
    camera.position.z = 5
    cameraRef.current = camera

    // Renderer
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true })
    renderer.setSize(width, height)
    renderer.setPixelRatio(window.devicePixelRatio)
    renderer.shadowMap.enabled = true
    containerRef.current.appendChild(renderer.domElement)
    rendererRef.current = renderer

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6)
    scene.add(ambientLight)

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8)
    directionalLight.position.set(10, 10, 10)
    directionalLight.castShadow = true
    scene.add(directionalLight)

    const pointLight = new THREE.PointLight(0x667eea, 0.5)
    pointLight.position.set(-10, 5, 10)
    scene.add(pointLight)

    // Setup user's scene
    setupScene(scene, camera)

    // Mouse Controls
    const controls = controlsRef.current

    const onMouseDown = (e) => {
      controls.isDragging = true
      controls.previousMousePosition = { x: e.clientX, y: e.clientY }
    }

    const onMouseMove = (e) => {
      if (!controls.isDragging) return

      const deltaX = e.clientX - controls.previousMousePosition.x
      const deltaY = e.clientY - controls.previousMousePosition.y

      controls.rotation.y += deltaX * 0.005
      controls.rotation.x += deltaY * 0.005

      controls.previousMousePosition = { x: e.clientX, y: e.clientY }

      // Apply rotation to all objects in scene
      scene.children.forEach(obj => {
        if (obj !== ambientLight && obj !== directionalLight && obj !== pointLight) {
          obj.rotation.y = controls.rotation.y
          obj.rotation.x = controls.rotation.x
        }
      })
    }

    const onMouseUp = () => {
      controls.isDragging = false
    }

    const onWheel = (e) => {
      e.preventDefault()
      const zoomSpeed = 0.1
      const zoomDirection = e.deltaY > 0 ? 1 : -1
      camera.position.z += zoomDirection * zoomSpeed
      camera.position.z = Math.max(1, Math.min(20, camera.position.z))
    }

    const onKeyDown = (e) => {
      if (e.key === 'r' || e.key === 'R') {
        controls.rotation = { x: 0, y: 0 }
        camera.position.z = 5
        scene.children.forEach(obj => {
          if (obj !== ambientLight && obj !== directionalLight && obj !== pointLight) {
            obj.rotation.x = 0
            obj.rotation.y = 0
          }
        })
      }
    }

    renderer.domElement.addEventListener('mousedown', onMouseDown)
    renderer.domElement.addEventListener('mousemove', onMouseMove)
    renderer.domElement.addEventListener('mouseup', onMouseUp)
    renderer.domElement.addEventListener('wheel', onWheel, { passive: false })
    window.addEventListener('keydown', onKeyDown)

    // Handle window resize
    const onResize = () => {
      const newWidth = containerRef.current.clientWidth
      const newHeight = containerRef.current.clientHeight
      camera.aspect = newWidth / newHeight
      camera.updateProjectionMatrix()
      renderer.setSize(newWidth, newHeight)
    }

    window.addEventListener('resize', onResize)

    // Animation loop
    const animate = () => {
      requestAnimationFrame(animate)
      renderer.render(scene, camera)
    }
    animate()

    // Cleanup
    return () => {
      renderer.domElement.removeEventListener('mousedown', onMouseDown)
      renderer.domElement.removeEventListener('mousemove', onMouseMove)
      renderer.domElement.removeEventListener('mouseup', onMouseUp)
      renderer.domElement.removeEventListener('wheel', onWheel)
      window.removeEventListener('keydown', onKeyDown)
      window.removeEventListener('resize', onResize)
      renderer.dispose()
      containerRef.current?.removeChild(renderer.domElement)
    }
  }, [setupScene])

  return <div ref={containerRef} style={{ width: '100%', height: '100%' }} />
}
