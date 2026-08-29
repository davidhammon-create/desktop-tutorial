import quantencomputer from './physik/quantencomputer'
import orbitale from './physik/orbitale'
import kristallgitter from './physik/kristallgitter'
import emwelle from './physik/emwelle'

import benzol from './chemie/benzol'
import hybridisierung from './chemie/hybridisierung'
import ionengitter from './chemie/ionengitter'
import cyclohexan from './chemie/cyclohexan'

import dna from './biologie/dna'
import zelle from './biologie/zelle'
import protein from './biologie/protein'
import atmungskette from './biologie/atmungskette'

import herz from './medizin/herz'
import nephron from './medizin/nephron'
import synapse from './medizin/synapse'
import alveole from './medizin/alveole'

export const FACHBEREICHE = [
  { id: 'physik', name: 'Physik', icon: '⚛', farbe: '#5b8def' },
  { id: 'chemie', name: 'Chemie', icon: '⬡', farbe: '#9775fa' },
  { id: 'biologie', name: 'Biologie', icon: '🧬', farbe: '#51cf66' },
  { id: 'medizin', name: 'Medizin', icon: '🫀', farbe: '#ff6b6b' },
]

export const MODELLE = [
  quantencomputer,
  orbitale,
  kristallgitter,
  emwelle,
  benzol,
  hybridisierung,
  ionengitter,
  cyclohexan,
  dna,
  zelle,
  protein,
  atmungskette,
  herz,
  nephron,
  synapse,
  alveole,
]

export function modellNach(id) {
  return MODELLE.find((m) => m.id === id)
}

/** Volltextsuche über Name, Kurzbeschreibung und Fachtexte. */
export function sucheModelle(begriff) {
  const q = begriff.trim().toLowerCase()
  if (!q) return MODELLE
  return MODELLE.filter((m) => {
    const haystack = [
      m.name,
      m.tagline,
      m.info?.summary,
      ...(m.info?.sections ?? []).flatMap((s) => [s.title, ...(s.body ?? [])]),
      ...(m.info?.facts ?? []).map((f) => `${f.k} ${f.v}`),
    ]
      .join(' ')
      .toLowerCase()
    return haystack.includes(q)
  })
}
