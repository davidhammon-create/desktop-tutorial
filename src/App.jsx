import React, { useState } from 'react'
import './App.css'
import QuantumComputer from './models/QuantumComputer'
import Molecule from './models/Molecule'
import AtomicStructure from './models/AtomicStructure'
import DNAHelix from './models/DNAHelix'

const MODELS = [
  {
    id: 'quantum-computer',
    name: 'Quantencomputer',
    description: 'Untersuche den Aufbau und die Funktionsweise eines modernen Quantencomputers',
    component: QuantumComputer,
    color: '#667eea'
  },
  {
    id: 'molecule',
    name: 'Molekül-Struktur',
    description: 'Erkunde komplexe Molekülstrukturen in 3D',
    component: Molecule,
    color: '#764ba2'
  },
  {
    id: 'atom',
    name: 'Atom-Struktur',
    description: 'Visualisiere die Elektronenorbitale und den Atomkern',
    component: AtomicStructure,
    color: '#f093fb'
  },
  {
    id: 'dna',
    name: 'DNA-Helix',
    description: 'Betrachte die Doppelhelix-Struktur der DNA',
    component: DNAHelix,
    color: '#4facfe'
  }
]

export default function App() {
  const [selectedModel, setSelectedModel] = useState(MODELS[0].id)
  const currentModel = MODELS.find(m => m.id === selectedModel)
  const ModelComponent = currentModel.component

  return (
    <div className="app">
      <header className="header">
        <h1>🧬 Interactive 3D Models</h1>
        <p>Interaktive Modelle für Studenten</p>
      </header>

      <div className="container">
        <aside className="sidebar">
          <div className="models-list">
            <h2>Modelle</h2>
            {MODELS.map(model => (
              <button
                key={model.id}
                className={`model-btn ${selectedModel === model.id ? 'active' : ''}`}
                onClick={() => setSelectedModel(model.id)}
                style={{
                  borderLeftColor: selectedModel === model.id ? model.color : 'transparent'
                }}
              >
                <span className="model-name">{model.name}</span>
                <span className="model-desc">{model.description}</span>
              </button>
            ))}
          </div>

          <div className="controls-info">
            <h3>Steuerung</h3>
            <ul>
              <li><strong>Maus drag:</strong> Rotation</li>
              <li><strong>Scroll:</strong> Zoom</li>
              <li><strong>Rechts-Klick:</strong> Pan</li>
              <li><strong>R-Taste:</strong> Zurücksetzen</li>
            </ul>
          </div>
        </aside>

        <main className="viewer">
          <div className="model-info">
            <h2>{currentModel.name}</h2>
            <p>{currentModel.description}</p>
          </div>
          <ModelComponent />
        </main>
      </div>

      <footer className="footer">
        <p>📚 Bildungswebsite für wissenschaftliche Visualisierung | Three.js + React</p>
      </footer>
    </div>
  )
}
