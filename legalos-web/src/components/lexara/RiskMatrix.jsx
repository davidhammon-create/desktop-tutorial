
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { RefreshCw, Loader2 } from "lucide-react";

const RISK_ZONES = [
  { x: [0, 50], y: [0, 33], color: "bg-green-100", label: "Niedrig" },
  { x: [50, 100], y: [0, 33], color: "bg-yellow-100", label: "Mittel-Niedrig" },
  { x: [0, 50], y: [33, 67], color: "bg-yellow-100", label: "Mittel-Niedrig" },
  { x: [50, 100], y: [33, 67], color: "bg-orange-100", label: "Mittel" },
  { x: [0, 50], y: [67, 100], color: "bg-orange-100", label: "Mittel-Hoch" },
  { x: [50, 100], y: [67, 100], color: "bg-red-100", label: "Hoch" },
];

function RiskZoneGrid({ width, height }) {
  return (
    <svg width={width} height={height} className="absolute inset-0">
      {RISK_ZONES.map((zone, i) => (
        <rect
          key={i}
          x={(zone.x[0] / 100) * width}
          y={height - (zone.y[1] / 100) * height}
          width={((zone.x[1] - zone.x[0]) / 100) * width}
          height={((zone.y[1] - zone.y[0]) / 100) * height}
          className={zone.color}
          opacity={0.3}
        />
      ))}
      {/* Grid lines */}
      <line x1={width / 2} y1={0} x2={width / 2} y2={height} stroke="#e5e7eb" strokeWidth={1} strokeDasharray="4" />
      <line x1={0} y1={height / 3} x2={width} y2={height / 3} stroke="#e5e7eb" strokeWidth={1} strokeDasharray="4" />
      <line x1={0} y1={(2 * height) / 3} x2={width} y2={(2 * height) / 3} stroke="#e5e7eb" strokeWidth={1} strokeDasharray="4" />
    </svg>
  );
}

export default function RiskMatrix({ caseId, caseData }) {
  const [args, setArgs] = useState([]);
  const [ratings, setRatings] = useState({});
  const [loading, setLoading] = useState(true);
  const [analyzing, setAnalyzing] = useState(false);
  const [error, setError] = useState(null);

  const matrixWidth = 600;
  const matrixHeight = 450;
  const padding = 60;
  const innerWidth = matrixWidth - 2 * padding;
  const innerHeight = matrixHeight - 2 * padding;

  useEffect(() => {
    loadArguments();
  }, [caseId]);

  const loadArguments = async () => {
    setLoading(true);
    try {
      const data = await base44.entities.Argument.filter({ case_id: caseId });
      setArgs(data);
    } catch (err) {
      setError("Fehler beim Laden der Argumente");
    } finally {
      setLoading(false);
    }
  };

  const analyzeRisks = async () => {
    if (args.length
