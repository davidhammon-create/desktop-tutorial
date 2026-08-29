import React, { useCallback } from 'react'
import * as THREE from 'three'
import Three3DCanvas from '../components/Three3DCanvas'

export default function Molecule() {
  const setupScene = useCallback((scene, camera) => {
    const moleculeGroup = new THREE.Group()

    // Define atoms: [x, y, z, radius, color, label]
    const atoms = [
      { pos: [0, 0, 0], radius: 0.4, color: 0x000000, label: 'C' },       // Carbon center
      { pos: [1.5, 0, 0], radius: 0.3, color: 0xffffff, label: 'H' },     // Hydrogen
      { pos: [-1.5, 0, 0], radius: 0.3, color: 0xffffff, label: 'H' },    // Hydrogen
      { pos: [0, 1.5, 0], radius: 0.35, color: 0xff0000, label: 'O' },    // Oxygen
      { pos: [0, -1.5, 0], radius: 0.35, color: 0xff0000, label: 'O' },   // Oxygen
      { pos: [1.06, 1.06, 0.75], radius: 0.3, color: 0xffffff, label: 'H' }, // Hydrogen
      { pos: [-1.06, -1.06, 0.75], radius: 0.3, color: 0xffffff, label: 'H' }, // Hydrogen
    ]

    // Create atoms
    atoms.forEach((atom, idx) => {
      const geometry = new THREE.SphereGeometry(atom.radius, 32, 32)
      const material = new THREE.MeshStandardMaterial({
        color: atom.color,
        metalness: 0.3,
        roughness: 0.4,
        emissive: atom.color === 0x000000 ? 0x333333 : 0x000000,
        emissiveIntensity: 0.2
      })
      const mesh = new THREE.Mesh(geometry, material)
      mesh.position.set(...atom.pos)
      mesh.castShadow = true
      mesh.userData.orbitSpeed = 0.01 + idx * 0.002
      moleculeGroup.add(mesh)
    })

    // Draw bonds
    const bonds = [
      [0, 1], [0, 2], [0, 3], [0, 4], [3, 5], [4, 6]
    ]

    bonds.forEach(([from, to]) => {
      const fromAtom = atoms[from]
      const toAtom = atoms[to]
      const distance = Math.sqrt(
        Math.pow(toAtom.pos[0] - fromAtom.pos[0], 2) +
        Math.pow(toAtom.pos[1] - fromAtom.pos[1], 2) +
        Math.pow(toAtom.pos[2] - fromAtom.pos[2], 2)
      )

      const bondGeometry = new THREE.CylinderGeometry(0.08, 0.08, distance, 16)
      const bondMaterial = new THREE.MeshStandardMaterial({
        color: 0xc0a080,
        metalness: 0.5,
        roughness: 0.5
      })
      const bond = new THREE.Mesh(bondGeometry, bondMaterial)

      const midpoint = [
        (fromAtom.pos[0] + toAtom.pos[0]) / 2,
        (fromAtom.pos[1] + toAtom.pos[1]) / 2,
        (fromAtom.pos[2] + toAtom.pos[2]) / 2
      ]
      bond.position.set(...midpoint)
      bond.lookAt(toAtom.pos[0], toAtom.pos[1], toAtom.pos[2])
      bond.castShadow = true
      moleculeGroup.add(bond)
    })

    scene.add(moleculeGroup)

    // Animation
    let time = 0
    const animate = () => {
      time += 0.01
      moleculeGroup.rotation.x = Math.sin(time * 0.3) * 0.3
      moleculeGroup.rotation.y += 0.004
      moleculeGroup.rotation.z = Math.cos(time * 0.3) * 0.2

      requestAnimationFrame(animate)
    }
    animate()
  }, [])

  return <Three3DCanvas setupScene={setupScene} />
}
