export type ArgumentType = 'claim' | 'evidence' | 'counterargument' | 'rebuttal' | 'premise' | 'frist' | 'risiko' | 'chance' | 'problem' | 'vorteil';
export type RelationType = 'support' | 'attack' | 'neutral' | 'causal';
export type ArgumentStrength = 1 | 2 | 3 | 4 | 5;
export interface NodeParagraph {
  id: string;
  text: string;
}
export interface NodeFileLink {
  id: string;
  name: string;
  url: string;
}
export interface ArgumentNode {
  id: string;
  type: ArgumentType;
  title: string;
  description: string;
  strength: ArgumentStrength;
  x: number;
  y: number;
  caseReference?: string;
  legalBasis?: string;
  paragraphs: NodeParagraph[];
  fileLinks: NodeFileLink[];
  createdAt: Date;
  side?: 'own' | 'opp'; // for graph: which party
}
export interface ArgumentEdge {
  id: string;
  source: string;
  target: string;
  relation: RelationType;
  label?: string;
}
export interface GraphState {
  nodes: ArgumentNode[];
  edges: ArgumentEdge[];
  selectedNodeId: string | null;
  zoom: number;
  panX: number;
  panY: number;
}
export const ARGUMENT_TYPE_CONFIG: Record<ArgumentType, { label: string; icon: string; color: string }> = {
  claim: { label: 'Claim', icon: 'Scale', color: 'hsl(220, 65%, 38%)' },
  evidence: { label: 'Beweis', icon: 'FileText', color: 'hsl(152, 60%, 36%)' },
  counterargument: { label: 'Gegenargument', icon: 'ShieldAlert', color: 'hsl(0, 72%, 51%)' },
  rebuttal: { label: 'Erwiderung', icon: 'Reply', color: 'hsl(30, 80%, 45%)' },
  premise: { label: 'Prämisse', icon: 'BookOpen', color: 'hsl(260, 50%, 48%)' },
  frist: { label: 'Frist', icon: 'Clock', color: 'hsl(40, 90%, 45%)' },
  risiko: { label: 'Risiko', icon: 'AlertTriangle', color: 'hsl(0, 80%, 50%)' },
  chance: { label: 'Chance', icon: 'TrendingUp', color: 'hsl(152, 70%, 35%)' },
  problem: { label: 'Problem', icon: 'AlertCircle', color: 'hsl(15, 80%, 48%)' },
  vorteil: { label: 'Vorteil', icon: 'ThumbsUp', color: 'hsl(200, 70%, 40%)' },
};
export const RELATION_CONFIG: Record<RelationType, { label: string; color: string; dash: string }> = {
  support: { label: 'Stützt', color: 'hsl(152, 60%, 36%)', dash: '' },
  attack: { label: 'Greift an', color: 'hsl(0, 72%, 51%)', dash: '8,4' },
  neutral: { label: 'Bezug', color: 'hsl(220, 10%, 46%)', dash: '4,4' },
  causal: { label: 'Kausal', color: 'hsl(190, 80%, 40%)', dash: '' },
};
