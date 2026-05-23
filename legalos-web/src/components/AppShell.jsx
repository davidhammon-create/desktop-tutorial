
/**
 * AppShell.jsx — Haupt-Layout-Wrapper der gesamten App
 *
 * Struktur:
 *   ┌─ <header> ─────────────────────────────────────────────────────┐
 *   │  Logo · Nav-Tabs · JurisdictionToggle · User-Menü              │
 *   └────────────────────────────────────────────────────────────────┘
 *   ┌─ <aside> Sidebar ──┬─ <main> Seiteninhalt (<Outlet>) ─────────┐
 *   │  Kontextabhängige  │  Wird durch React Router befüllt          │
 *   │  Navigation pro    │  (alle Seiten aus App.jsx)                │
 *   │  Modul             │                                           │
 *   └────────────────────┴───────────────────────────────────────────┘
 *
 * Wichtige Konzepte:
 *   - NAV_ITEMS:   Haupt-Navigationspunkte in der Toolbar
 *   - SIDEBAR_MAP: Kontextuelle Sidebar-Links je Modul (Schlüssel = Pfad-Präfix)
 *   - "lexara_goto_step" CustomEvent: Sidebar-Links dispatchen dieses Event,
 *     damit CaseDetail.jsx direkt auf den gewünschten Tab (1–9) springen kann.
 *
 * Design:
 *   Alle Farben über das C-Objekt zentral definiert (SwiftUI/Großkanzlei-Palette).
 *   Button-Styles werden per inline-style gesetzt, damit der globale CSS-Override
 *   in index.css nicht greift (Toolbar-Buttons sind keine normalen Formular-Buttons).
 */

import { useState } from "react";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { base44 } from "@/api/base44Client";
import { useAuth } from "@/lib/AuthContext";
import {
  Scale, MessageSquare, Users, Bot, LayoutDashboard,
  BarChart2, Sword, CheckSquare, Calendar, LogOut, ChevronDown,
  ChevronRight, FileText, Gavel, Brain, AlertTriangle, Activity,
  TrendingUp, ClipboardList, Archive, Clock, UserCheck, Search,
  BookOpen, Layers, BarChart, Settings
} from "lucide-react";
import JurisdictionToggle from "./JurisdictionToggle";

const C = {
  bg:         "#F2F2F7",   // systemGroupedBackground
  toolbar:    "rgba(248,248,248,0.96)",
  sidebar:    "rgba(245,245,245,0.98)",
  separator:  "rgba(0,0,0,0.08)",
  label:      "#1C1C1E",
  label2:     "#636366",
  label3:     "#AEAEB2",
  emerald:    "#1DB954",
  emeraldDim: "rgba(29,185,84,0.11)",
  emeraldText:"#166F38",
  content:    "#EBEBF0",
};

const NAV_ITEMS = [
  { path: "/",                     label: "Übersicht",    icon: LayoutDashboard, exact: true },
  { path: "/lexara",               label: "Lexara",       icon: Scale },
  { path: "/richterprofile",       label: "Beteiligte",   icon: Users },
  { path: "/aufgaben",             label: "Aufgaben",     icon: CheckSquare },
  { path: "/zeitleiste",           label: "Fristen",      icon: Calendar },
  { path: "/cockpit",              label: "Cockpit",      icon: Activity },
  { path: "/analytik",             label: "Analytik",     icon: BarChart2 },
  { path: "/strategic-analysis",   label: "Strategie",    icon: Sword },
  { path: "/chat/fall-assistent",  label: "KI-Assistent", icon: MessageSquare },
  { path: "/plattform-agent",      label: "Agent",        icon: Bot },
];

const SIDEBAR_MAP = {
  "/lexara": {
    title: "Fallverwaltung",
    sections: [
      { label: "Fallübersicht", items: [
        { label: "Alle Fälle", icon: Layers, path: "/lexara" },
        { label: "Neuer Fall", icon: FileText, path: "/lexara?new=1" },
      ]},
      { label: "Fall-Schritte", items: [
        { label: "1 · Fallerfassung",   icon: ClipboardList, step: 1 },
        { label: "2 · Fallsubstanz",    icon: FileText,      step: 2 },
        { label: "3 · Gegneranalyse",   icon: Search,        step: 3 },
        { label: "4 · Rechtl. Analyse", icon: BookOpen,      step: 4 },
        { label: "5 · Strategie",       icon: Sword,         step: 5 },
        { label: "6 · Risiko",          icon: AlertTriangle, step: 6 },
        { label: "7 · Simulation",      icon: Brain,         step: 7 },
        { label: "8 · Aktion",          icon: Gavel,         step: 8 },
        { label: "9 · Cockpit",         icon: Activity,      step: 9 },
        { label: "10 · Abschluss",      icon: Archive,       step: 10 },
        { label: "11 · KI-Protokoll",   icon: BarChart,      step: 11 },
      ]},
    ],
  },
  "/richterprofile": {
    title: "Prozessbeteiligte",
    sections: [{ label: "Kategorien", items: [
      { label: "Alle Profile",         icon: Users,       path: "/richterprofile" },
      { label: "Richter",              icon: Gavel,       path: "/richterprofile?kat=Richter" },
      { label: "Anwälte & Kanzleien",  icon: UserCheck,   path: "/richterprofile?kat=Anwalt" },
      { label: "Sachverständige",      icon: BookOpen,    path: "/richterprofile?kat=Sachverständiger" },
      { label: "Zeugen",               icon: MessageSquare,path: "/richterprofile?kat=Zeuge" },
    ]}],
  },
  "/aufgaben": {
    title: "Aufgaben",
    sections: [{ label: "Filter", items: [
      { label: "Alle Aufgaben",  icon: CheckSquare, path: "/aufgaben" },
      { label: "Offen",          icon: Clock,       path: "/aufgaben?status=offen" },
      { label: "In Bearbeitung", icon: Activity,    path: "/aufgaben?status=in_bearbeitung" },
      { label: "Erledigt",       icon: Archive,     path: "/aufgaben?status=erledigt" },
    ]}],
  },
  "/zeitleiste": {
    title: "Fristenverwaltung",
    sections: [{ label: "Ansicht", items: [
      { label: "Alle Fristen", icon: Calendar,      path: "/zeitleiste" },
      { label: "Überfällig",   icon: AlertTriangle, path: "/zeitleiste?filter=overdue" },
      { label: "Diese Woche",  icon: Clock,         path: "/zeitleiste?filter=week" },
    ]}],
  },
  "/cockpit":  { title: "Kanzlei-Cockpit",    sections: [{ label: "Module", items: [
    { label: "Dashboard", icon: Activity,  path: "/cockpit" },
    { label: "Analytik",  icon: BarChart2, path: "/analytik" },
  ]}]},
  "/analytik": { title: "Analytik", sections: [{ label: "Berichte", items: [
    { label: "Überblick",      icon: BarChart2,   path: "/analytik" },
    { label: "KI-Performance", icon: Brain,       path: "/analytik?view=ki" },
    { label: "Erfolgsquoten",  icon: TrendingUp,  path: "/analytik?view=erfolg" },
  ]}]},
  "/strategic-analysis": { title: "Strategische Analyse", sections: [{ label: "Module", items: [
    { label: "Sun Tzu / Machiavelli", icon: Sword,  path: "/strategic-analysis" },
    { label: "Gegner-Profil",         icon: Search, path: "/strategic-analysis?tab=gegner" },
  ]}]},
  "/chat/fall-assistent": { title: "KI-Assistent", sections: [{ label: "Chats", items: [
    { label: "Fall-Assistent", icon: MessageSquare, path: "/chat/fall-assistent" },
  ]}]},
  "/plattform-agent": { title: "Plattform-Agent", sections: [{ label: "Agenten", items: [
    { label: "Plattform-Optimierer", icon: Bot, path: "/plattform-agent" },
  ]}]},
  "/": { title: "Übersicht", sections: [{ label: "Navigation", items: [
    { label: "Startseite", icon: LayoutDashboard, path: "/" },
    { label: "Onboarding", icon: Settings,        path: "/onboarding" },
  ]}]},
};

const SF = { fontFamily: "-apple-system,'SF Pro Text','Helvetica Neue',Arial,sans-serif" };

export default function AppShell() {
  const location  = useLocation();
  const navigate  = useNavigate();
  const { currentUser } = useAuth();
  const [userMenuOpen,      setUserMenuOpen]      = useState(false);
  const [sidebarCollapsed,  setSidebarCollapsed]  = useState(false);

  const isActive = (item) =>
    item.exact ? location.pathname
