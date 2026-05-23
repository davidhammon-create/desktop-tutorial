
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Sparkles, RefreshCw, Target, AlertTriangle, TrendingUp, Lock } from "lucide-react";
import { Button } from "@/components/ui/button";

/**
 * Gegner-Strategie Dashboard
 * - Analysiert gegnerische Argumente & Fristen
 * - Erstellt Gegen-Schachzug-Matrix (Gegner-Arg vs. Eigener-Beweis)
 * - KI-gestützte taktische Empfehlungen
 * - Integration mit Prozess-Zeitachse
 */

function EffectivenessMatrix({ gegnerArgs, evidence, matrix }) {
  if (!matrix || matrix.length
