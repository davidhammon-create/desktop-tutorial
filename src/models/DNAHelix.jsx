import React, { useCallback } from 'react'
import * as THREE from 'three'
import Three3DCanvas from '../components/Three3DCanvas'

export default function DNAHelix() {
  const setupScene = useCallback((scene, camera) => {
    const dnaGroup = new THREE.Group()

    // Create DNA helix structure
    const helixHeight = 8
    const helixRadius = 1.5
    const turns = 3
    const numSegments = 200

    // First strand
    const strand1Points = []
    const strand2Points = []

    for (let i = 0; i <= numSegments; i++) {
      const t = i / numSegments
      const angle = t * turns * Math.PI * 2
      const height = (t - 0.5) * helixHeight

      const x1 = Math.cos(angle) * helixRadius
      const z1 = Math.sin(angle) * helixRadius
      strand1Points.push(new THREE.Vector3(x1, height, z1))

      const x2 = Math.cos(angle + Math.PI) * helixRadius
      const z2 = Math.sin(angle + Math.PI) * helixRadius
      strand2Points.push(new THREE.Vector3(x2, height, z2))
    }

    // Create strand 1 (red)
    const strand1Geometry = new THREE.BufferGeometry().setFromPoints(strand1Points)
    const strand1Material = new THREE.LineBasicMaterial({ color: 0xff4444, linewidth: 3 })
    const strand1 = new THREE.Line(strand1Geometry, strand1Material)
    dnaGroup.add(strand1)

    // Create strand 2 (blue)
    const strand2Geometry = new THREE.BufferGeometry().setFromPoints(strand2Points)
    const strand2Material = new THREE.LineBasicMaterial({ color: 0x4444ff, linewidth: 3 })
    const strand2 = new THREE.Line(strand2Geometry, strand2Material)
    dnaGroup.add(strand2)

    // Create base pairs (connecting segments)
    const basePairCount = 20
    for (let i = 0; i < basePairCount; i++) {
      const idx = Math.floor((i / basePairCount) * numSegments)
      const point1 = strand1Points[idx]
      const point2 = strand2Points[idx]

      const pairGeometry = new THREE.BufferGeometry().setFromPoints([point1, point2])
      const pairMaterial = new THREE.LineBasicMaterial({ color: 0xffd700, linewidth: 2 })
      const pair = new THREE.Line(pairGeometry, pairMaterial)
      dnaGroup.add(pair)
    }

    // Add spheres to represent nucleotides
    for (let i = 0; i < numSegments; i += 8) {
      // Nucleotide on strand 1
      const nuc1Geometry = new THREE.SphereGeometry(0.2, 16, 16)
      const nuc1Material = new THREE.MeshStandardMaterial({
        color: 0xff6666,
        emissive: 0xff4444,
        emissiveIntensity: 0.4,
        metalness: 0.6,
        roughness: 0.4
      })
      const nuc1 = new THREE.Mesh(nuc1Geometry, nuc1Material)
      nuc1.position.copy(strand1Points[i])
      nuc1.castShadow = true
      dnaGroup.add(nuc1)

      // Nucleotide on strand 2
      const nuc2Geometry = new THREE.SphereGeometry(0.2, 16, 16)
      const nuc2Material = new THREE.MeshStandardMaterial({
        color: 0x6666ff,
        emissive: 0x4444ff,
        emissiveIntensity: 0.4,
        metalness: 0.6,
        roughness: 0.4
      })
      const nuc2 = new THREE.Mesh(nuc2Geometry, nuc2Material)
      nuc2.position.copy(strand2Points[i])
      nuc2.castShadow = true
      dnaGroup.add(nuc2)
    }

    scene.add(dnaGroup)

    // Animation
    let time = 0
    const animate = () => {
      time += 0.005
      dnaGroup.rotation.z += 0.005
      dnaGroup.position.y = Math.sin(time * 0.5) * 0.3

      requestAnimationFrame(animate)
    }
    animate()
  }, [])

  return <Three3DCanvas setupScene={setupScene} />
}
