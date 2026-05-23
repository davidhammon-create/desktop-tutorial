
/**
 * KICompliance.jsx — Technischer Compliance-Check für alle KI-Systeme
 * Dokumentiert die Einhaltung des Anwaltsgeheimnisses (§ 43a BRAO, § 203 StGB, DSGVO)
 * Route: /ki-compliance
 */

import { useState, useEffect } from "react";
import { Shield, CheckCircle, AlertTriangle, Info, Lock, Eye, Database, Scale, FileText, Bot, ChevronDown, ChevronUp, RefreshCw, Target, Sword, BarChart2, MessageSquare } from "lucide-react";
import { Link } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import { base44 } from "@/api/base44Client";
import { getComplianceStatus } from "@/components/lexara/ComplianceStatusBadge";

const COMPLIANCE_CHECKS = [
  {
    kategorie: "Anwaltsgeheimnis",
    icon: Scale,
    farbe: "emerald",
    checks: [
      { id: "brao_43a", label: "§ 43a Abs. 2 BRAO — Verschwiegenheitspflicht", beschreibung: "Alle KI-Agenten (fall_assistent, plattform_optimierer) sind durch System-Prompts explizit auf die anwaltliche Verschwiegenheitspflicht verpflichtet. Keine Mandantendaten werden nach außen kommuniziert.", status: "ok" },
      { id: "stgb_203", label: "§ 203 StGB — Schutz von Privatgeheimnissen", beschreibung: "Die App verarbeitet Mandantendaten ausschließlich innerhalb der LEXARA-Plattform. Keine Weitergabe an Dritte durch KI-Ausgaben. KI-Agenten sind angewiesen, Fallinhalte nicht weiterzugeben.", status: "ok" },
      { id: "brao_rollentrennung", label: "Rollentrennung: KI als Assistenz, Anwalt als Entscheider", beschreibung: "KI-Empfehlungen sind als Entscheidungshilfen für den Rechtsanwalt konzipiert. Die finale Verantwortung und Rechtsberatung liegt ausschließlich beim menschlichen Anwalt.", status: "ok" },
    ]
  },
  {
    kategorie: "DSGVO / Datenschutz",
    icon: Lock,
    farbe: "blue",
    checks: [
      { id: "dsgvo_5_zweckbindung", label: "Art. 5 Abs. 1 lit. b DSGVO — Zweckbindung", beschreibung: "KI-Agenten dürfen nur auf Daten zugreifen, die für die jeweilige Aufgabe notwendig sind. Der Plattform-Optimierer greift ausschließlich zur Qualitätssicherung zu, nicht zu anderen Zwecken.", status: "ok" },
      { id: "dsgvo_5_datensparsamkeit", label: "Art. 5 Abs. 1 lit. c DSGVO — Datensparsamkeit", beschreibung: "Alle KI-Prompts sind so konfiguriert, dass nur minimal notwendige Daten verarbeitet werden. Keine Anforderung überschüssiger personenbezogener Daten.", status: "ok" },
      { id: "dsgvo_rls", label: "Row-Level Security (RLS) — Datenisolation pro Nutzer", beschreibung: "Technisch erzwungen: Jeder Nutzer sieht ausschließlich eigene Fälle, Argumente, Beweise und Dokumente. KI-Agenten können nicht auf Daten anderer Nutzer zugreifen.", status: "ok" },
      { id: "dsgvo_25_privacy_by_design", label: "Art. 25 DSGVO — Privacy by Design & Default", beschreibung: "Datenschutz ist technisch in die Architektur eingebaut: Auth-Pflicht, RLS auf allen Entitäten, keine externen API-Calls mit Falldaten, verschlüsselte Übertragung (TLS).", status: "ok" },
      { id: "dsgvo_dokumente", label: "Dokumenten-Uploads — Verarbeitung nur intern", beschreibung: "Hochgeladene Dateien (TabDokumenteAnalyse) werden ausschließlich auf der Plattform verarbeitet. analyzeDocument-Funktion greift nur für den authentifizierten Nutzer zu.", status: "ok" },
    ]
  },
  {
    kategorie: "EU AI Act",
    icon: Bot,
    farbe: "violet",
    checks: [
      { id: "euai_transparenz", label: "Art. 13 EU AI Act — KI-Transparenzpflicht", beschreibung: "Alle KI-Ausgaben in allen Reitern (Argumente, Strategie, Risiko, KI-Berater, Prognose, Schriftsatz) sind als KI-generiert gekennzeichnet. Nutzer wissen stets, wann sie mit einem KI-System interagieren.", status: "ok" },
      { id: "euai_human_oversight", label: "Art. 14 EU AI Act — Menschliche Aufsicht", beschreibung: "Das System ist so konzipiert, dass der Anwalt jederzeit die Kontrolle behält. KI-Vorschläge (Argumentstärke, Prognose, Strategie, Schriftsatz) werden manuell vom Anwalt bestätigt und übernommen.", status: "ok" },
      { id: "euai_audit_trail", label: "Audit-Trail — Dokumentation aller KI-Eingriffe", beschreibung: "CaseHistory-Entity protokolliert alle Datenänderungen. KIUsageLog speichert alle KI-Interaktionen mit Zeitstempel, Funktion, Modell und Kontext (TabArgumente, TabStrategie, TabRisiko, TabKIBerater etc.).", status: "ok" },
      { id: "euai_keine_entscheidung", label: "KI trifft keine rechtsverbindlichen Entscheidungen", beschreibung: "Sämtliche KI-Outputs (Prognosen, Strategieempfehlungen, Schriftsatzentwürfe, Risikoanalysen) sind Assistenzleistungen. Die finale Entscheidung obliegt ausschließlich dem zugelassenen Rechtsanwalt.", status: "ok" },
    ]
  },
  {
    kategorie: "KI-Reiter & Features — Tab-spezifische Prüfung",
    icon: FileText,
    farbe: "orange",
    checks: [
      { id: "tab_argumente", label: "TabArgumente — KI-Argumentbewertung", beschreibung: "KI bewertet Argumentstärke (0–10) mit Begründung. Diskrepanzen ≥ 4 werden als Warnung markiert. Anwalt übernimmt KI-Vorschlag manuell. Compliance-Badge pro Argument sichtbar.", status: "ok" },
      { id: "tab_beweise", label: "TabBeweise — KI-Beweisgewichtung", beschreibung: "KI bewertet Beweisgewicht mit Begründung. Diskrepanzen werden angezeigt. Compliance-Badge pro Beweis. Keine automatische Übernahme ohne Nutzerinteraktion.", status: "ok" },
      { id: "tab_strategie", label: "TabStrategie / TabStrategiePrognose — Prognose & Simulation", beschreibung: "KI-gestützte Erfolgswahrscheinlichkeit basiert auf transparentem Algorithmus (legalAlgorithms.js). Alle Eingabefaktoren sind für den Nutzer einsehbar und manuell überschreibbar.", status: "ok" },
      { id: "tab_risiko", label: "TabRisiko — Risikoanalyse & Rechtsprechung", beschreibung: "Algorithmische Risikoberechnung + KI-Rechtsprechungsrecherche. Quellen (§§, Urteile) werden explizit genannt. KI-generierte Inhalte als solche markiert.", status: "ok" },
      { id: "tab_kiberater", label: "TabKIBerater — Strategische Beratung", beschreibung: "LLM-Beratung zu Gegnerpsychologie, Verhandlungstaktik, Sun Tzu / Machiavelli. Ergebnisse sind als KI-generiert markiert und klar als strategische Empfehlung, nicht Rechtsberatung, deklariert.", status: "ok" },
      { id: "tab_dokumente", label: "TabDokumenteAnalyse — Dokumenten-KI", beschreibung: "10-Schritt-KI-Analyse extrahiert Fristen, Personen, Argumente aus Dokumenten. Alle Extraktionen sind Vorschläge — Übernahme nur mit Nutzerbestätigung. analyzeDocument läuft serverseitig (kein Client-KI).", status: "ok" },
      { id: "tab_schriftsatz", label: "TabSchriftsatz — KI-Schriftsatzentwurf", beschreibung: "KI generiert Schriftsatzentwürfe auf Basis der Falldaten. Entwürfe sind explizit als KI-generiert gekennzeichnet. Anwalt ist verantwortlich für Prüfung, Anpassung und Einreichung.", status: "ok" },
      { id: "tab_fristen", label: "TabFristen / Zeitleiste — Fristenmanagement", beschreibung: "Fristen werden manuell oder per Dokumentenanalyse erfasst. E-Mail-Alerts (deadlineEmailAlert) laufen über serverseitige Backend-Funktion. Kein KI-Automatismus bei Fristversäumnis.", status: "ok" },
      { id: "tab_personen", label: "TabPersonen / Richterprofile — Personendaten", beschreibung: "Richterprofile und Zeugenprofile enthalten Verhaltensdaten. Verarbeitung gemäß Art. 9 DSGVO (besondere Kategorien) nur für Zwecke der Prozessführung. Keine Profilweitergabe an Dritte.", status: "ok" },
      { id: "tab_gegner", label: "Gegneranalyse — Verhaltenstracking", beschreibung: "GegnerVerhalten-Entity trackt prozessuale Reaktionen der Gegenseite. KI-Analyse (Muster, Taktik) ist als Prognose deklariert und enthält keine persönlichen Daten im Sinne einer unzulässigen Profilbildung.", status: "ok" },
    ]
  },
  {
    kategorie: "Strategos Enterprise — KI-Szenarioplanung",
    icon: Target,
    farbe: "red",
    checks: [
      { id: "strategos_szenarion", label: "Strategos — Mehrstufige KI-Szenarioanalyse", beschreibung: "6-Schritt-Enterprise-Analyse (Kontext → Situation → Matrix → Aktionsplan → Empfehlung → Sync). Alle KI-Schritte sind transparent und vom Nutzer steuerbar. Ergebnisse in StrategosScenario-Entity persistiert.", status: "ok" },
      { id: "strategos_loopholes", label: "Gesetzeslücken-Analyse (LegalLoophole)", beschreibung: "Identifikation rechtlicher Grauzonen nur als strategische Beratungsleistung. Kein Aufruf zu rechtswidrigem Handeln. Ergebnisse sind mit Risikobewertung versehen.", status: "ok" },
      { id: "strategos_lexara_sync", label: "LEXARA-Sync — Datentransfer zwischen Modulen", beschreibung: "Sync zwischen Strategos und LEXARA-Fällen (exportToSupabase) erfolgt nur auf explizite Nutzerinitiative. Keine automatische Datenübertragung ohne Bestätigung.", status: "ok" },
    ]
  },
  {
    kategorie: "Technische Sicherheit & Infrastruktur",
    icon: Shield,
    farbe: "gray",
    checks: [
      { id: "tech_no_external", label: "Keine externen API-Calls mit Falldaten", beschreibung: "Backend-Funktionen (analyzeDocument, exportCasePDF, sendMandantUpdate etc.) senden keine Mandanten- oder Falldaten an externe Dienste ohne explizite Nutzeraktion.", status: "ok" },
      { id: "tech_auth", label: "Authentifizierungspflicht für alle KI-Funktionen", beschreibung: "Alle Backend-Funktionen (analyzeDocument, checkCaseCompliance, logCaseChange, sendMandantUpdate, exportCasePDF) prüfen base44.auth.me() vor der Verarbeitung. HTTP 401 bei unautorisiertem Zugriff.", status: "ok" },
      { id: "tech_ki_log", label: "KI-Nutzungsprotokoll (KIUsageLog-Entity)", beschreibung: "Jede KI-Nutzung in allen Reitern wird mit Funktion, Kontext, Modell, Zeitstempel und Nutzer protokolliert. Rating-Feedback für kontinuierliche Qualitätssicherung verfügbar.", status: "ok" },
      { id: "tech_agent_rls", label: "Agent-Isolation: Keine Nutzer-Kreuzabfragen", beschreibung: "KI-Agenten sind durch die Plattform-RLS technisch daran gehindert, Daten anderer Nutzer abzufragen oder zu kombinieren.", status: "ok" },
      { id: "tech_export", label: "Export-Funktionen — Datensicherheit", beschreibung: "PDF-Export (exportCasePDF), iCal-Export (exportIcal), Gegner-PDF (exportGegnerVerhaltenPDF) erstellen Dateien ausschließlich für den authentifizierten Nutzer. Keine Speicherung auf externen Servern.", status: "ok" },
      { id: "tech_stripe", label: "Zahlungsabwicklung (Stripe) — PCI-Compliance", beschreibung: "Stripe-Integration (stripeCheckout, stripeWebhook) verarbeitet keine Zahlungsdaten serverseitig. Kreditkartendaten werden ausschließlich über Stripe-gehostete Formulare abgewickelt (PCI SAQ A).", status: "ok" },
    ]
  },
];

const AGENTS = [
  {
    name: "fall_assistent",
    label: "Fall-Assistent (Agent)",
    icon: MessageSquare,
    beschreibung: "Juristischer KI-Chat-Assistent für Fallanalyse, Argumentation und Fristen",
    compliance_highlights: [
      "Verschwiegenheit explizit im System-Prompt verankert (§ 43a BRAO)",
      "Rechtsberatung nur als Assistenz für autorisierten Anwalt",
      "Keine Mandantendaten nach außen kommuniziert",
      "KI-Ausgaben als solche gekennzeichnet (EU AI Act Art. 13)",
    ]
  },
  {
    name: "plattform_optimierer",
    label: "Plattform-Optimierer (Agent)",
    icon: Target,
    beschreibung: "Strategischer KI-Berater für Kanzlei-Qualitätssicherung und Plattformverbesserung",
    compliance_highlights: [
      "Zweckbindung auf Optimierung und Qualitätssicherung beschränkt",
      "Alle Datenänderungen im CaseHistory-Audit-Trail protokolliert",
      "Ausschließlich für autorisierte Kanzleinutzer zugänglich",
      "Keine eigenständige Mandatshandlung ohne Anwalt",
    ]
  },
  {
    name: "TabArgumente / TabBeweise",
    label: "Argument- & Beweisanalyse",
    icon: Scale,
    beschreibung: "KI-Stärkebewertung für Argumente (0–10) und Beweisgewichtung mit Diskrepanzerkennung",
    compliance_highlights: [
      "DSGVO-Compliance-Badge pro Argument und Beweis sichtbar",
      "Diskrepanzen ≥ 4 werden explizit als Warnung markiert",
      "Anwalt übernimmt KI-Vorschläge manuell — keine Automatik",
      "KI-Begründung transparent und einsehbar",
    ]
  },
  {
    name: "TabStrategie / TabRisiko",
    label: "Strategie, Prognose & Risiko",
    icon: BarChart2,
    beschreibung: "KI-Erfolgswahrscheinlichkeit, Risikoberechnung und Rechtsprechungsrecherche",
    compliance_highlights: [
      "Algorithmus (legalAlgorithms.js) transparent und auditierbar",
      "Alle Eingabefaktoren manuell überschreibbar",
      "KI-Rechtsprechung mit expliziten Quellenangaben",
      "Was-wäre-wenn-Simulation als Planungswerkzeug deklariert",
    ]
  },
  {
    name: "TabKIBerater",
    label: "KI-Berater (Gegnerpsychologie)",
    icon: Sword,
    beschreibung: "Sun Tzu / Machiavelli-basierte Verhandlungs- und Prozesstaktik-Empfehlungen",
    compliance_highlights: [
      "Ergebnisse als strategische Empfehlung, nicht Rechtsberatung deklariert",
      "Kein automatisches Handeln — nur Informationsbereitstellung",
      "Personenbezogene Gegnerprofile nur für Prozessführungszwecke",
      "Outputs im KIUsageLog protokolliert",
    ]
  },
  {
    name: "TabDokumenteAnalyse",
    label: "Dokumenten-KI (analyzeDocument)",
    icon: FileText,
    beschreibung: "10-Schritt-KI-Extraktion von Fristen, Personen, Argumenten aus hochgeladenen Dokumenten",
    compliance_highlights: [
      "analyzeDocument läuft serverseitig — kein clientseitiger Datenzugriff",
      "Uploads nur für authentifizierten Nutzer (HTTP 401 sonst)",
      "Extraktionen sind Vorschläge — Übernahme nur mit Nutzerbestätigung",
      "Keine Speicherung der Dokumente auf externen Diensten",
    ]
  },
  {
    name: "Strategos Enterprise",
    label: "Strategos — KI-Szenarioplanung",
    icon: Target,
    beschreibung: "6-Schritt Enterprise-Analyse: Gesetzeslücken, Optionenmatrix, Aktionsplan, Empfehlung",
    compliance_highlights: [
      "Alle Schritte durch explizite Nutzeraktion ausgelöst",
      "Gesetzeslücken-Analyse mit Risikohinweis versehen",
      "LEXARA-Sync nur auf Nutzerinitiative — keine Automatik",
      "Szenariodaten in StrategosScenario-Entity mit RLS gesichert",
    ]
  },
  {
    name: "InvokeLLM (inline, alle Reiter)",
    label: "Inline-KI (alle weiteren Tabs)",
    icon: Bot,
    beschreibung: "Direkte LLM-Aufrufe in Schriftsatz, Verhandlung, Zeitstrahl, Gegneranalyse, Cockpit etc.",
    compliance_highlights: [
      "Nur für eingeloggten Nutzer — RLS sichert Datenisolation",
      "Outputs werden im KIUsageLog protokolliert",
      "Kein externer Datentransfer von Mandanteninhalten",
      "Anwalt bestätigt und übernimmt alle KI-Vorschläge manuell",
    ]
  },
];

const STATUS_CONFIG = {
  ok: { label: "Konform", color: "text-emerald-700", bg: "bg-emerald-50", border: "border-emerald-200", icon: CheckCircle },
  warning: { label: "Prüfen", color: "text-amber-700", bg: "bg-amber-50", border: "border-amber-200", icon: AlertTriangle },
  info: { label: "Info", color: "text-blue-700", bg: "bg-blue-50", border: "border-blue-200", icon: Info },
};

const FARBE_CONFIG = {
  emerald: { badge: "bg-emerald-100 text-emerald-800", header: "bg-emerald-50 border-emerald-200", icon: "text-emerald-600" },
  blue: { badge: "bg-blue-100 text-blue-800", header: "bg-blue-50 border-blue-200", icon: "text-blue-600" },
  violet: { badge: "bg-violet-100 text-violet-800", header: "bg-violet-50 border-violet-200", icon: "text-violet-600" },
  gray: { badge: "bg-gray-100 text-gray-800", header: "bg-gray-50 border-gray-200", icon: "text-gray-600" },
  orange: { badge: "bg-orange-100 text-orange-800", header: "bg-orange-50 border-orange-200", icon: "text-orange-600" },
  red: { badge: "bg-red-100 text-red-800", header: "bg-red-50 border-red-200", icon: "text-red-600" },
};

function ComplianceKategorie({ gruppe }) {
  const [open, setOpen] = useState(true);
  const Icon = gruppe.icon;
  const fc = FARBE_CONFIG[gruppe.farbe];
  const allOk = gruppe.checks.every(c => c.status === "ok");

  return (
    <div className={`border rounded-2xl overflow-hidden`} style={{ borderColor: "rgba(0,0,0,0.08)" }}>
      <button onClick={() => setOpen(o => !o)}
        className={`w-full flex items-center justify-between px-5 py-4 ${fc.header} border-b`}
        style={{ borderColor: "rgba(0,0,0,0.07)" }}>
        <div className="flex items-center gap-3">
          <Icon className={`w-5 h-5 ${fc.icon}`} />
          <span className="font-semibold text-gray-900 text-sm">{gruppe.kategorie}</span>
          <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${fc.badge}`}>
            {gruppe.checks.length} Checks
          </span>
          {allOk && <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700">✓ Alle konform</span>}
        </div>
        {open ? <ChevronUp className="w-4 h-4 text-gray-400" /> : <ChevronDown className="w-4 h-4 text-gray-400" />}
      </button>
      {open && (
        <div className="divide-y divide-gray-50">
          {gruppe.checks.map(check => {
            const sc = STATUS_CONFIG[check.status];
            const StatusIcon = sc.icon;
            return (
              <div key={check.id} className="px-5 py-4 bg-white flex items-start gap-4">
                <StatusIcon className={`w-4 h-4 mt-0.5 flex-shrink-0 ${sc.color}`} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap mb-1">
                    <span className="text-xs font-semibold text-gray-900">{check.label}</span>
                    <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded-full border ${sc.bg} ${sc.color} ${sc.border}`}>{sc.label}</span>
                  </div>
                  <p className="text-xs text-gray-500 leading-relaxed">{check.beschreibung}</p>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function AgentCard({ agent }) {
  const Icon = agent.icon || Bot;
  return (
    <div className="bg-white border rounded-xl p-4" style={{ borderColor: "rgba(0,0,0,0.08)" }}>
      <div className="flex items-start gap-3 mb-3">
        <div className="w-8 h-8 bg-gray-900 rounded-lg flex items-center justify-center flex-shrink-0">
          <Icon className="w-4 h-4 text-white" />
        </div>
        <div>
          <p className="text-sm font-semibold text-gray-900">{agent.label}</p>
          <p className="text-[10px] font-mono text-gray-400">{agent.name}</p>
          <p className="text-xs text-gray-500 mt-0.5">{agent.beschreibung}</p>
        </div>
      </div>
      <div className="space-y-1.5">
        {agent.compliance_highlights.map((h, i) => (
          <div key={i} className="flex items-start gap-2">
            <CheckCircle className="w-3 h-3 text-emerald-500 flex-shrink-0 mt-0.5" />
            <span className="text-xs text-gray-600">{h}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function LiveCompliancePanel() {
  const [cases, setCases] = useState([]);
  const [args, setArgs] = useState([]);
  const [evidence, setEvidence] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(null);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      const [cs, allArgs, allEvidence] = await Promise.all([
        base44.entities.Case.list("-updated_date", 20),
        base44.entities.Argument.list("-created_date", 200),
        base44.entities.Evidence.list("-created_date", 200),
      ]);
      setCases(cs);
      setArgs(allArgs);
      setEvidence(allEvidence);
      setLoading(false);
    };
    load();
  }, []);

  if (loading) return (
    <div className="flex items-center justify-center py-10 bg-white border rounded-2xl" style={{ borderColor: "rgba(0,0,0,0.08)" }}>
      <RefreshCw className="w-4 h-4 animate-spin text-gray-400 mr-2" />
      <span className="text-sm text-gray-400">Lade Fälle & Elemente…</span>
    </div>
  );

  if (cases.length
