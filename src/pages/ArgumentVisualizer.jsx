import React, { useState, useMemo, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Slider } from '@/components/ui/slider';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  ArrowLeft, Plus, ChevronDown, ChevronRight, TrendingUp, TrendingDown,
  BarChart3, Users, Camera, MessageSquare, BookOpen, FileText,
  Scale, Target, Info, Pencil, Trash2, Move, Zap
} from 'lucide-react';

const MAX_STRENGTH = 50;

const EVIDENCE_TYPES = [
  { id: 'rhetoric', label: 'Rhetorik', icon: MessageSquare },
  { id: 'witness', label: 'Zeuge', icon: Users },
  { id: 'affidavit', label: 'Eidesstattliche Erklärung', icon: Scale },
  { id: 'paragraph', label: '§ Paragraph', icon: BookOpen },
  { id: 'scenario', label: 'Szenario', icon: Target },
  { id: 'definition', label: 'Definition', icon: Info },
  { id: 'chat', label: 'Chat', icon: MessageSquare },
  { id: 'media', label: 'Foto/Video', icon: Camera },
  { id: 'document', label: 'Dokument', icon: FileText }
];

const initialOwnArguments = [
    {
      id: 1,
      side: 'own',
      title: 'Schriftliche Zusage per E-Mail',
      strength: 45,
      date: '2024-03-10',
      summary: 'CEO hat schriftlich per E-Mail zugesagt, die Konditionen zu erfüllen.',
      evidence: [{id: 1, type: 'document', description: 'E-Mail von CEO vom 10.03.24'}],
      isStrategicallyRelevant: true
    },
    {
      id: 2,
      side: 'own',
      title: 'Zeugenaussage Projektleiter',
      strength: 30,
      date: '2024-05-22',
      summary: 'Projektleiter kann mündliche Absprachen bestätigen.',
      evidence: [{id: 1, type: 'witness', description: 'Aussage von H. Meier'}],
      isStrategicallyRelevant: false
    }
];

const initialOpponents = {
    'opponent1': {
        name: 'Hauptbeklagte',
        arguments: [
            {
              id: 3,
              side: 'opponent1',
              title: 'AGB-Klausel schließt Haftung aus',
              strength: 38,
              date: '2024-04-01',
              summary: 'Gegenseite beruft sich auf §8.3 der AGB.',
              evidence: [{id: 1, type: 'paragraph', description: 'AGB §8.3'}],
              isStrategicallyRelevant: true
            },
            {
              id: 4,
              side: 'opponent1',
              title: 'Keine formelle Vertragsänderung',
              strength: 25,
              date: '2024-06-05',
              summary: 'Mündliche Absprachen wurden nie schriftlich fixiert.',
              evidence: [],
              isStrategicallyRelevant: false
            }
        ]
    },
    'opponent2': {
        name: 'Nebenbeklagte',
        arguments: [
            {
              id: 5,
              side: 'opponent2',
              title: 'Vertragsstrafe für verspätete Lieferung',
              strength: 30,
              date: '2024-04-15',
              summary: 'Wir haben eine Vertragsstrafe für verspätete Lieferung vereinbart.',
              evidence: [{id: 1, type: 'document', description: 'Vertragsanlage 2'}],
              isStrategicallyRelevant: false
            },
        ]
    }
};

const ArgumentGraph = ({ arguments: argList, side, ownArguments = [], opponentData = {}, selectedCombination = null }) => {
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

    let opponentArgumentsToUse = [];
    if (selectedCombination === 'all_opponents') {
      Object.values(opponentData).forEach(opponent => {
        opponentArgumentsToUse.push(...opponent.arguments);
      });
    } else if (opponentData[selectedCombination]) {
      opponentArgumentsToUse = opponentData[selectedCombination].arguments;
    }

    ownArguments.forEach(arg => {
      if (!strengthByDate.has(arg.date)) {
        strengthByDate.set(arg.date, { own: 0, opponent: 0 });
      }
      strengthByDate.get(arg.date).own += arg.strength;
    });

    opponentArgumentsToUse.forEach(arg => {
      if (!strengthByDate.has(arg.date)) {
        strengthByDate.set(arg.date, { own: 0, opponent: 0 });
      }
      strengthByDate.get(arg.date).opponent += arg.strength;
    });

    const points = Array.from(strengthByDate.entries()).map(([date, strengths]) => ({
      date: date,
      netStrength: strengths.own - strengths.opponent,
      ownStrength: strengths.own,
      opponentStrength: strengths.opponent,
      id: `net-${date}`
    }));

    return points.sort((a, b) => new Date(a.date) - new Date(b.date));
  }, [ownArguments, opponentData, side, selectedCombination]);

  const virtualNullPoints = useMemo(() => {
    if (side !== 'combined') return [];

    const nullPoints = [];

    netStrengthPoints.forEach(point => {
      if (point.ownStrength === 0 && point.opponentStrength > 0) {
        nullPoints.push({
          date: point.date,
          side: 'own',
          isVirtualNull: true,
          id: `virtual-own-${point.date}`
        });
      }
      if (point.opponentStrength === 0 && point.ownStrength > 0) {
        nullPoints.push({
          date: point.date,
          side: 'opponent',
          isVirtualNull: true,
          id: `virtual-opponent-${point.date}`
        });
      }
    });

    return nullPoints;
  }, [netStrengthPoints, side]);

  const extendedArguments = useMemo(() => {
    if (side === 'combined') {
      return [];
    }

    const currentSideArgs = side === 'own' ? ownArguments : (opponentData[side]?.arguments || []);

    let otherSideArgs = [];
    if (side === 'own') {
      Object.values(opponentData).forEach(opponent => {
        otherSideArgs = [...otherSideArgs, ...opponent.arguments];
      });
    } else {
      otherSideArgs = [...ownArguments];
      Object.entries(opponentData).forEach(([opponentKey, opponent]) => {
        if (opponentKey !== side) {
          otherSideArgs = [...otherSideArgs, ...opponent.arguments];
        }
      });
    }

    const currentSideDates = new Set(currentSideArgs.map(arg => arg.date));

    const result = [...currentSideArgs];

    otherSideArgs.forEach(otherArg => {
      if (!currentSideDates.has(otherArg.date)) {
        result.push({
          id: `virtual-${otherArg.date}-${side}-${Math.random()}`,
          side: side,
          title: `Kein Gegenargument (${otherArg.date})`,
          strength: 0,
          date: otherArg.date,
          summary: `Keine Reaktion auf Argument der Gegenseite vom ${new Date(otherArg.date).toLocaleDateString()}`,
          evidence: [],
          isVirtual: true
        });
      }
    });

    return result.sort((a, b) => new Date(a.date) - new Date(b.date));
  }, [ownArguments, opponentData, side]);

  const timeRange = useMemo(() => {
    let allArgs = [...ownArguments];
    Object.values(opponentData).forEach(opponent => {
      allArgs = [...allArgs, ...opponent.arguments];
    });

    if (!allArgs || allArgs.length === 0) {
      const now = new Date();
      const threeMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 3, now.getDate());
      return { start: threeMonthsAgo, end: now };
    }

    const dates = allArgs.map(arg => new Date(arg.date));
    const minDate = new Date(Math.min(...dates));
    const maxDate = new Date(Math.max(...dates));

    const buffer = (maxDate.getTime() - minDate.getTime()) * 0.1;
    return {
      start: new Date(minDate.getTime() - buffer),
      end: new Date(maxDate.getTime() + buffer)
    };
  }, [ownArguments, opponentData]);

  const argumentDatePoints = useMemo(() => {
    let allArgs = [...ownArguments];
    Object.values(opponentData).forEach(opponent => {
      allArgs = [...allArgs, ...opponent.arguments];
    });

    const uniqueDates = [...new Set(allArgs.map(arg => arg.date))];
    const startTime = timeRange.start.getTime();
    const endTime = timeRange.end.getTime();
    const span = endTime - startTime;

    return uniqueDates.map(date => {
      const timestamp = new Date(date).getTime();
      const xPos = span > 0 ? ((timestamp - startTime) / span) * chartWidth : 0;
      return {
        date: date,
        xPosition: xPos
      };
    }).sort((a, b) => a.xPosition - b.xPosition);
  }, [ownArguments, opponentData, timeRange, chartWidth]);

  const getX = (date) => {
    const timestamp = new Date(date).getTime();
    const startTime = timeRange.start.getTime();
    const endTime = timeRange.end.getTime();
    const span = endTime - startTime;
    if (span === 0) return panOffset.x;
    return ((timestamp - startTime) / span) * chartWidth + panOffset.x;
  };

  const getY = (strength, argSide, netStrengthValue) => {
    let y;
    if (side === 'combined') {
        const value = netStrengthValue;
        y = chartHeight * (0.5 - (value / MAX_STRENGTH) * 0.5);
    } else {
        y = chartHeight - (strength / MAX_STRENGTH) * chartHeight;
    }
    return y + panOffset.y;
  };

  const snapToGrid = (currentOffset) => {
    const snappedOffset = { ...currentOffset };

    let bestXSnap = null;
    let closestXDistance = SNAP_TOLERANCE + 1;

    argumentDatePoints.forEach(point => {
      const targetXOffset = -point.xPosition;
      const distance = Math.abs(currentOffset.x - targetXOffset);

      if (distance < SNAP_TOLERANCE && distance < closestXDistance) {
        closestXDistance = distance;
        bestXSnap = targetXOffset;
      }
    });

    const distanceToZero = Math.abs(currentOffset.x);
    if (distanceToZero < SNAP_TOLERANCE && distanceToZero < closestXDistance) {
      bestXSnap = 0;
    }

    if (bestXSnap !== null) {
      snappedOffset.x = bestXSnap;
    }

    if (Math.abs(snappedOffset.y) < SNAP_TOLERANCE) {
      snappedOffset.y = 0;
    }

    let finalX = snappedOffset.x;
    let finalY = snappedOffset.y;

    const maxRightX = chartWidth * 0.5;
    const maxLeftX = -chartWidth * 0.5;
    finalX = Math.max(maxLeftX, Math.min(maxRightX, finalX));

    let maxTopY, maxBottomY;
    if (side === 'combined') {
      maxTopY = -chartHeight * 0.5;
      maxBottomY = chartHeight * 0.5;
    } else {
      maxTopY = -chartHeight;
      maxBottomY = 0;
    }
    finalY = Math.max(maxTopY, Math.min(maxBottomY, finalY));

    return { x: finalX, y: finalY };
  };

  const handleMouseDown = (e) => {
    setIsPanning(true);
    setLastPanPoint({ x: e.clientX, y: e.clientY });
    e.preventDefault();
  };

  const handleMouseMove = (e) => {
    if (!isPanning) return;

    const dx = e.clientX - lastPanPoint.x;
    const dy = e.clientY - lastPanPoint.y;

    setPanOffset(prev => {
      let newX = prev.x + dx;
      let newY = prev.y + dy;

      const maxRightX = chartWidth * 0.5;
      const maxLeftX = -chartWidth * 0.5;
      newX = Math.max(maxLeftX, Math.min(maxRightX, newX));

      let maxTopY, maxBottomY;
      if (side === 'combined') {
        maxTopY = -chartHeight * 0.5;
        maxBottomY = chartHeight * 0.5;
      } else {
        maxTopY = -chartHeight;
        maxBottomY = 0;
      }
      newY = Math.max(maxTopY, Math.min(maxBottomY, newY));

      return { x: newX, y: newY };
    });

    setLastPanPoint({ x: e.clientX, y: e.clientY });
  };

  const handleMouseUp = () => {
    if (isPanning) {
      setPanOffset(prev => snapToGrid(prev));
    }
    setIsPanning(false);
  };

  const sortedArgs = side === 'combined' ? netStrengthPoints : extendedArguments;

  const pathData = sortedArgs.map((arg, index) => {
    const x = getX(arg.date);
    const y = side === 'combined'
      ? getY(0, null, arg.netStrength)
      : getY(arg.strength, arg.side, null);
    return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  const yLabels = useMemo(() => {
    const labels = [];
    if (side === 'combined') {
      labels.push({ y: 0, label: MAX_STRENGTH });
      labels.push({ y: chartHeight * 0.25, label: Math.round(MAX_STRENGTH * 0.5) });
      labels.push({ y: chartHeight * 0.5, label: '0' });
      labels.push({ y: chartHeight * 0.75, label: -Math.round(MAX_STRENGTH * 0.5) });
      labels.push({ y: chartHeight, label: -MAX_STRENGTH });
    } else {
      labels.push({ y: 0, label: MAX_STRENGTH });
      labels.push({ y: chartHeight * 0.25, label: Math.round(MAX_STRENGTH * 0.75) });
      labels.push({ y: chartHeight * 0.5, label: Math.round(MAX_STRENGTH * 0.5) });
      labels.push({ y: chartHeight * 0.75, label: Math.round(MAX_STRENGTH * 0.25) });
      labels.push({ y: chartHeight, label: '0' });
    }
    return labels;
  }, [side, chartHeight]);

  const xLabels = useMemo(() => {
    const labels = [];
    const spanMillis = timeRange.end.getTime() - timeRange.start.getTime();

    let allArgs = [...ownArguments];
    Object.values(opponentData).forEach(opponent => {
      allArgs = [...allArgs, ...opponent.arguments];
    });

    if (spanMillis <= 0) {
      if (allArgs.length > 0) {
        const date = new Date(allArgs[0].date);
        labels.push({ x: chartWidth / 2, label: date.toLocaleDateString('de-DE', { month: 'short', day: 'numeric' }) });
      }
      return labels;
    }

    const oneMonthMillis = 1000 * 60 * 60 * 24 * 30;
    const approxMonths = spanMillis / oneMonthMillis;
    let labelCount = Math.min(5, Math.max(2, Math.floor(approxMonths / 2)));
    if (labelCount < 2 && approxMonths > 0) labelCount = 2;

    for (let i = 0; i <= labelCount; i++) {
      const ratio = i / labelCount;
      const date = new Date(timeRange.start.getTime() + ratio * spanMillis);
      labels.push({
        x: ratio * chartWidth,
        label: date.toLocaleDateString('de-DE', { month: 'short', day: 'numeric' })
      });
    }
    return labels;
  }, [timeRange, chartWidth, ownArguments, opponentData]);

  const getCardTitle = () => {
      if (side === 'combined') {
          let opponentName = '';
          if (selectedCombination) {
              if (selectedCombination === 'all_opponents') {
                  opponentName = 'Alle Gegner';
              } else {
                  opponentName = opponentData[selectedCombination]?.name || selectedCombination;
              }
          }
          return `Netto-Argumentstärke${opponentName ? ` (vs ${opponentName})` : ''}`;
      } else if (side === 'own') {
          return 'Eigene Argumente';
      } else if (side.startsWith('opponent')) {
          return opponentData[side]?.name || 'Gegnerische Argumente';
      }
      return 'Argumente';
  };

  return (
    <Card className="bg-white rounded-2xl border border-gray-200/80 shadow-sm">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base font-semibold text-gray-900">
            {getCardTitle()}
          </CardTitle>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="text-xs bg-gray-50">
              {argList.length} Argumente
            </Badge>
            {side !== 'combined' && extendedArguments.some(arg => arg.isVirtual) && (
                <Badge variant="outline" className="text-xs bg-blue-50 text-blue-700">
                {extendedArguments.filter(arg => arg.isVirtual).length} Null-Punkte
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
            ref={svgRef}
            width={width}
            height={height}
            className={`w-full ${isPanning ? 'cursor-grabbing' : 'cursor-grab'}`}
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
          >
            <defs>
              <clipPath id={`chart-area-${side}`}>
                <rect x={0} y={0} width={chartWidth} height={chartHeight} />
              </clipPath>
            </defs>

            <rect x={margin.left} y={margin.top} width={chartWidth} height={chartHeight} fill="white" rx="8" />

            <g transform={`translate(${margin.left}, ${margin.top})`} clipPath={`url(#chart-area-${side})`}>

              <g opacity="0.3">
                {yLabels.map((label, i) => (
                  <line key={`y-grid-${i}`} x1={0} x2={chartWidth} y1={label.y + panOffset.y} y2={label.y + panOffset.y} stroke="#e5e7eb" strokeWidth="0.5" />
                ))}
                {xLabels.map((label, i) => (
                  <line key={`x-grid-${i}`} x1={label.x + panOffset.x} x2={label.x + panOffset.x} y1={0} y2={chartHeight} stroke="#e5e7eb" strokeWidth="0.5" />
                ))}
              </g>

              {side === 'combined' && (
                <line
                  x1={0}
                  y1={chartHeight / 2 + panOffset.y}
                  x2={chartWidth}
                  y2={chartHeight / 2 + panOffset.y}
                  stroke="#6b7280"
                  strokeWidth="1.5"
                  strokeDasharray="4,4"
                />
              )}

              {sortedArgs.length > 1 && (
                <path
                  d={pathData}
                  fill="none"
                  stroke={side === 'own' ? '#059669' : (side.startsWith('opponent') ? '#dc2626' : '#0ea5e9')}
                  strokeWidth="1.5"
                  strokeLinejoin="round"
                />
              )}

              {sortedArgs.map(arg => (
                <circle
                  key={arg.id}
                  cx={getX(arg.date)}
                  cy={side === 'combined'
                      ? getY(0, null, arg.netStrength)
                      : getY(arg.strength, arg.side, null)
                  }
                  r={arg.isVirtual ? "2" : "3"}
                  fill={arg.isVirtual ? "#f3f4f6" : (side === 'combined' ? '#0ea5e9' : "white")}
                  stroke={arg.isVirtual ? "#9ca3af" : (side === 'combined' ? '#0ea5e9' : (arg.side === 'own' ? '#059669' : '#dc2626'))}
                  strokeWidth={arg.isVirtual ? "1" : "2"}
                  strokeDasharray={arg.isVirtual ? "2,2" : "none"}
                  opacity={arg.isVirtual ? "0.7" : "1"}
                />
              ))}

              {side === 'combined' && virtualNullPoints.map(nullPoint => (
                <circle
                  key={nullPoint.id}
                  cx={getX(nullPoint.date)}
                  cy={chartHeight / 2 + panOffset.y}
                  r="1.5"
                  fill={nullPoint.side === 'own' ? '#059669' : '#dc2626'}
                  stroke={nullPoint.side === 'own' ? '#059669' : '#dc2626'}
                  strokeWidth="1"
                  opacity="0.8"
                />
              ))}
            </g>

            <g>
              <line x1={margin.left} y1={margin.top} x2={margin.left} y2={height - margin.bottom} stroke="#6b7280" strokeWidth="1" />
              {yLabels.map((label, i) => (
                <g key={`y-label-group-${i}`}>
                  <line x1={margin.left} x2={margin.left - 5} y1={margin.top + label.y} y2={margin.top + label.y} stroke="#6b7280" strokeWidth="1" />
                  <text x={margin.left - 8} y={margin.top + label.y + 4} textAnchor="end" fontSize="10" fill="#6b7280" fontFamily="system-ui">
                    {label.label}
                  </text>
                </g>
              ))}
              <text x={15} y={height / 2} textAnchor="middle" fontSize="11" fill="#374151" fontWeight="500" fontFamily="system-ui" transform={`rotate(-90, 15, ${height / 2})`}>
                {side === 'combined' ? 'Netto-Stärke' : 'Argumentstärke'}
              </text>
            </g>

            <g>
              <line x1={margin.left} y1={height - margin.bottom} x2={width - margin.right} y2={height - margin.bottom} stroke="#6b7280" strokeWidth="1" />
              {xLabels.map((label, i) => (
                <g key={`x-label-group-${i}`}>
                  <line x1={margin.left + label.x} x2={margin.left + label.x} y1={height - margin.bottom} y2={height - margin.bottom + 5} stroke="#6b7280" strokeWidth="1" />
                  <text x={margin.left + label.x} y={height - margin.bottom + 15} textAnchor="middle" fontSize="10" fill="#6b7280" fontFamily="system-ui">
                    {label.label}
                  </text>
                </g>
              ))}
              <text x={width / 2} y={height - 5} textAnchor="middle" fontSize="11" fill="#374151" fontWeight="500" fontFamily="system-ui">
                Zeitpunkt
              </text>
            </g>
          </svg>
        </div>

        {side !== 'combined' && extendedArguments.some(arg => arg.isVirtual) && (
          <div className="mt-3 text-xs text-gray-500 flex items-center gap-4">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-gray-300 border border-gray-400" style={{borderStyle: 'dashed'}}></div>
              <span>Null-Punkte (keine Reaktion auf Gegenargument)</span>
            </div>
          </div>
        )}

        {side === 'combined' && virtualNullPoints.length > 0 && (
          <div className="mt-3 text-xs text-gray-500">
            <div className="flex items-center gap-4 mb-2">
              <div className="flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-green-600"></div>
                <span>Eigene Seite schweigt</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-red-600"></div>
                <span>Gegner schweigt</span>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-1 text-xs">
              {virtualNullPoints
                .filter(point => point.side === 'own')
                .map(point => (
                  <div key={point.id} className="flex items-center gap-1">
                    <div className="w-1 h-1 rounded-full bg-green-600"></div>
                    <span className="text-green-700">
                      Eigene Seite schweigt: {new Date(point.date).toLocaleDateString('de-DE')}
                    </span>
                  </div>
                ))}
              {virtualNullPoints
                .filter(point => point.side === 'opponent')
                .map(point => (
                  <div key={point.id} className="flex items-center gap-1">
                    <div className="w-1 h-1 rounded-full bg-red-600"></div>
                    <span className="text-red-700">
                      Gegner schweigt: {new Date(point.date).toLocaleDateString('de-DE')}
                    </span>
                  </div>
                ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
};


const ArgumentCard = ({ argument, onEdit, onDelete, onToggleStrategic }) => {
    const navigate = useNavigate();
    const [isExpanded, setIsExpanded] = useState(false);

    const EvidenceIcon = ({type}) => {
        const iconData = EVIDENCE_TYPES.find(t => t.id === type);
        const Icon = iconData ? iconData.icon : FileText;
        return <Icon className="w-4 h-4 text-gray-500" />;
    };

    const handleArgumentClick = () => {
        if (argument.isStrategicallyRelevant) {
            navigate(createPageUrl('ArgumentDetails'), {
                state: { argument }
            });
        }
    };

    return (
        <Card className="bg-white rounded-2xl border border-gray-200/80 shadow-sm transition-all hover:border-gray-300">
            <CardContent className="p-4">
                <div className="flex justify-between items-start">
                    <div
                        className={`flex-1 pr-4 ${argument.isStrategicallyRelevant ? 'cursor-pointer' : ''}`}
                        onClick={handleArgumentClick}
                    >
                        <div className="flex items-center gap-2 mb-2">
                            <h4 className={`font-semibold text-gray-900 ${argument.isStrategicallyRelevant ? 'hover:text-blue-600 transition-colors' : ''}`}>
                                {argument.title}
                            </h4>
                            {argument.isStrategicallyRelevant && (
                                <Badge className="text-xs bg-purple-100 text-purple-700 border-purple-200">
                                    ⚡ Strategisch
                                </Badge>
                            )}
                        </div>
                        <p className="text-sm text-gray-600 mt-1">{argument.summary}</p>
                        <div className="flex items-center gap-2 mt-3">
                            <Badge className="bg-blue-100 text-blue-800 font-medium">Stärke: {argument.strength}</Badge>
                            <Badge variant="outline" className="text-gray-600">{new Date(argument.date).toLocaleDateString()}</Badge>
                        </div>
                        {argument.isStrategicallyRelevant && (
                            <div className="mt-2">
                                <Badge
                                    variant="outline"
                                    className="text-xs bg-blue-50 text-blue-700 border-blue-200 cursor-pointer hover:bg-blue-100"
                                >
                                    📋 Beweisstrang anzeigen →
                                </Badge>
                            </div>
                        )}
                        {!argument.isStrategicallyRelevant && (
                            <div className="mt-2">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        onToggleStrategic(argument.id, argument.side);
                                    }}
                                    className="text-xs bg-purple-50 text-purple-700 border-purple-200 hover:bg-purple-100"
                                >
                                    ⚡ Als strategisch markieren
                                </Button>
                            </div>
                        )}
                    </div>

                    <div className="flex items-center gap-1">
                        <Button
                            size="icon"
                            variant="ghost"
                            onClick={(e) => {
                                e.stopPropagation();
                                onToggleStrategic(argument.id, argument.side);
                            }}
                            className={`h-8 w-8 rounded-lg ${argument.isStrategicallyRelevant ? 'text-purple-600 bg-purple-50' : 'text-gray-400 hover:text-purple-600'}`}
                            title={argument.isStrategicallyRelevant ? "Strategische Markierung entfernen" : "Als strategisch markieren"}
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
                    <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="mt-4 pt-4 border-t border-gray-200/80">
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
    )
}

export default function ArgumentVisualizer() {
    const navigate = useNavigate();
    const [activeTab, setActiveTab] = useState('combined');
    const [ownArguments, setOwnArguments] = useState(initialOwnArguments);
    const [opponentData, setOpponentData] = useState(initialOpponents);
    const [editingArgument, setEditingArgument] = useState(null);

    const [selectedCombination, setSelectedCombination] = useState(() => {
        const opponentKeys = Object.keys(initialOpponents);
        if (opponentKeys.length > 1) {
            return 'all_opponents';
        } else if (opponentKeys.length === 1) {
            return opponentKeys[0];
        }
        return null;
    });

    useEffect(() => {
        const opponentKeys = Object.keys(opponentData);
        if (!selectedCombination ||
            (selectedCombination !== 'all_opponents' && !opponentKeys.includes(selectedCombination)) ||
            (selectedCombination === 'all_opponents' && opponentKeys.length <= 1)
        ) {
            if (opponentKeys.length === 0) {
                setSelectedCombination(null);
            } else if (opponentKeys.length === 1) {
                setSelectedCombination(opponentKeys[0]);
            } else {
                setSelectedCombination('all_opponents');
            }
        }
    }, [opponentData, selectedCombination]);


    const handleAddOpponent = () => {
        const opponentName = prompt("Name des neuen Gegners:");
        if (!opponentName) return;

        const newOpponentKey = `opponent${Date.now()}`;

        setOpponentData(prev => {
            const newOpponentData = {
                ...prev,
                [newOpponentKey]: {
                    name: opponentName,
                    arguments: []
                }
            };
            const currentOpponentKeys = Object.keys(prev);
            if (currentOpponentKeys.length === 0) {
                setSelectedCombination(newOpponentKey);
            } else if (currentOpponentKeys.length === 1) {
                setSelectedCombination('all_opponents');
            }
            return newOpponentData;
        });
    };

    const handleSaveArgument = (argToSave) => {
        if (argToSave.side === 'own') {
            const list = ownArguments;
            const setList = setOwnArguments;

            if (argToSave.id && !argToSave.isVirtual) {
                setList(list.map(arg => arg.id === argToSave.id ? argToSave : arg));
            } else {
                setList([...list, {
                  ...argToSave,
                  id: Date.now(),
                  isStrategicallyRelevant: argToSave.isStrategicallyRelevant || false
                }]);
            }
        } else {
            const opponentKey = argToSave.side;
            setOpponentData(prev => {
                const currentOpponent = prev[opponentKey];
                if (!currentOpponent) return prev;

                const updatedArguments = argToSave.id && !argToSave.isVirtual
                    ? currentOpponent.arguments.map(arg => arg.id === argToSave.id ? argToSave : arg)
                    : [...currentOpponent.arguments, {
                        ...argToSave,
                        id: Date.now(),
                        isStrategicallyRelevant: argToSave.isStrategicallyRelevant || false
                      }];

                return {
                    ...prev,
                    [opponentKey]: {
                        ...currentOpponent,
                        arguments: updatedArguments
                    }
                };
            });
        }
        setEditingArgument(null);
    };

    const handleDeleteArgument = (id, side) => {
        if (!window.confirm("Sind Sie sicher, dass Sie dieses Argument löschen möchten?")) return;

        if (side === 'own') {
            setOwnArguments(ownArguments.filter(arg => arg.id !== id));
        } else {
            setOpponentData(prev => {
                const currentOpponent = prev[side];
                if (!currentOpponent) return prev;

                return {
                    ...prev,
                    [side]: {
                        ...currentOpponent,
                        arguments: currentOpponent.arguments.filter(arg => arg.id !== id)
                    }
                };
            });
        }
    };

    const handleToggleStrategic = (argumentId, side) => {
        if (side === 'own') {
            setOwnArguments(prev =>
                prev.map(arg =>
                    arg.id === argumentId
                        ? { ...arg, isStrategicallyRelevant: !arg.isStrategicallyRelevant }
                        : arg
                )
            );
        } else {
            setOpponentData(prev => {
                const currentOpponent = prev[side];
                if (!currentOpponent) return prev;

                return {
                    ...prev,
                    [side]: {
                        ...currentOpponent,
                        arguments: currentOpponent.arguments.map(arg =>
                            arg.id === argumentId
                                ? { ...arg, isStrategicallyRelevant: !arg.isStrategicallyRelevant }
                                : arg
                        )
                    }
                };
            });
        }
    };

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="sticky top-0 bg-white/80 backdrop-blur-lg border-b border-gray-200/80 z-10">
                <div className="max-w-7xl mx-auto px-6 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <Button variant="ghost" size="icon" onClick={() => navigate(createPageUrl('KanzleiDashboard'))} className="w-9 h-9 rounded-full bg-gray-100 hover:bg-gray-200">
                                <ArrowLeft className="w-5 h-5 text-gray-700" />
                            </Button>
                            <div>
                                <h1 className="text-lg font-semibold text-gray-900">Argument Visualizer</h1>
                                <p className="text-sm text-gray-600">Zeitabhängige Analyse der Argumentationsstärke</p>
                            </div>
                        </div>
                        <div className="flex items-center gap-3">
                            <Button variant="outline" className="rounded-lg" onClick={handleAddOpponent}>
                                <Plus className="w-4 h-4 mr-2"/> Neuer Gegner
                            </Button>
                            <Button className="rounded-lg bg-blue-600 hover:bg-blue-700" onClick={() => setEditingArgument({ side: 'own', strength: 25, date: new Date().toISOString().split('T')[0], evidence: [], isStrategicallyRelevant: false })}>
                                <Plus className="w-4 h-4 mr-2"/> Neues Argument
                            </Button>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <main className="max-w-7xl mx-auto p-6 space-y-8">
                {/* Tabs */}
                <div className="flex justify-center">
                    <Tabs value={activeTab} onValueChange={setActiveTab}>
                        <TabsList className="bg-gray-200/70 p-1 rounded-xl">
                            <TabsTrigger value="own" className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-lg px-4">
                                <TrendingUp className="w-4 h-4 mr-2 text-green-600"/> Eigene Seite
                            </TabsTrigger>
                            {Object.keys(opponentData).length > 0 && (
                                <TabsTrigger value="combined" className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-lg px-4">
                                    <BarChart3 className="w-4 h-4 mr-2 text-blue-600"/> Kombiniert
                                </TabsTrigger>
                            )}
                            {Object.entries(opponentData).map(([key, opponent]) => (
                                <TabsTrigger key={key} value={key} className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-lg px-4">
                                    <TrendingDown className="w-4 h-4 mr-2 text-red-600"/> {opponent.name}
                                </TabsTrigger>
                            ))}
                        </TabsList>
                    </Tabs>
                </div>

                {/* Kombinierte Ansicht: Auswahl des Gegners */}
                {activeTab === 'combined' && Object.keys(opponentData).length > 0 && (
                    <div className="flex justify-center">
                        <div className="flex items-center gap-3 bg-white p-3 rounded-lg border border-gray-200">
                            <span className="text-sm font-medium text-gray-700">Vergleich mit:</span>
                            <Tabs value={selectedCombination || ''} onValueChange={setSelectedCombination}>
                                <TabsList className="bg-gray-100 p-1 rounded-lg">
                                    {Object.entries(opponentData).map(([key, opponent]) => (
                                        <TabsTrigger key={key} value={key} className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-md px-3 text-sm">
                                            {opponent.name}
                                        </TabsTrigger>
                                    ))}
                                    {Object.keys(opponentData).length > 1 && (
                                        <TabsTrigger value="all_opponents" className="data-[state=active]:bg-white data-[state=active]:shadow-sm rounded-md px-3 text-sm">
                                            Alle Gegner
                                        </TabsTrigger>
                                    )}
                                </TabsList>
                            </Tabs>
                        </div>
                    </div>
                )}

                {/* Graphen */}
                <div>
                    <AnimatePresence mode="wait">
                        <motion.div key={activeTab + selectedCombination} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
                            {activeTab === 'own' && (
                                <ArgumentGraph
                                    arguments={ownArguments}
                                    side="own"
                                    ownArguments={ownArguments}
                                    opponentData={opponentData}
                                />
                            )}
                            {activeTab === 'combined' && selectedCombination && (
                                <ArgumentGraph
                                    arguments={
                                        selectedCombination === 'all_opponents'
                                        ? [...ownArguments, ...Object.values(opponentData).flatMap(opp => opp.arguments)]
                                        : [...ownArguments, ...(opponentData[selectedCombination]?.arguments || [])]
                                    }
                                    side="combined"
                                    ownArguments={ownArguments}
                                    opponentData={opponentData}
                                    selectedCombination={selectedCombination}
                                />
                            )}
                            {Object.keys(opponentData).includes(activeTab) && (
                                <ArgumentGraph
                                    arguments={opponentData[activeTab]?.arguments || []}
                                    side={activeTab}
                                    ownArguments={ownArguments}
                                    opponentData={opponentData}
                                />
                            )}
                        </motion.div>
                    </AnimatePresence>
                </div>

                {/* Argument Listen */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <div className="space-y-4">
                        <h3 className="text-lg font-semibold text-gray-800">Eigene Argumente</h3>
                        {ownArguments.map(arg => <ArgumentCard key={arg.id} argument={arg} onEdit={setEditingArgument} onDelete={handleDeleteArgument} onToggleStrategic={handleToggleStrategic}/>)}
                    </div>
                    <div className="space-y-4">
                        <h3 className="text-lg font-semibold text-gray-800">Gegnerische Argumente</h3>
                        {Object.entries(opponentData).map(([key, opponent]) => (
                            <div key={key} className="space-y-4">
                                <h4 className="text-md font-medium text-gray-700 border-l-4 border-red-400 pl-3">{opponent.name}</h4>
                                {opponent.arguments.map(arg => (
                                    <ArgumentCard key={arg.id} argument={arg} onEdit={setEditingArgument} onDelete={handleDeleteArgument} onToggleStrategic={handleToggleStrategic}/>
                                ))}
                            </div>
                        ))}
                    </div>
                </div>
            </main>

            {/* Dialog für Argumente */}
            <AnimatePresence>
                {editingArgument && (
                    <Dialog open={!!editingArgument} onOpenChange={() => setEditingArgument(null)}>
                        <DialogContent className="sm:max-w-[425px] bg-white rounded-2xl">
                            <DialogHeader>
                                <DialogTitle>{editingArgument.id && !editingArgument.isVirtual ? 'Argument bearbeiten' : 'Neues Argument erstellen'}</DialogTitle>
                                <DialogDescription>Füllen Sie die Details für das Argument aus.</DialogDescription>
                            </DialogHeader>
                            <div className="py-4 space-y-4">
                                <div className="space-y-2">
                                    <Label htmlFor="title">Titel</Label>
                                    <Input id="title" value={editingArgument.title || ''} onChange={e => setEditingArgument({...editingArgument, title: e.target.value})} className="rounded-lg" disabled={editingArgument.isVirtual}/>
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="summary">Zusammenfassung</Label>
                                    <Textarea id="summary" value={editingArgument.summary || ''} onChange={e => setEditingArgument({...editingArgument, summary: e.target.value})} className="rounded-lg" disabled={editingArgument.isVirtual}/>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label htmlFor="date">Datum</Label>
                                        <Input id="date" type="date" value={editingArgument.date || ''} onChange={e => setEditingArgument({...editingArgument, date: e.target.value})} className="rounded-lg" disabled={editingArgument.isVirtual}/>
                                    </div>
                                    <div className="space-y-2">
                                        <Label htmlFor="side">Seite</Label>
                                        <select id="side" value={editingArgument.side || 'own'} onChange={e => setEditingArgument({...editingArgument, side: e.target.value})} className="w-full p-2 border border-gray-200 rounded-lg" disabled={editingArgument.isVirtual}>
                                            <option value="own">Eigene Seite</option>
                                            {Object.entries(opponentData).map(([key, opponent]) => (
                                                <option key={key} value={key}>{opponent.name}</option>
                                            ))}
                                        </select>
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label>Stärke: {editingArgument.strength}</Label>
                                    <Slider value={[editingArgument.strength]} onValueChange={([val]) => setEditingArgument({...editingArgument, strength: val})} max={MAX_STRENGTH} step={1} disabled={editingArgument.isVirtual}/>
                                </div>

                                <div className="flex items-center space-x-2">
                                    <input
                                        type="checkbox"
                                        id="strategic"
                                        checked={editingArgument.isStrategicallyRelevant || false}
                                        onChange={e => setEditingArgument({...editingArgument, isStrategicallyRelevant: e.target.checked})}
                                        disabled={editingArgument.isVirtual}
                                        className="rounded border-gray-300 text-purple-600 focus:ring-purple-500"
                                    />
                                    <Label htmlFor="strategic" className="flex items-center gap-2">
                                        <Zap className="w-4 h-4 text-purple-600" />
                                        Strategisch relevantes Argument (bekommt Beweisstrang)
                                    </Label>
                                </div>
                            </div>
                            <DialogFooter>
                                <Button type="button" variant="outline" onClick={() => setEditingArgument(null)}>Abbrechen</Button>
                                <Button type="submit" onClick={() => handleSaveArgument(editingArgument)} disabled={editingArgument.isVirtual}>Speichern</Button>
                            </DialogFooter>
                        </DialogContent>
                    </Dialog>
                )}
            </AnimatePresence>
        </div>
    );
}
