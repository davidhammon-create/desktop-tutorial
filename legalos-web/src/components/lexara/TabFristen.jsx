
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Plus, Trash2, Check, X, ChevronDown, ChevronUp, Sparkles, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";

const FRIST_TYPES = ["Berufungsfrist","Berufungsbegründung","Revisionsfrist","Klagebegründung","Schriftsatzfrist","Widerspruch Mahnbescheid","Einspruch Versäumnisurteil","eV-Antragsfrist","Verjährungsfrist","Klagefrist KSchG","BR-Anzeige §102 BetrVG","Vollstreckungsfristen","Sonstige"];
const FRIST_REF = [["Berufungsfrist","§517 ZPO","1 Monat","~60–100%"],["Berufungsbegründung","§520 ZPO","2 Monate","~40–70%"],["Revisionsfrist","§548 ZPO","1 Monat","~100–100%"],["Klagebegründung","§276 ZPO","Richterlich","~20–50%"],["Schriftsatzfrist","§296 ZPO","Richterlich","~10–30%"],["Widerspruch Mahnbescheid","§694 ZPO","2 Wochen","~80–100%"],["Einspruch Versäumnisurteil","§339 ZPO","2 Wochen","~90–100%"],["eV-Antragsfrist","§940 ZPO","Fallabhängig","~30–70%"],["Verjährungsfrist","§§195ff. BGB","3 Jahre","~100–100%"],["Klagefrist KSchG","§4 KSchG","3 Wochen","~100–100%"],["BR-Anzeige §102 BetrVG","§102 BetrVG","1 Woche","+40–20%"],["Vollstreckungsfristen","§§767ff. ZPO","Variabel","~30–60%"]];
const EMPTY = { title:"", frist_type:"eV-Antragsfrist", paragraph:"", due_date:"", responsible:"", side:"Eigene", status:"offen", prognoseabzug:"" };

function daysUntil(d) { if(!d) return null; return Math.ceil((new Date(d)-new Date())/(1000*60*60*24)); }
function FristDot({ days, status }) {
  if(status==="versaeumt") return <div className="w-2 h-2 rounded-full bg-gray-300" />;
  if(status==="erledigt") return <div className="w-2 h-2 rounded-full bg-green-300" />;
  if(days
