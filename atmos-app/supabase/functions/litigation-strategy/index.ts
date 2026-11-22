import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
function anonymize(text: string, nameMap: Map<string, string>): string {
  let result = text;
  for (const [real, alias] of nameMap) {
    if (real.length > 2) result = result.replaceAll(real, alias);
  }
  return result;
}
async function buildLearningContext(supabase: any, caseType: string): Promise<string> {
  try {
    const { data: pastCases } = await supabase
      .from('cases')
      .select('name, type, goal, status, kernfrage, outcome_rating, outcome_notes')
      .not('outcome_rating', 'is', null)
      .order('updated_at', { ascending: false })
      .limit(10);
    if (!pastCases?.length) return '';
    const nameMap = new Map<string, string>();
    let idx = 1;
    const ordered = pastCases.filter((c: any) => c.type === caseType).concat(
      pastCases.filter((c: any) => c.type !== caseType)
    ).slice(0, 5);
    ordered.forEach((c: any) => {
      if (c.name && !nameMap.has(c.name)) nameMap.set(c.name, `Fall_${idx++}`);
    });
    const learnings = ordered.map((c: any, i: number) =>
      `Erfahrung ${i + 1} (${c.type || 'Allgemein'}): Kernfrage: ${anonymize(c.kernfrage || c.goal || '', nameMap).slice(0, 200)}, Bewertung: ${c.outcome_rating}/5${c.outcome_notes ? `, Feedback: ${anonymize(c.outcome_notes, nameMap).slice(0, 200)}` : ''}`
    );
    return `\n\nERFAHRUNGSWISSEN (anonymisiert, ${ordered.length} Fälle):\n${learnings.join('\n')}\nNutze diese Erfahrungen zur Verbesserung der Analyse. KEINE identifizierbaren Details weitergeben.`;
  } catch { return ''; }
}
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  try {
    const { module, caseData, businessData, options } = await req.json();
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY not configured");
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const learningContext = await buildLearningContext(supabase, caseData?.type || businessData?.category || '');
    const systemPrompt = buildSystemPrompt(module, learningContext);
    const userPrompt = buildUserPrompt(module, caseData, businessData, options);
    const tools = [{
      type: "function",
      function: {
        name: "litigation_analysis",
        description: "Return the litigation strategy analysis result",
        parameters: getSchema(module),
      },
    }];
    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-2.5-flash",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        tools,
        tool_choice: { type: "function", function: { name: "litigation_analysis" } },
      }),
    });
    if (!response.ok) {
      const status = response.status;
      if (status === 429) return new Response(JSON.stringify({ error: "Rate limit erreicht. Bitte in einer Minute erneut versuchen." }), { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } });
      if (status === 402) return new Response(JSON.stringify({ error: "Guthaben aufgebraucht. Bitte Konto aufladen." }), { status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" } });
      const t = await response.text();
      console.error("AI gateway error:", status, t);
      throw new Error("AI gateway error");
    }
    const data = await response.json();
    const toolCall = data.choices?.[0]?.message?.tool_calls?.[0];
    let result;
    if (toolCall?.function?.arguments) {
      try { result = JSON.parse(toolCall.function.arguments); } catch { result = { raw: toolCall.function.arguments }; }
    } else {
      result = { raw: data.choices?.[0]?.message?.content || "Keine Analyse verfügbar." };
    }
    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Litigation strategy error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
function buildSystemPrompt(module: string, learningContext: string): string {
  const base = `Du bist ein KI-Prozessstrategieberater für deutsche Zivilprozesse. Du analysierst Rechtsfälle und Geschäftsszenarien mit höchster Präzision.
KERNKOMPETENZ: Anspruchspyramide (§§ BGB/HGB/ZPO), Beweislastmatrix, Monte-Carlo-Prozessrisiko, Vergleichskorridor (ZOPA), Instanz-Kosten-Matrix (RVG/GKG), Verjährungsmanagement, dynamische Strategieanpassung.
METHODIK:
- Ansprüche hierarchisch gliedern: Primär ? Sekundär ? Hilfs ? Prozessuale Nebenansprüche
- Für jeden Anspruch: Anspruchsgrundlage, Schlüssigkeitswahrscheinlichkeit (0-100%), Beweisbarkeitswahrscheinlichkeit (0-100%), Verjährungsstatus
- Beweislücken identifizieren: kritisch (kein Beweis), mittel (schwacher Beweis), gering (suboptimale Form)
- Mehrstufiger Wahrscheinlichkeitsbaum: Schlüssigkeit ? Beweis ? Rechtliche Bewertung ? Rechtsmittel ? Vollstreckung
- Vergleichskorridor: Mindestbetrag Kläger vs. Maximalbetrag Beklagter = ZOPA
- Kostenmatrix nach RVG/GKG für alle Instanzen und Szenarien
RECHTSGEBIETE-INVENTAR:
Kaufrecht: §§ 433-441, 280, 281, 286, 311a, 812, 823 BGB
Werkvertrag: §§ 631-651, 648, 650a ff. BGB
Deliktsrecht: §§ 823, 824, 826, 831 BGB; UWG; MarkenG; UrhG
Gesellschaftsrecht: §§ 43, 64 GmbHG; §§ 93, 116 AktG; AnfG; InsO
Arbeitsrecht: §§ 1 KSchG, 611a, 615 BGB; AGG; BetrVG
Antworte IMMER auf Deutsch. Sei extrem konkret mit Paragraphen und Berechnungen.
DATENSCHUTZ: Anonymisierte Erfahrungsdaten NIEMALS de-anonymisieren.${learningContext}`;
  const modules: Record<string, string> = {
    claims: `${base}\n\nMODUL: ANSPRUCHSPYRAMIDE\nErstelle eine vollständige hierarchische Anspruchsanalyse mit allen Ebenen (primär, sekundär, hilfs, prozessual). Für jeden Anspruch: exakte Anspruchsgrundlage mit Paragraphen, Schlüssigkeitswahrscheinlichkeit, Beweisbarkeitswahrscheinlichkeit, Verjährungsstatus, Abhängigkeiten zu anderen Ansprüchen. Prüfe ALLE relevanten Rechtsgebiete systematisch.`,

    evidence_gaps: `${base}\n\nMODUL: BEWEIS- UND TATSACHENANALYSE\nAnalysiere die Beweislage systematisch:\n1. Beweislastmatrix: Wer trägt für welches Merkmal die Beweislast?\n2. Beweismittel-Inventar: Verfügbare, potenziell verfügbare, nicht verfügbare Beweismittel\n3. Beweislücken: Kritisch/Mittel/Gering mit konkreten Handlungsempfehlungen\n4. Beweissicherungsmaßnahmen: §§ 485 ff. ZPO, einstweilige Verfügung, Arrest\n5. Für jeden Beweis: Beweiskraft, Verwertbarkeit, Angreifbarkeit`,

    settlement: `${base}\n\nMODUL: VERGLEICHS-OPTIMIERUNG (ZOPA)\nBerechne den optimalen Vergleichskorridor:\n1. Mindestvergleichsbetrag (Klägersicht): EW_Klage - Kostendifferenz\n2. Maximalvergleichsbetrag (Beklagtensicht): EW_Prozessrisiko ? Verurteilungswahrscheinlichkeit\n3. ZOPA: Zone of Possible Agreement\n4. Verhandlungstaktik: Welche Konzessionen anbieten, welche fordern?\n5. BATNA-Analyse: Best Alternative to Negotiated Agreement\n6. Stufenklage-Prüfung nach § 254 ZPO\n7. Berücksichtige Zeitwert (Diskontierung bei langer Verfahrensdauer)`,

    risk_simulation: `${base}\n\nMODUL: QUANTITATIVE PROZESSRISIKO-ANALYSE\nFühre eine vollständige quantitative Risikoanalyse durch:\n1. Mehrstufiger Wahrscheinlichkeitsbaum (5 Stufen: Schlüssigkeit ? Beweis ? Recht ? Rechtsmittel ? Vollstreckung)\n2. Instanz-Kosten-Matrix: Berechne für JEDE Kombination (1. Instanz, Berufung, Revision) ? (Sieg, Teilsieg, Niederlage, Vergleich) die Kosten nach RVG/GKG\n3. Monte-Carlo-Kennzahlen: Erwartungswert, Median, 5./95. Perzentil, VaR\n4. Risiko-Adjustierter Prozessbarwert (RAPB): Diskontierung auf heutigen Zeitpunkt\n5. Sharpe Ratio des Prozesses: (EW - risikofreier Zins) / Standardabweichung`,

    dynamic_strategy: `${base}\n\nMODUL: DYNAMISCHE STRATEGIE-ANPASSUNG\nAnalysiere die aktuelle Situation und generiere:\n1. Trigger-Ereignis-Katalog: Welche Ereignisse erfordern Strategieneubeurteilung?\n2. Eskalations-/De-Eskalations-Framework: Verfügbare Maßnahmen mit erwarteter Wirkung\n3. Parallelverfahrens-Koordination: Abhängigkeiten und Widerspruchsrisiken\n4. Taktische Zeitsteuerung: Optimaler Zeitpunkt für nächste Schritte\n5. Strategieoptionen-Matrix: 6 Dimensionen (Verfahrensart, Zeitpunkt, Streitgegenstand, Instanzenziel, Kooperation, Öffentlichkeit)\n6. Dominierte Strategien eliminieren, Pareto-optimale Strategien identifizieren`,

    full_analysis: `${base}\n\nMODUL: VOLLSTÄNDIGE PROZESSSTRATEGIE-ANALYSE\nFühre eine kompakte Gesamtanalyse durch die alle Module vereint:\n1. Anspruchspyramide (Top-3 Ansprüche mit Wahrscheinlichkeiten)\n2. Beweislücken-Analyse (kritischste Lücken)\n3. Vergleichskorridor (ZOPA mit Beträgen)\n4. Risikosimulation (EW, VaR, Break-Even)\n5. Strategieempfehlung (Klage/Vergleich/Aufgabe mit Begründung)\n6. Nächste 3 taktische Schritte mit Timing`,

    opponent_litigation: `${base}\n\nMODUL: GEGNER-LITIGATION-ANALYSE\nAnalysiere die Prozessposition der Gegenseite:\n1. Wirtschaftliche Situation und Vollstreckungswahrscheinlichkeit\n2. Gegenansprüche und Aufrechnung\n3. Prozessverhalten-Prognose\n4. Anwaltsanalyse der Gegenseite\n5. Interessenlage und Vergleichsmotivation\n6. Netting: Eigene vs. Gegenansprüche = Netto-Prozessgegenstand`,
  };
  return modules[module] || base;
}
function buildUserPrompt(module: string, caseData: any, businessData: any, options: any): string {
  let prompt = '';
  if (caseData) {
    const ownArgs = caseData.arguments?.filter((a: any) => a.side === 'own') || [];
    const oppArgs = caseData.arguments?.filter((a: any) => a.side === 'opp') || [];
    const evidenceCount = caseData.evidence ? Object.values(caseData.evidence).flat().length : 0;
    const openFristen = caseData.fristen?.filter((f: any) => f.status === 'offen')?.length || 0;
    prompt += `FALLDATEN:
- Fall: ${caseData.name || 'N/A'} (${caseData.number || 'N/A'})
- Gericht: ${caseData.court || 'N/A'}
- Rechtsgebiet: ${caseData.type || 'N/A'}
- Instanz: ${caseData.instanz || 'Erstinstanz'}
- Prozessziel: ${caseData.goal || 'N/A'}
- Kernfrage: ${caseData.kernfrage || 'N/A'}
- Status: ${caseData.status || 'N/A'}
ARGUMENTE EIGENE SEITE (${ownArgs.length}):
${ownArgs.map((a: any) => `  ? [Stärke ${a.strength}/10] ${a.label}: ${a.content || a.description || ''} ${a.legalBasis ? `(${a.legalBasis})` : ''}`).join('\n')}
ARGUMENTE GEGENSEITE (${oppArgs.length}):
${oppArgs.map((a: any) => `  ? [Stärke ${a.strength}/10] ${a.label}: ${a.content || a.description || ''}`).join('\n')}
BEWEISMITTEL (${evidenceCount}):
${caseData.evidence ? Object.entries(caseData.evidence).map(([argId, evs]: [string, any]) => {
  const arg = caseData.arguments?.find((a: any) => a.id === argId);
  return (evs as any[]).map((e: any) => `  ? ${e.name} (${e.type || 'Sonstige'}) ? ${arg?.label || 'Unbekannt'} [Stärke: ${e.strength}/10, Validität: ${e.validity}%]`).join('\n');
}).join('\n') : 'Keine'}
PERSONEN:
${caseData.persons?.map((p: any) => `  ? ${p.name} (${p.role}, ${p.party || 'N/A'})${p.role === 'Richter' && p.plaintiffWinRate != null ? ` - Klägerquote: ${p.plaintiffWinRate}%` : ''}`).join('\n') || 'Keine'}
FRISTEN (${openFristen} offen):
${caseData.fristen?.map((f: any) => `  ? ${f.type} (${f.paragraph}): ${f.date} [${f.status}] ${f.side === 'own' ? '?? EIGENE' : 'Gegner'}`).join('\n') || 'Keine'}
KOSTEN:
${caseData.kosten ? `Streitwert: ${caseData.kosten.streitwert}€, Instanz: ${caseData.kosten.instanz}, Gebührenstufe: ${caseData.kosten.gebuehrenstufe}` : 'Nicht konfiguriert'}
`;
  }
  if (businessData) {
    prompt += `GESCHÄFTSSZENARIO:
- Titel: ${businessData.title || 'N/A'}
- Kategorie: ${businessData.category || 'N/A'}
- Unternehmen: ${businessData.company || 'N/A'}
- Beschreibung: ${businessData.description || 'N/A'}
- Status: ${businessData.status || 'N/A'}
`;
    if (options?.length) {
      prompt += `\nOPTIONEN (${options.length}):\n`;
      options.forEach((o: any, i: number) => {
        prompt += `  Option ${i + 1}: ${o.label}
    Erfolgswahrscheinlichkeit: ${o.risk?.erfolgswahrscheinlichkeit || 50}%
    Best Case: ${o.risk?.bestCase || 0}€ / Worst Case: ${o.risk?.worstCase || 0}€
    Kosten: Anwalt ${o.costs?.anwaltskosten || 0}€, Gericht ${o.costs?.gerichtskosten || 0}€
    Argumente Pro: ${o.arguments?.filter((a: any) => a.side === 'pro')?.length || 0}
    Argumente Contra: ${o.arguments?.filter((a: any) => a.side === 'contra')?.length || 0}
    Gesetze: ${o.relevanteLaws?.join(', ') || 'Keine'}
`;
      });
    }
  }
  const modulePrompts: Record<string, string> = {
    claims: `Erstelle eine vollständige Anspruchspyramide für diesen Fall. Prüfe ALLE relevanten Anspruchsgrundlagen systematisch.\n\n${prompt}`,
    evidence_gaps: `Analysiere die Beweislage und identifiziere alle Beweislücken.\n\n${prompt}`,
    settlement: `Berechne den optimalen Vergleichskorridor (ZOPA) und gib Verhandlungsempfehlungen.\n\n${prompt}`,
    risk_simulation: `Führe eine vollständige quantitative Prozessrisiko-Analyse durch.\n\n${prompt}`,
    dynamic_strategy: `Analysiere die dynamische Strategie und identifiziere Trigger-Ereignisse.\n\n${prompt}`,
    full_analysis: `Führe eine kompakte Gesamtanalyse aller Module durch.\n\n${prompt}`,
    opponent_litigation: `Analysiere die Prozessposition und Interessen der Gegenseite.\n\n${prompt}`,
  };
  return modulePrompts[module] || `Analysiere diesen Fall.\n\n${prompt}`;
}
function getSchema(module: string): any {
  const schemas: Record<string, any> = {
    claims: {
      type: "object",
      properties: {
        ansprueche: {
          type: "array",
          items: {
            type: "object",
            properties: {
              ebene: { type: "string", enum: ["primaer", "sekundaer", "hilfs", "prozessual"] },
              anspruchsgrundlage: { type: "string" },
              paragraphen: { type: "string" },
              betrag_euro: { type: "number" },
              schluessigkeit_pct: { type: "number" },
              beweisbarkeit_pct: { type: "number" },
              verjaehrung_status: { type: "string" },
              verjaehrung_datum: { type: "string" },
              abhaengig_von: { type: "string" },
              begruendung: { type: "string" },
            },
            required: ["ebene", "anspruchsgrundlage", "paragraphen", "schluessigkeit_pct", "beweisbarkeit_pct"],
          },
        },
        gesamtbetrag: { type: "number" },
        staerkster_anspruch: { type: "string" },
        schwachstelle: { type: "string" },
        empfehlung: { type: "string" },
      },
      required: ["ansprueche", "empfehlung"],
    },
    evidence_gaps: {
      type: "object",
      properties: {
        beweislast_matrix: {
          type: "array",
          items: {
            type: "object",
            properties: {
              tatbestandsmerkmal: { type: "string" },
              beweislast_traeger: { type: "string", enum: ["eigen", "gegner"] },
              beweismittel_vorhanden: { type: "boolean" },
              beweismittel_typ: { type: "string" },
              beweiskraft: { type: "string", enum: ["stark", "mittel", "schwach", "keine"] },
              angreifbarkeit: { type: "string" },
            },
            required: ["tatbestandsmerkmal", "beweislast_traeger", "beweismittel_vorhanden", "beweiskraft"],
          },
        },
        luecken: {
          type: "array",
          items: {
            type: "object",
            properties: {
              schweregrad: { type: "string", enum: ["kritisch", "mittel", "gering"] },
              merkmal: { type: "string" },
              fehlender_beweis: { type: "string" },
              massnahme: { type: "string" },
              kosten_schaetzung: { type: "string" },
              frist: { type: "string" },
            },
            required: ["schweregrad", "merkmal", "fehlender_beweis", "massnahme"],
          },
        },
        sicherungsmassnahmen: {
          type: "array",
          items: {
            type: "object",
            properties: {
              typ: { type: "string" },
              paragraph: { type: "string" },
              voraussetzungen: { type: "string" },
              empfehlung: { type: "string" },
              dringlichkeit: { type: "string", enum: ["sofort", "zeitnah", "optional"] },
            },
            required: ["typ", "paragraph", "empfehlung", "dringlichkeit"],
          },
        },
        gesamtbewertung: { type: "string" },
      },
      required: ["beweislast_matrix", "luecken", "gesamtbewertung"],
    },
    settlement: {
      type: "object",
      properties: {
        mindestbetrag_klaeger: { type: "number" },
        maximalbetrag_beklagter: { type: "number" },
        zopa_untergrenze: { type: "number" },
        zopa_obergrenze: { type: "number" },
        optimaler_vergleichsbetrag: { type: "number" },
        berechnung_klaeger: { type: "string" },
        berechnung_beklagter: { type: "string" },
        rapb: { type: "number" },
        diskontierungssatz: { type: "number" },
        verfahrensdauer_monate: { type: "number" },
        verhandlungstaktik: {
          type: "array",
          items: {
            type: "object",
            properties: {
              schritt: { type: "number" },
              aktion: { type: "string" },
              begruendung: { type: "string" },
              konzession_anbieten: { type: "string" },
              forderung: { type: "string" },
            },
            required: ["schritt", "aktion", "begruendung"],
          },
        },
        batna_wert: { type: "number" },
        batna_beschreibung: { type: "string" },
        stufenklage_sinnvoll: { type: "boolean" },
        stufenklage_begruendung: { type: "string" },
        empfehlung: { type: "string" },
      },
      required: ["mindestbetrag_klaeger", "maximalbetrag_beklagter", "zopa_untergrenze", "zopa_obergrenze", "empfehlung"],
    },
    risk_simulation: {
      type: "object",
      properties: {
        wahrscheinlichkeitsbaum: {
          type: "array",
          items: {
            type: "object",
            properties: {
              stufe: { type: "number" },
              name: { type: "string" },
              wahrscheinlichkeit_pct: { type: "number" },
              begruendung: { type: "string" },
            },
            required: ["stufe", "name", "wahrscheinlichkeit_pct"],
          },
        },
        gesamt_erfolgswahrscheinlichkeit: { type: "number" },
        instanz_kosten: {
          type: "array",
          items: {
            type: "object",
            properties: {
              instanz: { type: "string" },
              szenario: { type: "string" },
              gerichtsgebuehren: { type: "number" },
              eigen_anwalt: { type: "number" },
              gegner_anwalt: { type: "number" },
              sonstige: { type: "number" },
              netto: { type: "number" },
            },
            required: ["instanz", "szenario", "netto"],
          },
        },
        erwartungswert: { type: "number" },
        var_95: { type: "number" },
        var_99: { type: "number" },
        break_even_pct: { type: "number" },
        rapb: { type: "number" },
        sharpe_ratio: { type: "number" },
        empfehlung: { type: "string" },
        risiko_bewertung: { type: "string" },
      },
      required: ["wahrscheinlichkeitsbaum", "gesamt_erfolgswahrscheinlichkeit", "erwartungswert", "empfehlung"],
    },
    dynamic_strategy: {
      type: "object",
      properties: {
        trigger_ereignisse: {
          type: "array",
          items: {
            type: "object",
            properties: {
              ereignis: { type: "string" },
              wahrscheinlichkeit: { type: "string" },
              auswirkung: { type: "string" },
              reaktion: { type: "string" },
              frist: { type: "string" },
            },
            required: ["ereignis", "auswirkung", "reaktion"],
          },
        },
        eskalationsmassnahmen: {
          type: "array",
          items: {
            type: "object",
            properties: {
              massnahme: { type: "string" },
              typ: { type: "string", enum: ["eskalation", "de_eskalation"] },
              erwartete_wirkung: { type: "string" },
              risiko: { type: "string" },
              timing: { type: "string" },
            },
            required: ["massnahme", "typ", "erwartete_wirkung"],
          },
        },
        strategieoptionen: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              verfahrensart: { type: "string" },
              zeitpunkt: { type: "string" },
              streitgegenstand: { type: "string" },
              instanzenziel: { type: "string" },
              kooperation: { type: "string" },
              oeffentlichkeit: { type: "string" },
              erwartungswert: { type: "number" },
              risiko_score: { type: "number" },
              dominiert: { type: "boolean" },
              empfohlen: { type: "boolean" },
            },
            required: ["name", "erwartungswert", "risiko_score", "empfohlen"],
          },
        },
        naechste_schritte: {
          type: "array",
          items: {
            type: "object",
            properties: {
              nr: { type: "number" },
              aktion: { type: "string" },
              wann: { type: "string" },
              ziel: { type: "string" },
              verantwortlich: { type: "string" },
            },
            required: ["nr", "aktion", "wann", "ziel"],
          },
        },
        empfehlung: { type: "string" },
      },
      required: ["trigger_ereignisse", "strategieoptionen", "naechste_schritte", "empfehlung"],
    },
    full_analysis: {
      type: "object",
      properties: {
        ansprueche_top3: {
          type: "array",
          items: {
            type: "object",
            properties: {
              anspruchsgrundlage: { type: "string" },
              paragraphen: { type: "string" },
              erfolgswahrscheinlichkeit: { type: "number" },
              betrag: { type: "number" },
            },
            required: ["anspruchsgrundlage", "erfolgswahrscheinlichkeit"],
          },
        },
        kritische_beweisluecken: {
          type: "array",
          items: {
            type: "object",
            properties: {
              merkmal: { type: "string" },
              massnahme: { type: "string" },
            },
            required: ["merkmal", "massnahme"],
          },
        },
        zopa: {
          type: "object",
          properties: {
            untergrenze: { type: "number" },
            obergrenze: { type: "number" },
            optimal: { type: "number" },
          },
          required: ["untergrenze", "obergrenze"],
        },
        risiko: {
          type: "object",
          properties: {
            erwartungswert: { type: "number" },
            var_95: { type: "number" },
            break_even: { type: "number" },
            sharpe_ratio: { type: "number" },
          },
          required: ["erwartungswert", "break_even"],
        },
        empfehlung: { type: "string", enum: ["klage", "vergleich", "aufgabe"] },
        begruendung: { type: "string" },
        naechste_schritte: {
          type: "array",
          items: {
            type: "object",
            properties: {
              nr: { type: "number" },
              aktion: { type: "string" },
              timing: { type: "string" },
            },
            required: ["nr", "aktion", "timing"],
          },
        },
      },
      required: ["ansprueche_top3", "zopa", "risiko", "empfehlung", "begruendung", "naechste_schritte"],
    },
    opponent_litigation: {
      type: "object",
      properties: {
        wirtschaftliche_situation: { type: "string" },
        vollstreckungswahrscheinlichkeit: { type: "number" },
        gegenansprueche: {
          type: "array",
          items: {
            type: "object",
            properties: {
              anspruch: { type: "string" },
              betrag: { type: "number" },
              wahrscheinlichkeit: { type: "number" },
            },
            required: ["anspruch", "wahrscheinlichkeit"],
          },
        },
        netto_prozessgegenstand: { type: "number" },
        prozessverhalten_prognose: { type: "string" },
        vergleichsmotivation: { type: "number" },
        schwachstellen: {
          type: "array",
          items: { type: "string" },
        },
        empfehlung: { type: "string" },
      },
      required: ["vollstreckungswahrscheinlichkeit", "prozessverhalten_prognose", "vergleichsmotivation", "empfehlung"],
    },
  };
  return schemas[module] || { type: "object", properties: { analyse: { type: "string" } }, required: ["analyse"] };
}
