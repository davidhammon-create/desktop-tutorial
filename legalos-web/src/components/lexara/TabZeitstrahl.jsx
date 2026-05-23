
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import {
  Plus, Calendar, FileText, Edit2, Trash2, Upload, X, Sparkles,
  ChevronDown, ChevronUp, Image, Video, Link2, AlertTriangle, CheckCircle, Clock, ZoomIn
} from "lucide-react";
import { Button } from "@/components/ui/button";

// ── CONFIG ───────────────────────────────────────────────────────────────────

const CATEGORY_CONFIG = {
  vertrag:      { label: "Vertrag",       color: "#34C759", bg: "#e8f5e9" },
  zahlung:      { label: "Zahlung",       color: "#007AFF", bg: "#e3f2fd" },
  klage:        { label: "Klage",         color: "#FF3B30", bg: "#fce4ec" },
  urteil:       { label: "Urteil",        color: "#5856D6", bg: "#e8eaf6" },
  frist:        { label: "Frist",         color: "#FF9500", bg: "#fff8e1" },
  verhandlung:  { label: "Verhandlung",   color: "#AF52DE", bg: "#f3e5f5" },
  gutachten:    { label: "Gutachten",     color: "#00BCD4", bg: "#e0f7fa" },
  korrespondenz:{ label: "Korrespondenz", color: "#8BC34A", bg: "#f1f8e9" },
  foto:         { label: "Foto",          color: "#FF6B35", bg: "#fff3ee" },
  video:        { label: "Video",         color: "#C0392B", bg: "#fde8e8" },
  sonstiges:    { label: "Sonstiges",     color: "#9E9E9E", bg: "#fafafa" },
};

const IMPORTANCE_CONFIG = {
  kritisch: { label: "Kritisch", color: "#FF3B30" },
  hoch:     { label: "Hoch",     color: "#FF9500" },
  mittel:   { label: "Mittel",   color: "#007AFF" },
  niedrig:  { label: "Niedrig",  color: "#8E8E93" },
};

const MEDIA_TYPE = {
  image: ["jpg","jpeg","png","gif","webp","heic","bmp","tiff","svg"],
  video: ["mp4","mov","avi","mkv","webm","wmv","flv","m4v"],
  pdf:   ["pdf"],
};

function getMediaType(url = "", mime = "") {
  const ext = url.split(".").pop().toLowerCase().split("?")[0];
  if (MEDIA_TYPE.image.includes(ext) || mime.startsWith("image/")) return "image";
  if (MEDIA_TYPE.video.includes(ext) || mime.startsWith("video/")) return "video";
  if (ext === "pdf" || mime === "application/pdf") return "pdf";
  return "file";
}

function MediaIcon({ type, size = 12 }) {
  if (type === "image") return <Image style={{ width: size, height: size, color: "#FF6B35" }} />;
  if (type === "video") return <Video style={{ width: size, height: size, color: "#C0392B" }} />;
  return <FileText style={{ width: size, height: size, color: "#555" }} />;
}

// ── RELATION BADGE ────────────────────────────────────────────────────────────

function RelationBadge({ type }) {
  if (type === "beweist")   return <span className="text-[9px] px-1.5 py-0.5 rounded bg-green-100 text-green-700 font-semibold flex items-center gap-0.5"><CheckCircle style={{width:9,height:9}}/> bestätigt</span>;
  if (type === "widerlegt") return <span className="text-[9px] px-1.5 py-0.5 rounded bg-red-100 text-red-600 font-semibold flex items-center gap-0.5"><AlertTriangle style={{width:9,height:9}}/> widerlegt</span>;
  if (type === "überschneidet") return <span className="text-[9px] px-1.5 py-0.5 rounded bg-amber-100 text-amber-700 font-semibold flex items-center gap-0.5"><Link2 style={{width:9,height:9}}/> überschneidet</span>;
  return null;
}

// ── CONTRACT CHECKLIST ────────────────────────────────────────────────────────

function ContractChecklist({ checklist, onChange }) {
  return (
    <div className="mt-2 space-y-1">
      <p className="text-[10px] font-semibold text-gray-400 uppercase mb-1">Vertragspunkte / Erfüllung</p>
      {checklist.map((item, i) => (
        <div key={i} className="flex items-start gap-2 bg-gray-50 rounded-lg p-2">
          <button onClick={() => onChange(checklist.map((c,j) => j
