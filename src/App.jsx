import React, { useState, useMemo, useRef, useEffect, forwardRef } from 'react';
import { BrowserRouter, Routes, Route, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { clsx } from 'clsx';
import * as LabelPrimitive from '@radix-ui/react-label';
import * as SliderPrimitive from '@radix-ui/react-slider';
import * as DialogPrimitive from '@radix-ui/react-dialog';
import * as TabsPrimitive from '@radix-ui/react-tabs';
import {
  ArrowLeft, Plus, ChevronDown, ChevronRight, TrendingUp, TrendingDown,
  BarChart3, Users, Camera, MessageSquare, BookOpen, FileText,
  Scale, Target, Info, Pencil, Trash2, Move, Zap
} from 'lucide-react';

// ─── Utility ────────────────────────────────────────────────────────────────

function createPageUrl(pageName) {
  return '/' + pageName.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
}

// ─── UI Components ───────────────────────────────────────────────────────────

const Button = forwardRef(function Button(
  { className, variant = 'default', size = 'default', children, ...props }, ref
) {
  const variants = {
    default:     'bg-blue-600 text-white hover:bg-blue-700',
    outline:     'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50',
    ghost:       'text-gray-700 hover:bg-gray-100',
    destructive: 'bg-red-600 text-white hover:bg-red-700',
    secondary:   'bg-gray-200 text-gray-900 hover:bg-gray-300',
  };
  const sizes = {
    default: 'h-10 px-4 py-2 text-sm',
    sm:      'h-9 px-3 text-xs',
    lg:      'h-11 px-8 text-base',
    icon:    'h-10 w-10',
  };
  return (
    <button
      ref={ref}
      className={clsx(
        'inline-flex items-center justify-center rounded-md font-medium transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500',
        'disabled:pointer-events-none disabled:opacity-50',
        variants[variant] ?? variants.default,
        sizes[size] ?? sizes.default,
        className
      )}
      {...props}
    >
      {children}
    </button>
  );
});

const Input = forwardRef(function Input({ className, ...props }, ref) {
  return (
    <input
      ref={ref}
      className={clsx(
        'flex h-10 w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm',
        'placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500',
        'disabled:cursor-not-allowed disabled:opacity-50',
        className
      )}
      {...props}
    />
  );
});

const Textarea = forwardRef(function Textarea({ className, ...props }, ref) {
  return (
    <textarea
      ref={ref}
      className={clsx(
        'flex min-h-[80px] w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm',
        'placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500',
        'disabled:cursor-not-allowed disabled:opacity-50',
        className
      )}
      {...props}
    />
  );
});

function Card({ className, children, ...props }) {
  return (
    <div className={clsx('rounded-lg border border-gray-200 bg-white shadow-sm', className)} {...props}>
      {children}
    </div>
  );
}
function CardHeader({ className, children, ...props }) {
  return <div className={clsx('flex flex-col space-y-1.5 p-6', className)} {...props}>{children}</div>;
}
function CardTitle({ className, children, ...props }) {
  return <h3 className={clsx('text-2xl font-semibold leading-none tracking-tight', className)} {...props}>{children}</h3>;
}
function CardContent({ className, children, ...props }) {
  return <div className={clsx('p-6 pt-0', className)} {...props}>{children}</div>;
}

function Badge({ className, variant = 'default', children, ...props }) {
  const variants = {
    default:     'bg-blue-600 text-white border-transparent',
    secondary:   'bg-gray-200 text-gray-800 border-transparent',
    destructive: 'bg-red-600 text-white border-transparent',
    outline:     'border border-gray-300 text-gray-700',
  };
  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors',
        variants[variant] ?? variants.default,
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
}

function Label({ className, ...props }) {
  return (
    <LabelPrimitive.Root
      className={clsx('text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70', className)}
      {...props}
    />
  );
}

function Slider({ className, ...props }) {
  return (
    <SliderPrimitive.Root className={clsx('relative flex w-full touch-none select-none items-center', className)} {...props}>
      <SliderPrimitive.Track className="relative h-2 w-full grow overflow-hidden rounded-full bg-gray-200">
        <SliderPrimitive.Range className="absolute h-full bg-blue-600" />
      </SliderPrimitive.Track>
      <SliderPrimitive.Thumb className="block h-5 w-5 rounded-full border-2 border-blue-600 bg-white shadow focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:pointer-events-none disabled:opacity-50" />
    </SliderPrimitive.Root>
  );
}

const Dialog = DialogPrimitive.Root;

function DialogOverlay({ className, ...props }) {
  return (
    <DialogPrimitive.Overlay
      className={clsx('fixed inset-0 z-50 bg-black/50 backdrop-blur-sm', className)}
      {...props}
    />
  );
}
function DialogContent({ className, children, ...props }) {
  return (
    <DialogPrimitive.Portal>
      <DialogOverlay />
      <DialogPrimitive.Content
        className={clsx(
          'fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2',
          'rounded-lg bg-white p-6 shadow-xl focus:outline-none',
          className
        )}
        {...props}
      >
        {children}
      </DialogPrimitive.Content>
    </DialogPrimitive.Portal>
  );
}
function DialogHeader({ className, children, ...props }) {
  return <div className={clsx('flex flex-col space-y-1.5 text-left mb-4', className)} {...props}>{children}</div>;
}
function DialogTitle({ className, children, ...props }) {
  return <DialogPrimitive.Title className={clsx('text-lg font-semibold text-gray-900', className)} {...props}>{children}</DialogPrimitive.Title>;
}
function DialogDescription({ className, children, ...props }) {
  return <DialogPrimitive.Description className={clsx('text-sm text-gray-500', className)} {...props}>{children}</DialogPrimitive.Description>;
}
function DialogFooter({ className, children, ...props }) {
  return <div className={clsx('flex flex-col-reverse gap-2 sm:flex-row sm:justify-end mt-4', className)} {...props}>{children}</div>;
}

const Tabs = TabsPrimitive.Root;

function TabsList({ className, ...props }) {
  return (
    <TabsPrimitive.List
      className={clsx('inline-flex h-10 items-center justify-center rounded-md bg-gray-100 p-1 text-gray-600', className)}
      {...props}
    />
  );
}
function TabsTrigger({ className, ...props }) {
  return (
    <TabsPrimitive.Trigger
      className={clsx(
        'inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium',
        'transition-all focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50',
        'data-[state=active]:bg-white data-[state=active]:text-gray-900 data-[state=active]:shadow-sm',
        className
      )}
      {...props}
    />
  );
}

// ─── Constants & Data ────────────────────────────────────────────────────────

const MAX_STRENGTH = 50;

const EVIDENCE_TYPES = [
  { id: 'rhetoric',  label: 'Rhetorik',               icon: MessageSquare },
  { id: 'witness',   label: 'Zeuge',                  icon: Users },
  { id: 'affidavit', label: 'Eidesstattliche Erklärung', icon: Scale },
  { id: 'paragraph', label: '§ Paragraph',            icon: BookOpen },
  { id: 'scenario',  label: 'Szenario',               icon: Target },
  { id: 'definition',label: 'Definition',             icon: Info },
  { id: 'chat',      label: 'Chat',                   icon: MessageSquare },
  { id: 'media',     label: 'Foto/Video',             icon: Camera },
  { id: 'document',  label: 'Dokument',               icon: FileText },
];

const initialOwnArguments = [
  {
    id: 1, side: 'own',
    title: 'Schriftliche Zusage per E-Mail',
    strength: 45, date: '2024-03-10',
    summary: 'CEO hat schriftlich per E-Mail zugesagt, die Konditionen zu erfüllen.',
    evidence: [{ id: 1, type: 'document', description: 'E-Mail von CEO vom 10.03.24' }],
    isStrategicallyRelevant: true,
  },
  {
    id: 2, side: 'own',
    title: 'Zeugenaussage Projektleiter',
    strength: 30, date: '2024-05-22',
    summary: 'Projektleiter kann mündliche Absprachen bestätigen.',
    evidence: [{ id: 1, type: 'witness', description: 'Aussage von H. Meier' }],
    isStrategicallyRelevant: false,
  },
];

const initialOpponents = {
  opponent1: {
    name: 'Hauptbeklagte',
    arguments: [
      {
        id: 3, side: 'opponent1',
        title: 'AGB-Klausel schließt Haftung aus',
        strength: 38, date: '2024-04-01',
        summary: 'Gegenseite beruft sich auf §8.3 der AGB.',
        evidence: [{ id: 1, type: 'paragraph', description: 'AGB §8.3' }],
        isStrategicallyRelevant: true,
      },
      {
        id: 4, side: 'opponent1',
        title: 'Keine formelle Vertragsänderung',
        strength: 25, date: '2024-06-05',
        summary: 'Mündliche Absprachen wurden nie schriftlich fixiert.',
        evidence: [],
        isStrategicallyRelevant: false,
      },
    ],
  },
  opponent2: {
    name: 'Nebenbeklagte',
    arguments: [
      {
        id: 5, side: 'opponent2',
        title: 'Vertragsstrafe für verspätete Lieferung',
        strength: 30, date: '2024-04-15',
        summary: 'Wir haben eine Vertragsstrafe für verspätete Lieferung vereinbart.',
        evidence: [{ id: 1, type: 'document', description: 'Vertragsanlage 2' }],
        isStrategicallyRelevant: false,
      },
    ],
  },
};

// ─── ArgumentGraph ────────────────────────────────────────────────────────────

function ArgumentGraph({ arguments: argList, side, ownArguments = [], opponentData = {}, selectedCombination = null }) {
  const svgRef = useRef(null);
  const [panOffset, setPanOffset] = useState({ x: 0, y: 0 });
  const [isPanning, setIsPanning] = useState(false);
  const [lastPanPoint, setLastPanPoint] = useState({ x: 0, y: 0 });

  const width = 700;
  const height = 180;
  const margin = { top: 15, right: 40, bottom: 35, left: 45 };
  const chartWidth = width - margin.left - margin.right;
  const chartHeight = height - margin.top - margin.bottom;
  const SNAP_TOLERANCE = 20;

  const netStrengthPoints = useMemo(() => {
    if (side !== 'combined' || !selectedCombination) return [];
    const strengthByDate = new Map();
    let opponentArgs = [];
    if (selectedCombination === 'all_opponents') {
      Object.values(opponentData).forEach(o => opponentArgs.push(...o.arguments));
    } else if (opponentData[selectedCombination]) {
      opponentArgs = opponentData[selectedCombination].arguments;
    }
    ownArguments.forEach(arg => {
      if (!strengthByDate.has(arg.date)) strengthByDate.set(arg.date, { own: 0, opponent: 0 });
      strengthByDate.get(arg.date).own += arg.strength;
    });
    opponentArgs.forEach(arg => {
      if (!strengthByDate.has(arg.date)) strengthByDate.set(arg.date, { own: 0, opponent: 0 });
      strengthByDate.get(arg.date).opponent += arg.strength;
    });
    return Array.from(strengthByDate.entries())
      .map(([date, s]) => ({ date, netStrength: s.own - s.opponent, ownStrength: s.own, opponentStrength: s.opponent, id: `net-${date}` }))
      .sort((a, b) => new Date(a.date) - new Date(b.date));
  }, [ownArguments, opponentData, side, selectedCombination]);

  const virtualNullPoints = useMemo(() => {
    if (side !== 'combined') return [];
    const pts = [];
    netStrengthPoints.forEach(p => {
      if (p.ownStrength === 0 && p.opponentStrength > 0)
        pts.push({ date: p.date, side: 'own',      isVirtualNull: true, id: `virtual-own-${p.date}` });
      if (p.opponentStrength === 0 && p.ownStrength > 0)
        pts.push({ date: p.date, side: 'opponent', isVirtualNull: true, id: `virtual-opponent-${p.date}` });
    });
    return pts;
  }, [netStrengthPoints, side]);

  const extendedArguments = useMemo(() => {
    if (side === 'combined') return [];
    const currentArgs = side === 'own' ? ownArguments : (opponentData[side]?.arguments || []);
    let otherArgs = [];
    if (side === 'own') {
      Object.values(opponentData).forEach(o => { otherArgs = [...otherArgs, ...o.arguments]; });
    } else {
      otherArgs = [...ownArguments];
      Object.entries(opponentData).forEach(([k, o]) => { if (k !== side) otherArgs = [...otherArgs, ...o.arguments]; });
    }
    const currentDates = new Set(currentArgs.map(a => a.date));
    const result = [...currentArgs];
    otherArgs.forEach(other => {
      if (!currentDates.has(other.date)) {
        result.push({
          id: `virtual-${other.date}-${side}-${Math.random()}`, side,
          title: `Kein Gegenargument (${other.date})`, strength: 0, date: other.date,
          summary: `Keine Reaktion auf Argument der Gegenseite vom ${new Date(other.date).toLocaleDateString()}`,
          evidence: [], isVirtual: true,
        });
      }
    });
    return result.sort((a, b) => new Date(a.date) - new Date(b.date));
  }, [ownArguments, opponentData, side]);

  const timeRange = useMemo(() => {
    let all = [...ownArguments];
    Object.values(opponentData).forEach(o => { all = [...all, ...o.arguments]; });
    if (!all.length) {
      const now = new Date();
      return { start: new Date(now.getFullYear(), now.getMonth() - 3, now.getDate()), end: now };
    }
    const dates = all.map(a => new Date(a.date));
    const min = new Date(Math.min(...dates));
    const max = new Date(Math.max(...dates));
    const buf = (max - min) * 0.1;
    return { start: new Date(min - buf), end: new Date(+max + buf) };
  }, [ownArguments, opponentData]);

  const argumentDatePoints = useMemo(() => {
    let all = [...ownArguments];
    Object.values(opponentData).forEach(o => { all = [...all, ...o.arguments]; });
    const span = timeRange.end - timeRange.start;
    return [...new Set(all.map(a => a.date))].map(date => ({
      date,
      xPosition: span > 0 ? ((new Date(date) - timeRange.start) / span) * chartWidth : 0,
    })).sort((a, b) => a.xPosition - b.xPosition);
  }, [ownArguments, opponentData, timeRange, chartWidth]);

  const getX = date => {
    const span = timeRange.end - timeRange.start;
    return span === 0 ? panOffset.x : ((new Date(date) - timeRange.start) / span) * chartWidth + panOffset.x;
  };

  const getY = (strength, _argSide, net) => {
    const y = side === 'combined'
      ? chartHeight * (0.5 - (net / MAX_STRENGTH) * 0.5)
      : chartHeight - (strength / MAX_STRENGTH) * chartHeight;
    return y + panOffset.y;
  };

  const snapToGrid = cur => {
    let snapped = { ...cur };
    let bestX = null, closest = SNAP_TOLERANCE + 1;
    argumentDatePoints.forEach(p => {
      const target = -p.xPosition;
      const dist = Math.abs(cur.x - target);
      if (dist < SNAP_TOLERANCE && dist < closest) { closest = dist; bestX = target; }
    });
    if (Math.abs(cur.x) < SNAP_TOLERANCE && Math.abs(cur.x) < closest) bestX = 0;
    if (bestX !== null) snapped.x = bestX;
    if (Math.abs(snapped.y) < SNAP_TOLERANCE) snapped.y = 0;

    const maxX = chartWidth * 0.5;
    snapped.x = Math.max(-maxX, Math.min(maxX, snapped.x));
    const [maxTop, maxBot] = side === 'combined'
      ? [-chartHeight * 0.5, chartHeight * 0.5]
      : [-chartHeight, 0];
    snapped.y = Math.max(maxTop, Math.min(maxBot, snapped.y));
    return snapped;
  };

  const handleMouseDown = e => { setIsPanning(true); setLastPanPoint({ x: e.clientX, y: e.clientY }); e.preventDefault(); };
  const handleMouseMove = e => {
    if (!isPanning) return;
    setPanOffset(prev => {
      const nx = prev.x + e.clientX - lastPanPoint.x;
      const ny = prev.y + e.clientY - lastPanPoint.y;
      const maxX = chartWidth * 0.5;
      const [maxTop, maxBot] = side === 'combined' ? [-chartHeight * 0.5, chartHeight * 0.5] : [-chartHeight, 0];
      return { x: Math.max(-maxX, Math.min(maxX, nx)), y: Math.max(maxTop, Math.min(maxBot, ny)) };
    });
    setLastPanPoint({ x: e.clientX, y: e.clientY });
  };
  const handleMouseUp = () => { if (isPanning) setPanOffset(prev => snapToGrid(prev)); setIsPanning(false); };

  const sortedArgs = side === 'combined' ? netStrengthPoints : extendedArguments;
  const pathData = sortedArgs.map((arg, i) => {
    const x = getX(arg.date);
    const y = side === 'combined' ? getY(0, null, arg.netStrength) : getY(arg.strength, arg.side, null);
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  const yLabels = useMemo(() => side === 'combined'
    ? [
        { y: 0,               label: MAX_STRENGTH },
        { y: chartHeight*.25, label: Math.round(MAX_STRENGTH*.5) },
        { y: chartHeight*.5,  label: '0' },
        { y: chartHeight*.75, label: -Math.round(MAX_STRENGTH*.5) },
        { y: chartHeight,     label: -MAX_STRENGTH },
      ]
    : [
        { y: 0,               label: MAX_STRENGTH },
        { y: chartHeight*.25, label: Math.round(MAX_STRENGTH*.75) },
        { y: chartHeight*.5,  label: Math.round(MAX_STRENGTH*.5) },
        { y: chartHeight*.75, label: Math.round(MAX_STRENGTH*.25) },
        { y: chartHeight,     label: '0' },
      ]
  , [side, chartHeight]);

  const xLabels = useMemo(() => {
    const span = timeRange.end - timeRange.start;
    if (span <= 0) return [];
    const months = span / (1000*60*60*24*30);
    const count = Math.min(5, Math.max(2, Math.floor(months / 2)));
    return Array.from({ length: count + 1 }, (_, i) => {
      const ratio = i / count;
      return {
        x: ratio * chartWidth,
        label: new Date(+timeRange.start + ratio * span).toLocaleDateString('de-DE', { month: 'short', day: 'numeric' }),
      };
    });
  }, [timeRange, chartWidth]);

  const cardTitle = side === 'combined'
    ? `Netto-Argumentstärke${selectedCombination
        ? ` (vs ${selectedCombination === 'all_opponents' ? 'Alle Gegner' : opponentData[selectedCombination]?.name || selectedCombination})`
        : ''}`
    : side === 'own' ? 'Eigene Argumente'
    : opponentData[side]?.name || 'Gegnerische Argumente';

  const lineColor = side === 'own' ? '#059669' : side.startsWith('opponent') ? '#dc2626' : '#0ea5e9';

  return (
    <Card className="bg-white rounded-2xl border border-gray-200/80 shadow-sm">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base font-semibold text-gray-900">{cardTitle}</CardTitle>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="text-xs bg-gray-50">{argList.length} Argumente</Badge>
            {side !== 'combined' && extendedArguments.some(a => a.isVirtual) && (
              <Badge variant="outline" className="text-xs bg-blue-50 text-blue-700">
                {extendedArguments.filter(a => a.isVirtual).length} Null-Punkte
              </Badge>
            )}
            {side === 'combined' && virtualNullPoints.length > 0 && (
              <Badge variant="outline" className="text-xs bg-orange-50 text-orange-700">
                {virtualNullPoints.length} Null-Punkte
              </Badge>
            )}
            <Move className="w-4 h-4 text-gray-400" />
          </div>
        </div>
      </CardHeader>
      <CardContent className="pb-4">
        <div className="relative bg-gray-50/30 rounded-xl border border-gray-200/50">
          <svg
            ref={svgRef} width={width} height={height}
            className={`w-full ${isPanning ? 'cursor-grabbing' : 'cursor-grab'}`}
            onMouseDown={handleMouseDown} onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp} onMouseLeave={handleMouseUp}
          >
            <defs>
              <clipPath id={`chart-area-${side}`}>
                <rect x={0} y={0} width={chartWidth} height={chartHeight} />
              </clipPath>
            </defs>

            <rect x={margin.left} y={margin.top} width={chartWidth} height={chartHeight} fill="white" rx="8" />

            <g transform={`translate(${margin.left},${margin.top})`} clipPath={`url(#chart-area-${side})`}>
              <g opacity="0.3">
                {yLabels.map((l, i) => (
                  <line key={i} x1={0} x2={chartWidth} y1={l.y + panOffset.y} y2={l.y + panOffset.y} stroke="#e5e7eb" strokeWidth="0.5" />
                ))}
                {xLabels.map((l, i) => (
                  <line key={i} x1={l.x + panOffset.x} x2={l.x + panOffset.x} y1={0} y2={chartHeight} stroke="#e5e7eb" strokeWidth="0.5" />
                ))}
              </g>

              {side === 'combined' && (
                <line x1={0} y1={chartHeight/2 + panOffset.y} x2={chartWidth} y2={chartHeight/2 + panOffset.y}
                  stroke="#6b7280" strokeWidth="1.5" strokeDasharray="4,4" />
              )}

              {sortedArgs.length > 1 && (
                <path d={pathData} fill="none" stroke={lineColor} strokeWidth="1.5" strokeLinejoin="round" />
              )}

              {sortedArgs.map(arg => (
                <circle
                  key={arg.id}
                  cx={getX(arg.date)}
                  cy={side === 'combined' ? getY(0, null, arg.netStrength) : getY(arg.strength, arg.side, null)}
                  r={arg.isVirtual ? '2' : '3'}
                  fill={arg.isVirtual ? '#f3f4f6' : (side === 'combined' ? '#0ea5e9' : 'white')}
                  stroke={arg.isVirtual ? '#9ca3af' : (side === 'combined' ? '#0ea5e9' : (arg.side === 'own' ? '#059669' : '#dc2626'))}
                  strokeWidth={arg.isVirtual ? '1' : '2'}
                  strokeDasharray={arg.isVirtual ? '2,2' : 'none'}
                  opacity={arg.isVirtual ? '0.7' : '1'}
                />
              ))}

              {side === 'combined' && virtualNullPoints.map(p => (
                <circle key={p.id} cx={getX(p.date)} cy={chartHeight/2 + panOffset.y} r="1.5"
                  fill={p.side === 'own' ? '#059669' : '#dc2626'}
                  stroke={p.side === 'own' ? '#059669' : '#dc2626'} strokeWidth="1" opacity="0.8" />
              ))}
            </g>

            {/* Y-axis */}
            <g>
              <line x1={margin.left} y1={margin.top} x2={margin.left} y2={height - margin.bottom} stroke="#6b7280" strokeWidth="1" />
              {yLabels.map((l, i) => (
                <g key={i}>
                  <line x1={margin.left} x2={margin.left-5} y1={margin.top+l.y} y2={margin.top+l.y} stroke="#6b7280" strokeWidth="1" />
                  <text x={margin.left-8} y={margin.top+l.y+4} textAnchor="end" fontSize="10" fill="#6b7280" fontFamily="system-ui">{l.label}</text>
                </g>
              ))}
              <text x={15} y={height/2} textAnchor="middle" fontSize="11" fill="#374151" fontWeight="500" fontFamily="system-ui"
                transform={`rotate(-90,15,${height/2})`}>
                {side === 'combined' ? 'Netto-Stärke' : 'Argumentstärke'}
              </text>
            </g>

            {/* X-axis */}
            <g>
              <line x1={margin.left} y1={height-margin.bottom} x2={width-margin.right} y2={height-margin.bottom} stroke="#6b7280" strokeWidth="1" />
              {xLabels.map((l, i) => (
                <g key={i}>
                  <line x1={margin.left+l.x} x2={margin.left+l.x} y1={height-margin.bottom} y2={height-margin.bottom+5} stroke="#6b7280" strokeWidth="1" />
                  <text x={margin.left+l.x} y={height-margin.bottom+15} textAnchor="middle" fontSize="10" fill="#6b7280" fontFamily="system-ui">{l.label}</text>
                </g>
              ))}
              <text x={width/2} y={height-5} textAnchor="middle" fontSize="11" fill="#374151" fontWeight="500" fontFamily="system-ui">Zeitpunkt</text>
            </g>
          </svg>
        </div>

        {side !== 'combined' && extendedArguments.some(a => a.isVirtual) && (
          <div className="mt-3 text-xs text-gray-500 flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-gray-300 border border-dashed border-gray-400" />
            <span>Null-Punkte (keine Reaktion auf Gegenargument)</span>
          </div>
        )}

        {side === 'combined' && virtualNullPoints.length > 0 && (
          <div className="mt-3 text-xs text-gray-500">
            <div className="flex items-center gap-4 mb-2">
              <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-green-600" /><span>Eigene Seite schweigt</span></div>
              <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-red-600" /><span>Gegner schweigt</span></div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-1">
              {virtualNullPoints.filter(p => p.side === 'own').map(p => (
                <div key={p.id} className="flex items-center gap-1">
                  <div className="w-1 h-1 rounded-full bg-green-600" />
                  <span className="text-green-700">Eigene Seite schweigt: {new Date(p.date).toLocaleDateString('de-DE')}</span>
                </div>
              ))}
              {virtualNullPoints.filter(p => p.side === 'opponent').map(p => (
                <div key={p.id} className="flex items-center gap-1">
                  <div className="w-1 h-1 rounded-full bg-red-600" />
                  <span className="text-red-700">Gegner schweigt: {new Date(p.date).toLocaleDateString('de-DE')}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ─── ArgumentCard ─────────────────────────────────────────────────────────────

function ArgumentCard({ argument, onEdit, onDelete, onToggleStrategic }) {
  const navigate = useNavigate();
  const [isExpanded, setIsExpanded] = useState(false);

  const EvidenceIcon = ({ type }) => {
    const found = EVIDENCE_TYPES.find(t => t.id === type);
    const Icon = found ? found.icon : FileText;
    return <Icon className="w-4 h-4 text-gray-500" />;
  };

  return (
    <Card className="bg-white rounded-2xl border border-gray-200/80 shadow-sm transition-all hover:border-gray-300">
      <CardContent className="p-4">
        <div className="flex justify-between items-start">
          <div
            className={`flex-1 pr-4 ${argument.isStrategicallyRelevant ? 'cursor-pointer' : ''}`}
            onClick={() => argument.isStrategicallyRelevant && navigate(createPageUrl('ArgumentDetails'), { state: { argument } })}
          >
            <div className="flex items-center gap-2 mb-2">
              <h4 className={`font-semibold text-gray-900 ${argument.isStrategicallyRelevant ? 'hover:text-blue-600 transition-colors' : ''}`}>
                {argument.title}
              </h4>
              {argument.isStrategicallyRelevant && (
                <Badge className="text-xs bg-purple-100 text-purple-700 border-purple-200">⚡ Strategisch</Badge>
              )}
            </div>
            <p className="text-sm text-gray-600 mt-1">{argument.summary}</p>
            <div className="flex items-center gap-2 mt-3">
              <Badge className="bg-blue-100 text-blue-800 font-medium">Stärke: {argument.strength}</Badge>
              <Badge variant="outline" className="text-gray-600">{new Date(argument.date).toLocaleDateString()}</Badge>
            </div>
            {argument.isStrategicallyRelevant ? (
              <div className="mt-2">
                <Badge variant="outline" className="text-xs bg-blue-50 text-blue-700 border-blue-200 cursor-pointer hover:bg-blue-100">
                  📋 Beweisstrang anzeigen →
                </Badge>
              </div>
            ) : (
              <div className="mt-2">
                <Button
                  variant="outline" size="sm"
                  onClick={e => { e.stopPropagation(); onToggleStrategic(argument.id, argument.side); }}
                  className="text-xs bg-purple-50 text-purple-700 border-purple-200 hover:bg-purple-100"
                >
                  ⚡ Als strategisch markieren
                </Button>
              </div>
            )}
          </div>

          <div className="flex items-center gap-1">
            <Button
              size="icon" variant="ghost"
              onClick={e => { e.stopPropagation(); onToggleStrategic(argument.id, argument.side); }}
              className={`h-8 w-8 rounded-lg ${argument.isStrategicallyRelevant ? 'text-purple-600 bg-purple-50' : 'text-gray-400 hover:text-purple-600'}`}
              title={argument.isStrategicallyRelevant ? 'Strategische Markierung entfernen' : 'Als strategisch markieren'}
            >
              <Zap className="w-4 h-4" />
            </Button>
            <Button size="icon" variant="ghost" onClick={() => onEdit(argument)} disabled={argument.isVirtual} className="h-8 w-8 rounded-lg">
              <Pencil className="w-4 h-4" />
            </Button>
            <Button size="icon" variant="ghost" onClick={() => onDelete(argument.id, argument.side)} disabled={argument.isVirtual} className="h-8 w-8 rounded-lg text-red-500">
              <Trash2 className="w-4 h-4" />
            </Button>
            <Button variant="ghost" size="icon" className="w-8 h-8 rounded-lg" onClick={() => setIsExpanded(!isExpanded)}>
              {isExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
            </Button>
          </div>
        </div>

        <AnimatePresence>
          {isExpanded && (
            <motion.div
              initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}
              className="mt-4 pt-4 border-t border-gray-200/80"
            >
              <h5 className="text-sm font-semibold text-gray-700 mb-2">Beweisstrang</h5>
              {argument.evidence.length > 0 ? (
                <ul className="space-y-2">
                  {argument.evidence.map(ev => (
                    <li key={ev.id} className="flex items-center gap-3 p-2 bg-gray-50 rounded-lg">
                      <EvidenceIcon type={ev.type} />
                      <span className="text-sm text-gray-800 flex-1">{ev.description}</span>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-gray-500 italic">Keine Beweise verknüpft.</p>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </CardContent>
    </Card>
  );
}

// ─── ArgumentVisualizer (main page) ──────────────────────────────────────────

function ArgumentVisualizer() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('combined');
  const [ownArguments, setOwnArguments] = useState(initialOwnArguments);
  const [opponentData, setOpponentData] = useState(initialOpponents);
  const [editingArgument, setEditingArgument] = useState(null);

  const [selectedCombination, setSelectedCombination] = useState(() => {
    const keys = Object.keys(initialOpponents);
    return keys.length > 1 ? 'all_opponents' : keys[0] ?? null;
  });

  useEffect(() => {
    const keys = Object.keys(opponentData);
    if (!selectedCombination ||
        (selectedCombination !== 'all_opponents' && !keys.includes(selectedCombination)) ||
        (selectedCombination === 'all_opponents' && keys.length <= 1)) {
      setSelectedCombination(keys.length === 0 ? null : keys.length === 1 ? keys[0] : 'all_opponents');
    }
  }, [opponentData, selectedCombination]);

  const handleAddOpponent = () => {
    const name = prompt('Name des neuen Gegners:');
    if (!name) return;
    const key = `opponent${Date.now()}`;
    setOpponentData(prev => {
      const next = { ...prev, [key]: { name, arguments: [] } };
      const prevKeys = Object.keys(prev);
      if (prevKeys.length === 0) setSelectedCombination(key);
      else if (prevKeys.length === 1) setSelectedCombination('all_opponents');
      return next;
    });
  };

  const handleSaveArgument = arg => {
    if (arg.side === 'own') {
      setOwnArguments(prev =>
        arg.id && !arg.isVirtual
          ? prev.map(a => a.id === arg.id ? arg : a)
          : [...prev, { ...arg, id: Date.now(), isStrategicallyRelevant: arg.isStrategicallyRelevant || false }]
      );
    } else {
      setOpponentData(prev => {
        const opp = prev[arg.side];
        if (!opp) return prev;
        return {
          ...prev,
          [arg.side]: {
            ...opp,
            arguments: arg.id && !arg.isVirtual
              ? opp.arguments.map(a => a.id === arg.id ? arg : a)
              : [...opp.arguments, { ...arg, id: Date.now(), isStrategicallyRelevant: arg.isStrategicallyRelevant || false }],
          },
        };
      });
    }
    setEditingArgument(null);
  };

  const handleDeleteArgument = (id, side) => {
    if (!window.confirm('Sind Sie sicher, dass Sie dieses Argument löschen möchten?')) return;
    if (side === 'own') {
      setOwnArguments(prev => prev.filter(a => a.id !== id));
    } else {
      setOpponentData(prev => {
        const opp = prev[side];
        if (!opp) return prev;
        return { ...prev, [side]: { ...opp, arguments: opp.arguments.filter(a => a.id !== id) } };
      });
    }
  };

  const handleToggleStrategic = (argId, side) => {
    if (side === 'own') {
      setOwnArguments(prev => prev.map(a => a.id === argId ? { ...a, isStrategicallyRelevant: !a.isStrategicallyRelevant } : a));
    } else {
      setOpponentData(prev => {
        const opp = prev[side];
        if (!opp) return prev;
        return {
          ...prev,
          [side]: { ...opp, arguments: opp.arguments.map(a => a.id === argId ? { ...a, isStrategicallyRelevant: !a.isStrategicallyRelevant } : a) },
        };
      });
    }
  };

  const opponentKeys = Object.keys(opponentData);

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="sticky top-0 bg-white/80 backdrop-blur-lg border-b border-gray-200/80 z-10">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate(createPageUrl('KanzleiDashboard'))}
              className="w-9 h-9 rounded-full bg-gray-100 hover:bg-gray-200">
              <ArrowLeft className="w-5 h-5 text-gray-700" />
            </Button>
            <div>
              <h1 className="text-lg font-semibold text-gray-900">Argument Visualizer</h1>
              <p className="text-sm text-gray-600">Zeitabhängige Analyse der Argumentationsstärke</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Button variant="outline" className="rounded-lg" onClick={handleAddOpponent}>
              <Plus className="w-4 h-4 mr-2" /> Neuer Gegner
            </Button>
            <Button className="rounded-lg bg-blue-600 hover:bg-blue-700"
              onClick={() => setEditingArgument({ side: 'own', strength: 25, date: new Date().toISOString().split('T')[0], evidence: [], isStrategicallyRelevant: false })}>
              <Plus className="w-4 h-4 mr-2" /> Neues Argument
            </Button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto p-6 space-y-8">
        {/* Tabs */}
        <div className="flex justify-center">
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="bg-gray-200/70 p-1 rounded-xl">
              <TabsTrigger value="own" className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-lg px-4">
                <TrendingUp className="w-4 h-4 mr-2 text-green-600" /> Eigene Seite
              </TabsTrigger>
              {opponentKeys.length > 0 && (
                <TabsTrigger value="combined" className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-lg px-4">
                  <BarChart3 className="w-4 h-4 mr-2 text-blue-600" /> Kombiniert
                </TabsTrigger>
              )}
              {Object.entries(opponentData).map(([key, opp]) => (
                <TabsTrigger key={key} value={key} className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-lg px-4">
                  <TrendingDown className="w-4 h-4 mr-2 text-red-600" /> {opp.name}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>
        </div>

        {/* Opponent selector for combined view */}
        {activeTab === 'combined' && opponentKeys.length > 0 && (
          <div className="flex justify-center">
            <div className="flex items-center gap-3 bg-white p-3 rounded-lg border border-gray-200">
              <span className="text-sm font-medium text-gray-700">Vergleich mit:</span>
              <Tabs value={selectedCombination || ''} onValueChange={setSelectedCombination}>
                <TabsList className="bg-gray-100 p-1 rounded-lg">
                  {Object.entries(opponentData).map(([key, opp]) => (
                    <TabsTrigger key={key} value={key} className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-md px-3 text-sm">
                      {opp.name}
                    </TabsTrigger>
                  ))}
                  {opponentKeys.length > 1 && (
                    <TabsTrigger value="all_opponents" className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-md px-3 text-sm">
                      Alle Gegner
                    </TabsTrigger>
                  )}
                </TabsList>
              </Tabs>
            </div>
          </div>
        )}

        {/* Graph */}
        <AnimatePresence mode="wait">
          <motion.div key={activeTab + selectedCombination}
            initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
            {activeTab === 'own' && (
              <ArgumentGraph arguments={ownArguments} side="own" ownArguments={ownArguments} opponentData={opponentData} />
            )}
            {activeTab === 'combined' && selectedCombination && (
              <ArgumentGraph
                arguments={
                  selectedCombination === 'all_opponents'
                    ? [...ownArguments, ...Object.values(opponentData).flatMap(o => o.arguments)]
                    : [...ownArguments, ...(opponentData[selectedCombination]?.arguments || [])]
                }
                side="combined" ownArguments={ownArguments} opponentData={opponentData} selectedCombination={selectedCombination}
              />
            )}
            {opponentKeys.includes(activeTab) && (
              <ArgumentGraph arguments={opponentData[activeTab]?.arguments || []} side={activeTab} ownArguments={ownArguments} opponentData={opponentData} />
            )}
          </motion.div>
        </AnimatePresence>

        {/* Argument lists */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-800">Eigene Argumente</h3>
            {ownArguments.map(arg => (
              <ArgumentCard key={arg.id} argument={arg} onEdit={setEditingArgument} onDelete={handleDeleteArgument} onToggleStrategic={handleToggleStrategic} />
            ))}
          </div>
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-800">Gegnerische Argumente</h3>
            {Object.entries(opponentData).map(([key, opp]) => (
              <div key={key} className="space-y-4">
                <h4 className="text-md font-medium text-gray-700 border-l-4 border-red-400 pl-3">{opp.name}</h4>
                {opp.arguments.map(arg => (
                  <ArgumentCard key={arg.id} argument={arg} onEdit={setEditingArgument} onDelete={handleDeleteArgument} onToggleStrategic={handleToggleStrategic} />
                ))}
              </div>
            ))}
          </div>
        </div>
      </main>

      {/* Edit / Create Dialog */}
      <AnimatePresence>
        {editingArgument && (
          <Dialog open onOpenChange={() => setEditingArgument(null)}>
            <DialogContent className="sm:max-w-[425px] bg-white rounded-2xl">
              <DialogHeader>
                <DialogTitle>{editingArgument.id && !editingArgument.isVirtual ? 'Argument bearbeiten' : 'Neues Argument erstellen'}</DialogTitle>
                <DialogDescription>Füllen Sie die Details für das Argument aus.</DialogDescription>
              </DialogHeader>
              <div className="py-4 space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="title">Titel</Label>
                  <Input id="title" value={editingArgument.title || ''} disabled={editingArgument.isVirtual}
                    onChange={e => setEditingArgument({ ...editingArgument, title: e.target.value })} className="rounded-lg" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="summary">Zusammenfassung</Label>
                  <Textarea id="summary" value={editingArgument.summary || ''} disabled={editingArgument.isVirtual}
                    onChange={e => setEditingArgument({ ...editingArgument, summary: e.target.value })} className="rounded-lg" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="date">Datum</Label>
                    <Input id="date" type="date" value={editingArgument.date || ''} disabled={editingArgument.isVirtual}
                      onChange={e => setEditingArgument({ ...editingArgument, date: e.target.value })} className="rounded-lg" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="side">Seite</Label>
                    <select id="side" value={editingArgument.side || 'own'} disabled={editingArgument.isVirtual}
                      onChange={e => setEditingArgument({ ...editingArgument, side: e.target.value })}
                      className="w-full p-2 border border-gray-200 rounded-lg text-sm">
                      <option value="own">Eigene Seite</option>
                      {Object.entries(opponentData).map(([k, o]) => <option key={k} value={k}>{o.name}</option>)}
                    </select>
                  </div>
                </div>
                <div className="space-y-2">
                  <Label>Stärke: {editingArgument.strength}</Label>
                  <Slider value={[editingArgument.strength]} max={MAX_STRENGTH} step={1} disabled={editingArgument.isVirtual}
                    onValueChange={([v]) => setEditingArgument({ ...editingArgument, strength: v })} />
                </div>
                <div className="flex items-center space-x-2">
                  <input type="checkbox" id="strategic"
                    checked={editingArgument.isStrategicallyRelevant || false}
                    disabled={editingArgument.isVirtual}
                    onChange={e => setEditingArgument({ ...editingArgument, isStrategicallyRelevant: e.target.checked })}
                    className="rounded border-gray-300 text-purple-600 focus:ring-purple-500"
                  />
                  <Label htmlFor="strategic" className="flex items-center gap-2 cursor-pointer">
                    <Zap className="w-4 h-4 text-purple-600" />
                    Strategisch relevantes Argument (bekommt Beweisstrang)
                  </Label>
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setEditingArgument(null)}>Abbrechen</Button>
                <Button onClick={() => handleSaveArgument(editingArgument)} disabled={editingArgument.isVirtual}>Speichern</Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        )}
      </AnimatePresence>
    </div>
  );
}

// ─── KanzleiDashboard (stub) ──────────────────────────────────────────────────

function KanzleiDashboard() {
  const navigate = useNavigate();
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">Kanzlei Dashboard</h1>
        <p className="text-gray-500">Platzhalter-Seite</p>
        <button className="text-blue-600 underline text-sm" onClick={() => navigate('/')}>
          ← Zurück zum Argument Visualizer
        </button>
      </div>
    </div>
  );
}

// ─── Root App ─────────────────────────────────────────────────────────────────

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<ArgumentVisualizer />} />
        <Route path="/kanzlei-dashboard" element={<KanzleiDashboard />} />
        <Route path="*" element={<ArgumentVisualizer />} />
      </Routes>
    </BrowserRouter>
  );
}
