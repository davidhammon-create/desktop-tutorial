
/**
 * StrategieCheckliste.jsx
 * Geführte strategische Checkliste basierend auf Sun Tzu, Machiavelli,
 * Rspr., Lit. und allen Fall-Ergebnissen (Prognose, Argumente, Beweise,
 * Fristen, Gegnerverhalten). Enthält interaktive 2D/3D-Funktionsvisualisierungen.
 */
import { useState, useEffect, useRef } from "react";
import { base44 } from "@/api/base44Client";
import { invokeLLM } from "@/lib/kiProvider";
import { Button } from "@/components/ui/button";
import {
  RadarChart, PolarGrid, PolarAngleAxis, Radar, ResponsiveContainer,
  LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ReferenceLine,
  ScatterChart, Scatter, ZAxis, Legend
} from "recharts";
import {
  CheckCircle2, Circle, ChevronDown, ChevronUp, Sword, BookOpen,
  TrendingUp, AlertTriangle, Zap, Eye, RefreshCw, BarChart3
} from "lucide-react";

// ── Sun Tzu & Machiavelli Prinzipien-Bibliothek ──────────────────────
const PRINZIPIEN = {
  suntzu: [
    { id: "st1", titel: "Kenne deinen Feind, kenne dich selbst", zitat: "Wer den Feind und sich selbst kennt, wird in hundert Schlachten nicht scheitern.", kategorie: "Analyse", norm: "§ 138 ZPO (Wahrheitspflicht), § 282 ZPO (Prozessförderungspflicht)" },
    { id: "st2", titel: "Angriff auf Schwachstellen", zitat: "Greife Stärke nicht frontal an — umgehe sie und schlage bei der Schwäche.", kategorie: "Taktik", norm: "§ 138 ZPO, Widerklage § 33 ZPO" },
    { id: "st3", titel: "Überraschungsmoment", zitat: "Reagiere auf Veränderungen schneller als der Gegner erwartet.", kategorie: "Prozess", norm: "§ 296 ZPO (verspätetes Vorbringen), § 139 ZPO (richterliche Hinweispflicht)" },
    { id: "st4", titel: "Psychologische Kriegsführung", zitat: "Der überlegene Krieger gewinnt, bevor er kämpft.", kategorie: "Verhandlung", norm: "§ 278 ZPO (Güteverhandlung), § 42 ZPO (Befangenheit)" },
    { id: "st5", titel: "Ressourcenschonung", zitat: "Ein langer Krieg nützt niemandem — zermürbe den Gegner ohne dich selbst zu erschöpfen.", kategorie: "Kosten", norm: "§§ 91 ff. ZPO (Kostenrecht), § 93 ZPO (sofortige Anerkennung)" },
    { id: "st6", titel: "Flexible Strategie (Wasser-Prinzip)", zitat: "Wasser hat keine feste Form — passe deine Strategie der Lage an.", kategorie: "Adaptiv", norm: "§ 263 ZPO (Klageänderung), § 264 ZPO (keine Klageänderung)" },
  ],
  machiavelli: [
    { id: "mv1", titel: "Stärke vor Recht", zitat: "Der Fürst muss gleichzeitig Löwe und Fuchs sein.", kategorie: "Macht", norm: "§ 935 ZPO (einstweilige Verfügung), §§ 916 ff. ZPO (Arrest)" },
    { id: "mv2", titel: "Initiale Entscheidungsschnelligkeit", zitat: "Ein langsamer Angriff gibt dem Gegner Zeit — handle zuerst und entscheide.", kategorie: "Prozess", norm: "§ 688 ZPO (Mahnverfahren), §§ 935 ff. ZPO (einstweiliger Rechtsschutz)" },
    { id: "mv3", titel: "Koalitionen schmieden", zitat: "Man soll niemals glauben, man könne immer sichere Entschlüsse fassen.", kategorie: "Netzwerk", norm: "§ 72 ZPO (Streitverkündung), § 64 ZPO (Hauptintervention)" },
    { id: "mv4", titel: "Erschütterung des Vertrauens", zitat: "Der kluge Herrscher muss sein Wort nicht halten.", kategorie: "Psychologie", norm: "§ 138 ZPO (Ausforschungsbeweis), § 421 ZPO (Vorlegung Urkunde)" },
    { id: "mv5", titel: "Erschöpfungstaktik", zitat: "Halte die Gegner in einem Kriegszustand, ohne dich erschöpfen zu lassen.", kategorie: "Kosten", norm: "§§ 91a ZPO (Kostenentscheidung), § 281 ZPO (Verweisung)" },
    { id: "mv6", titel: "Die Wahrheit dosiert einsetzen", zitat: "Täusche so viel, dass der Gegner das Echte nicht mehr erkennt.", kategorie: "Taktik", norm: "§ 402 ZPO (Sachverständigenbeweis), § 373 ZPO (Zeugenbeweis)" },
  ]
};

// ── Mathematische Hilfsfunktionen für Charts ──────────────────────────
function sinData(prognose, n = 40) {
  const amp = prognose / 2;
  const baseline = prognose;
  return Array.from({ length: n }, (_, i) => ({
    t: +(i * 0.4).toFixed(1),
    y: +(baseline + amp * Math.sin(i * 0.4)).toFixed(1),
    yLower: +(baseline - amp * 0.4 * Math.sin(i * 0.4 + Math.PI / 3)).toFixed(1),
  }));
}

function linearData(m, b, n = 20) {
  return Array.from({ length: n }, (_, x) => ({
    x,
    y: +(m * x + b).toFixed(1),
  }));
}

function scatterData3D(args, evidence) {
  return args.slice(0, 12).map((a, i) => {
    const evCount = evidence.filter(e => e.argument_id
