// Subdued, monochrome law-firm aesthetic ? Apple macOS style
export const T = {
  bg: '#f5f5f7',
  surface: '#ffffff',
  raised: '#fafafa',
  card: '#ffffff',
  border: 'rgba(0,0,0,0.06)',
  borderStrong: 'rgba(0,0,0,0.12)',
  text: '#1d1d1f',
  textSecondary: '#6e6e73',
  dim: '#8e8e93',
  muted: '#e5e5ea',
  // Functional colors ? very muted, only used for scores/status
  own: '#48484a',
  ownDim: 'rgba(72,72,74,0.06)',
  opp: '#636366',
  oppDim: 'rgba(99,99,102,0.06)',
  green: '#4a7c59',
  orange: '#8b7355',
  red: '#8b4553',
  blue: '#48484a',
  purple: '#636366',
  teal: '#6e7b8b',
  accent: '#1d1d1f',
  gold: '#86868b',
  goldLight: '#1d1d1f',
  goldDim: 'rgba(0,0,0,0.03)',
  ink: '#f5f5f7',
};
export const mono = "'SF Mono', 'DM Mono', 'Menlo', monospace";
export const serif = "'Georgia', 'Times New Roman', serif";
export const sans = "'SF Pro Text', -apple-system, 'Helvetica Neue', sans-serif";
export const ecol = (t: string) => t === 'exclude' ? T.red : t === 'weakens' ? T.orange : T.green;
export const scol = (s: number) => s >= 65 ? T.green : s >= 40 ? T.orange : T.red;
export const rcol = (r: string) => r === 'Richter' ? T.textSecondary : r === 'Zeuge' ? T.dim : T.textSecondary;
// Damage level colors
export const damageLevelColor = (level: string) => {
  if (level === 'high') return T.red;
  if (level === 'medium') return T.orange;
  return T.green;
};
// Role badge styles ? subdued
export const roleBadge = (classification: string) => {
  switch (classification) {
    case 'Feind': return { bg: 'rgba(139,69,83,0.08)', color: T.red, label: 'Feind' };
    case 'Bekannt': return { bg: 'rgba(139,115,85,0.08)', color: T.orange, label: 'Bekannt' };
    case 'Neutral': return { bg: 'rgba(74,124,89,0.08)', color: T.green, label: 'Neutral' };
    default: return { bg: 'rgba(72,72,74,0.08)', color: T.textSecondary, label: classification };
  }
};
