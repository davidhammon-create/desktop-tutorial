import React from 'react';
import { T, mono, sans, scol } from './theme';
export function Bar({ v, max = 100, color = T.text, h = 4 }: { v: number; max?: number; color?: string; h?: number }) {
  return (
    <div style={{ height: h, background: T.muted, flex: 1, position: 'relative', borderRadius: h }}>
      <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: `${Math.min(100, (v / max) * 100)}%`, background: color, borderRadius: h, transition: 'width 0.4s ease' }} />
    </div>
  );
}
export function Chip({ children, color, small, variant }: { children: React.ReactNode; color?: string; small?: boolean; variant?: 'filled' | 'outline' }) {
  const isFilled = variant === 'filled';
  const c = color || T.textSecondary;
  return (
    <span style={{
      fontFamily: sans, fontSize: small ? 11 : 12, fontWeight: 500,
      color: isFilled ? '#fff' : c,
      background: isFilled ? c : 'rgba(0,0,0,0.04)',
      border: isFilled ? 'none' : '1px solid rgba(0,0,0,0.06)',
      borderRadius: 6, padding: small ? '2px 8px' : '3px 10px',
      whiteSpace: 'nowrap', display: 'inline-block', lineHeight: 1.4,
      letterSpacing: '0.01em',
    }}>
      {children}
    </span>
  );
}
export function ScoreRing({ score, size = 48 }: { score: number; size?: number }) {
  const col = scol(score);
  const r = size / 2 - 4;
  const circ = 2 * Math.PI * r;
  const dash = (score / 100) * circ;
  return (
    <svg width={size} height={size} style={{ transform: 'rotate(-90deg)', flexShrink: 0 }}>
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={T.muted} strokeWidth={2} />
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={col} strokeWidth={2}
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round" style={{ transition: 'stroke-dasharray 0.6s ease' }} />
      <text x={size / 2} y={size / 2 + 1} textAnchor="middle" dominantBaseline="middle"
        style={{ transform: `rotate(90deg)`, transformOrigin: `${size / 2}px ${size / 2}px`, fontFamily: sans, fontSize: size * 0.28, fill: T.text, fontWeight: 600 }}>
        {score}
      </text>
    </svg>
  );
}
export function BigRing({ score, size = 120 }: { score: number; size?: number }) {
  const col = scol(score);
  const r = size / 2 - 8;
  const circ = 2 * Math.PI * r;
  const dash = (score / 100) * circ;
  return (
    <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={T.muted} strokeWidth={3} />
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={col} strokeWidth={3}
        strokeDasharray={`${dash} ${circ}`} strokeLinecap="round" style={{ transition: 'stroke-dasharray 0.8s ease' }} />
      <text x={size / 2} y={size / 2 - 4} textAnchor="middle" dominantBaseline="middle"
        style={{ transform: `rotate(90deg)`, transformOrigin: `${size / 2}px ${size / 2}px`, fontFamily: sans, fontSize: size * 0.26, fill: T.text, fontWeight: 700 }}>
        {score}%
      </text>
      <text x={size / 2} y={size / 2 + 14} textAnchor="middle" dominantBaseline="middle"
        style={{ transform: `rotate(90deg)`, transformOrigin: `${size / 2}px ${size / 2}px`, fontFamily: sans, fontSize: 10, fill: T.dim, letterSpacing: '0.05em' }}>
        Prognose
      </text>
    </svg>
  );
}
export function Btn({ children, onClick, active, color, small, destructive }: {
  children: React.ReactNode; onClick?: () => void; active?: boolean; color?: string; small?: boolean; destructive?: boolean;
}) {
  const finalColor = destructive ? T.red : (color || T.text);
  return (
    <button onClick={onClick} style={{
      fontFamily: sans, fontSize: small ? 13 : 14, fontWeight: 500,
      color: active ? '#fff' : finalColor,
      background: active ? finalColor : 'transparent',
      border: 'none', borderRadius: 8,
      padding: small ? '5px 14px' : '8px 18px',
      cursor: 'pointer', transition: 'all 0.2s',
      whiteSpace: 'nowrap',
      ...(active ? {} : { background: 'rgba(0,0,0,0.04)' }),
    }}>
      {children}
    </button>
  );
}
export function Panel({ children, style, onClick, onMouseEnter, onMouseLeave }: { children: React.ReactNode; style?: React.CSSProperties; onClick?: () => void; onMouseEnter?: React.MouseEventHandler; onMouseLeave?: React.MouseEventHandler }) {
  return (
    <div onClick={onClick} onMouseEnter={onMouseEnter} onMouseLeave={onMouseLeave} style={{
      background: T.surface, borderRadius: 12,
      padding: 20,
      ...style,
    }}>
      {children}
    </div>
  );
}
export function Label({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ fontFamily: sans, fontSize: 12, fontWeight: 600, color: T.dim, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 8 }}>
      {children}
    </div>
  );
}
export function SectionTitle({ children, icon }: { children: React.ReactNode; icon?: string }) {
  return (
    <h3 style={{ fontFamily: sans, fontSize: 17, fontWeight: 600, color: T.text, marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8, letterSpacing: '-0.01em' }}>
      {icon && <span style={{ fontSize: 15 }}>{icon}</span>}
      {children}
    </h3>
  );
}
export function CheckboxItem({ label, checked, onChange }: { label: string; checked?: boolean; onChange?: (v: boolean) => void }) {
  const isChecked = !!checked;
  return (
    <label
      style={{
        display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0',
        fontFamily: sans, fontSize: 14, color: T.text, cursor: 'pointer',
        userSelect: 'none',
      }}
      onClick={(e) => {
        e.preventDefault();
        onChange?.(!isChecked);
      }}
    >
      <div style={{
        width: 18, height: 18, borderRadius: 5, border: `1.5px solid ${isChecked ? T.text : T.muted}`,
        background: isChecked ? T.text : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'all 0.15s', flexShrink: 0,
      }}>
        {isChecked && <span style={{ color: '#fff', fontSize: 11, lineHeight: 1 }}>?</span>}
      </div>
      {label}
    </label>
  );
}
