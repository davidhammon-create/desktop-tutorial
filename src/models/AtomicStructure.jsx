import React, { useCallback } from 'react'
import * as THREE from 'three'
import Three3DCanvas from '../components/Three3DCanvas'

export default function AtomicStructure() {
  const setupScene = useCallback((scene, camera) => {
    const atomGroup = new THREE.Group()

    // Nucleus (protons and neutrons)
    const nucleusGeometry = new THREE.SphereGeometry(0.8, 32, 32)
    const nucleusMaterial = new THREE.MeshStandardMaterial({
      color: 0xff4444,
      emissive: 0xff4444,
      emissiveIntensity: 0.6,
      metalness: 0.8,
      roughness: 0.2
    })
    const nucleus = new THREE.Mesh(nucleusGeometry, nucleusMaterial)
    nucleus.castShadow = true
    atomGroup.add(nucleus)

    // Electron shells (3 orbital rings)
    const shellRadii = [2.5, 4, 5.5]
    const shellColors = [0x00ff88, 0x4facfe, 0xffd700]

    shellRadii.forEach((radius, shellIdx) => {
      // Create shell ring (torus)
      const torusGeometry = new THREE.TorusGeometry(radius, 0.15, 8, 32)
      const torusMaterial = new THREE.MeshStandardMaterial({
        color: shellColors[shellIdx],
        metalness: 0.5,
        roughness: 0.5
      })
      const torus = new THREE.Mesh(torusGeometry, torusMaterial)
      torus.castShadow = true
      atomGroup.add(torus)

      // Add electrons on this shell
      const electronCount = 2 + shellIdx * 3
      for (let i = 0; i < electronCount; i++) {
        const electronGeometry = new THREE.SphereGeometry(0.2, 16, 16)
        const electronMaterial = new THREE.MeshStandardMaterial({
          color: shellColors[shellIdx],
          emissive: shellColors[shellIdx],
          emissiveIntensity: 0.7,
          metalness: 0.9,
          roughness: 0.1
        })
        const electron = new THREE.Mesh(electronGeometry, electronMaterial)
        electron.userData.orbitRadius = radius
        electron.userData.orbitSpeed = 0.01 + shellIdx * 0.003
        electron.userData.orbitOffset = (i / electronCount) * Math.PI * 2
        electron.userData.shellIdx = shellIdx
        atomGroup.add(electron)
      }
    })

    scene.add(atomGroup)

    // Animation
    let time = 0
    const animate = () => {
      time += 0.01

      atomGroup.children.forEach((obj) => {
        if (obj.userData.orbitRadius) {
          const angle = time * obj.userData.orbitSpeed + obj.userData.orbitOffset
          obj.position.x = Math.cos(angle) * obj.userData.orbitRadius
          obj.position.y = Math.sin(angle * 0.7) * (obj.userData.orbitRadius * 0.3)
          obj.position.z = Math.sin(angle) * obj.userData.orbitRadius * 0.6
        }
      })

      nucleus.rotation.x += 0.001
      nucleus.rotation.y += 0.002

      requestAnimationFrame(animate)
    }
    animate()
  }, [])

  return <Three3DCanvas setupScene={setupScene} />
}
