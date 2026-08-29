import React, { useCallback } from 'react'
import * as THREE from 'three'
import Three3DCanvas from '../components/Three3DCanvas'

export default function QuantumComputer() {
  const setupScene = useCallback((scene, camera) => {
    // Main structure
    const computerGroup = new THREE.Group()

    // Base platform
    const baseGeometry = new THREE.BoxGeometry(8, 0.5, 8)
    const baseMaterial = new THREE.MeshStandardMaterial({ color: 0x1a1a2e, metalness: 0.8, roughness: 0.2 })
    const base = new THREE.Mesh(baseGeometry, baseMaterial)
    base.position.y = -2
    base.castShadow = true
    computerGroup.add(base)

    // Central cooling system (cylindrical structure)
    const coolingGeometry = new THREE.CylinderGeometry(1.5, 1.5, 3, 32)
    const coolingMaterial = new THREE.MeshStandardMaterial({ color: 0x4facfe, metalness: 0.7, roughness: 0.3 })
    const cooling = new THREE.Mesh(coolingGeometry, coolingMaterial)
    cooling.castShadow = true
    computerGroup.add(cooling)

    // Quantum processor unit (glowing cube)
    const processorGeometry = new THREE.BoxGeometry(1, 1, 1)
    const processorMaterial = new THREE.MeshStandardMaterial({
      color: 0x667eea,
      emissive: 0x667eea,
      emissiveIntensity: 0.5,
      metalness: 0.9,
      roughness: 0.1
    })
    const processor = new THREE.Mesh(processorGeometry, processorMaterial)
    processor.position.y = 1.5
    processor.castShadow = true
    computerGroup.add(processor)

    // Surrounding circuit boards (6 pieces around the center)
    for (let i = 0; i < 6; i++) {
      const angle = (i / 6) * Math.PI * 2
      const boardGeometry = new THREE.BoxGeometry(1.5, 2, 0.3)
      const boardMaterial = new THREE.MeshStandardMaterial({
        color: 0x764ba2,
        metalness: 0.6,
        roughness: 0.4
      })
      const board = new THREE.Mesh(boardGeometry, boardMaterial)
      board.position.x = Math.cos(angle) * 2.5
      board.position.z = Math.sin(angle) * 2.5
      board.rotation.y = angle
      board.castShadow = true
      computerGroup.add(board)

      // Add LED indicators
      const ledGeometry = new THREE.SphereGeometry(0.15, 16, 16)
      const ledMaterial = new THREE.MeshStandardMaterial({
        color: 0x00ff88,
        emissive: 0x00ff88,
        emissiveIntensity: 0.8
      })
      const led = new THREE.Mesh(ledGeometry, ledMaterial)
      led.position.copy(board.position)
      led.position.y = 1.2
      computerGroup.add(led)
    }

    // Cables/connections
    for (let i = 0; i < 6; i++) {
      const angle = (i / 6) * Math.PI * 2
      const startX = Math.cos(angle) * 2.5
      const startZ = Math.sin(angle) * 2.5

      const cableGeometry = new THREE.CylinderGeometry(0.1, 0.1, 2, 8)
      const cableMaterial = new THREE.MeshStandardMaterial({ color: 0xffd700 })
      const cable = new THREE.Mesh(cableGeometry, cableMaterial)
      cable.position.x = startX * 0.5
      cable.position.z = startZ * 0.5
      cable.position.y = 0.5
      cable.rotation.z = angle + Math.PI / 2
      cable.castShadow = true
      computerGroup.add(cable)
    }

    scene.add(computerGroup)

    // Animation
    let time = 0
    const animate = () => {
      time += 0.02
      processor.rotation.x += 0.003
      processor.rotation.y += 0.004
      processor.scale.x = 1 + Math.sin(time * 2) * 0.1
      processor.scale.y = 1 + Math.sin(time * 2) * 0.1
      processor.scale.z = 1 + Math.sin(time * 2) * 0.1

      // Pulse the LEDs
      computerGroup.children.forEach((obj, idx) => {
        if (obj.geometry?.type === 'SphereGeometry') {
          obj.material.emissiveIntensity = 0.5 + Math.sin(time + idx) * 0.5
        }
      })

      requestAnimationFrame(animate)
    }
    animate()
  }, [])

  return <Three3DCanvas setupScene={setupScene} />
}
