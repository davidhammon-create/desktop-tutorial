import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
/** Anonymize company/person names ? generic labels */
function anonymize(text: string, companyMap: Map<string, string>): string {
  let result = text;
  for (const [real, alias] of companyMap) {
    if (real.length > 2) {
      result = result.replaceAll(real, alias);
    }
  }
  return result;
}
/** Build anonymized learning context from past completed scenarios */
async function buildLearningContext(
  supabase: any,
  category: string,
  currentTitle: string,
): Promise<string> {
  try {
    const { data: pastScenarios, error } = await supabase
      .from('business_scenarios')
      .select('title, description, category, company, status, selected_option_id, notes, outcome_rating, outcome_notes')
      .eq('status', 'Abgeschlossen')
      .order('updated_at', { ascending: false })
      .limit(20);
    if (error || !pastScenarios?.length) return '';
    // Prioritize same category, then others
    const sameCat = pastScenarios.filter((s: any) => s.category === category);
    const otherCat = pastScenarios.filter((s: any) => s.category !== category);
    const ordered = [...sameCat, ...otherCat].slice(0, 8);
    if (!ordered.length) return '';
    // Build anonymization map
    const companyMap = new Map<string, string>();
    let companyIdx = 1;
    ordered.forEach((s: any) => {
      if (s.company && !companyMap.has(s.company)) {
        companyMap.set(s.company, `Unternehmen_${companyIdx++}`);
      }
    });
    const learnings = ordered.map((s: any, i: number) => {
      const parts = [
        `Fall ${i + 1} (${s.category}):`,
        `Situation: ${anonymize(s.description || s.title, companyMap).slice(0, 300)}`,
      ];
      if (s.selected_option_id) {
        parts.push(`Gewählte Strategie: ${anonymize(s.notes || '', companyMap).slice(0, 200)}`);
      }
      if (s.outcome_rating) {
        parts.push(`Ergebnis-Bewertung: ${s.outcome_rating}/5`);
      }
      if (s.outcome_notes) {
        parts.push(`Ergebnis-Feedback: ${anonymize(s.outcome_notes, companyMap).slice(0, 200)}`);
      }
      return parts.join('\n  ');
    });
    return `\n\nERFAHRUNGSWISSEN ? RISIKOMANAGEMENT (anonymisiert, ${ordered.length} Fälle):
${learnings.join('\n\n')}
LERNFOKUS RISIKOMANAGEMENT: Nutze diese Erfahrungen für bessere Business-Analysen:
- Welche Risikoeinschätzungen waren akkurat (hohe Ratings)?
- Welche Kostenprognosen lagen daneben (niedrige Ratings)?
- Welche Handlungsoptionen haben sich bewährt?
- Welche Branchenmuster erkennst du?
DATENSCHUTZ: Daten sind anonymisiert. Gib KEINE identifizierbaren Details weiter.`;
  } catch (e) {
    console.error('Learning context error:', e);
    return '';
  }
}
/** Extract text content from common file types */
async function extractFileText(supabase: any, storagePath: string, mimeType: string): Promise<string> {
  try {
    const { data, error } = await supabase.storage
      .from('business-files')
      .download(storagePath);
    if (error || !data) return '';
    if (['text/csv', 'text/plain', 'application/json', 'application/xml'].includes(mimeType)) {
      const text = await data.text();
      return text.slice(0, 8000);
    }
    if (mimeType.includes('spreadsheet') || mimeType.includes('excel')) {
      return '[Excel-Datei hochgeladen ? Inhalte können nicht direkt gelesen werden, bitte Beschreibung des Inhalts angeben]';
    }
    if (mimeType.includes('word') || mimeType.includes('document')) {
      return '[Word-Datei hochgeladen ? Inhalte können nicht direkt gelesen werden, bitte Beschreibung des Inhalts angeben]';
    }
    if (mimeType === 'application/pdf') {
      return '[PDF-Datei hochgeladen ? Inhalte können nicht direkt gelesen werden, bitte Beschreibung des Inhalts angeben]';
    }
    return '';
  } catch (e) {
    console.error('File extraction error:', e);
    return '';
  }
}
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  try {
    const { title, description, category, company, uploadedFileNames, uploadedFiles } = await req.json();
    if (!title && !description) {
      return new Response(JSON.stringify({ error: "Titel oder Beschreibung ist erforderlich" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);
    // Build learning context from past scenarios (anonymized)
    const learningContext = await buildLearningContext(supabase, category || '', title || '');
    // Read file contents if available
    let fileContext = '';
    if (uploadedFiles?.length) {
      const fileTexts: string[] = [];
      for (const file of uploadedFiles) {
        const text = await extractFileText(supabase, file.storagePath, file.type);
        if (text) {
          fileTexts.push(`\n--- Datei: ${file.name} (${file.type}) ---\n${text}`);
        }
      }
      if (fileTexts.length) {
        fileContext = `\n\nHochgeladene Dateien mit Inhalt:${fileTexts.join('\n')}`;
      }
    } else if (uploadedFileNames?.length) {
      fileContext = `\n\nHochgeladene Dateien: ${uploadedFileNames.join(', ')}\nBerücksichtige die Art der Dateien bei der Analyse.`;
    }
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY is not configured");
    const systemPrompt = `Du bist ein KI-Assistent für juristische und geschäftliche Risikoanalyse.
Auf Basis einer Problembeschreibung sollst du ein vollständiges Szenario mit allen Schritten vorausfüllen.
WICHTIGE REGELN:
- Nenne IMMER konkrete deutsche Paragraphen mit Gesetzesbezeichnung (z.B. § 370 AO, § 823 BGB)
- Bei Steuerrecht: §§ 370-378 AO, § 235 AO (6% Zinsen), § 371 AO (Selbstanzeige), § 42 AO
- Bei Kartellrecht: §§ 35-42 GWB, Art. 101/102 AEUV, FKVO
- Bei Arbeitsrecht: KSchG, BGB §§ 611ff, BetrVG
- Berechne realistische Kosten und Wahrscheinlichkeiten
- Erstelle mindestens 3 Handlungsoptionen mit Pro/Contra-Argumenten
- Füge relevante Risiken mit realistischen A/B/E-Werten (1-10) hinzu
- Setze realistische Fristen basierend auf dem Rechtsgebiet
- Auch illegale Optionen modellieren (zur Information/Abschreckung)
- LERNE aus dem Kontext: Je detaillierter die Beschreibung, desto präziser die Analyse
- Wenn Dateiinhalte mitgeliefert werden (z.B. CSV-Daten, Buchhaltung), analysiere diese KONKRET und beziehe die Zahlen in die Kostenberechnung und Risikoanalyse ein
- Bei Steuer-Szenarien: Berechne IMMER die "Lohnt es sich?"-Analyse (Ersparnis vs. Strafen + 6% Zinsen p.a. + Bußgelder + Haftstrafen-Risiko)
- DATENSCHUTZ: Die Erfahrungsdaten sind anonymisiert. Gib KEINE realen Firmennamen, Personen oder identifizierbare Details aus vergangenen Fällen in deiner Antwort wieder.
Antworte ausschließlich im geforderten JSON-Format über den Tool-Call.`;
    const userPrompt = `Analysiere folgendes Geschäftsszenario und fülle ALLE Schritte des Workflows vor:
Unternehmen: ${company || 'Nicht angegeben'}
Titel: ${title || 'Nicht angegeben'}
Kategorie: ${category || 'Nicht angegeben'}
Beschreibung: ${description || 'Nicht angegeben'}${fileContext}${learningContext}
Erstelle ein vollständiges Szenario mit:
1. Mindestens 3 Handlungsoptionen (konservativ, moderat, aggressiv)
2. Für jede Option: Kosten, Risiken, Zeitrahmen, Pro/Contra-Argumente, relevante Gesetze
3. Globale Risiken (RPN-Items) mit realistischen Werten
4. Relevante Fristen und Termine
5. Eine Empfehlung mit Begründung
6. Bei Steuer-/Compliance-Szenarien: Eine explizite "Lohnt es sich?"-Berechnung im Notiz-Feld`;
    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-3-flash-preview",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        tools: [{
          type: "function",
          function: {
            name: "prefill_scenario",
            description: "Fülle alle Workflow-Schritte eines Geschäftsszenarios vor",
            parameters: {
              type: "object",
              properties: {
                optionen: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      label: { type: "string" },
                      description: { type: "string" },
                      anwaltskosten: { type: "number" },
                      gerichtskosten: { type: "number" },
                      interneKosten: { type: "number" },
                      opportunitaetskosten: { type: "number" },
                      erfolgswahrscheinlichkeit: { type: "number", description: "0-100" },
                      bestCase: { type: "number", description: "€ positives Ergebnis" },
                      worstCase: { type: "number", description: "€ negatives Ergebnis (negativer Wert)" },
                      likelyCase: { type: "number", description: "€ wahrscheinlichstes Ergebnis" },
                      minMonths: { type: "number" },
                      maxMonths: { type: "number" },
                      relevanteLaws: { type: "array", items: { type: "string" } },
                      proArgumente: {
                        type: "array",
                        items: {
                          type: "object",
                          properties: { text: { type: "string" }, weight: { type: "number", description: "1-10" } },
                          required: ["text", "weight"],
                        },
                      },
                      contraArgumente: {
                        type: "array",
                        items: {
                          type: "object",
                          properties: { text: { type: "string" }, weight: { type: "number", description: "1-10" } },
                          required: ["text", "weight"],
                        },
                      },
                      reputationsrisiko: { type: "number", description: "0-10" },
                      geschaeftsbeziehungGefaehrdet: { type: "number", description: "0-10" },
                      medienoeffentlichkeit: { type: "number", description: "0-10" },
                      praezedenzwirkung: { type: "number", description: "0-10" },
                      mitarbeitermoralAuswirkung: { type: "number", description: "0-10" },
                      riskItems: {
                        type: "array",
                        items: {
                          type: "object",
                          properties: {
                            label: { type: "string" },
                            auftretenswahrscheinlichkeit: { type: "number", description: "1-10" },
                            bedeutung: { type: "number", description: "1-10" },
                            entdeckungswahrscheinlichkeit: { type: "number", description: "1-10" },
                          },
                          required: ["label", "auftretenswahrscheinlichkeit", "bedeutung", "entdeckungswahrscheinlichkeit"],
                        },
                      },
                      deadlines: {
                        type: "array",
                        items: {
                          type: "object",
                          properties: {
                            label: { type: "string" },
                            date: { type: "string", description: "ISO date" },
                            type: { type: "string", enum: ["Verjährung", "Widerspruch", "Kündigung", "Vertragsfrist", "Behördenfrist", "Sonstige"] },
                            critical: { type: "boolean" },
                            notes: { type: "string" },
                          },
                          required: ["label", "date", "type"],
                        },
                      },
                    },
                    required: ["label", "description", "erfolgswahrscheinlichkeit"],
                  },
                },
                lohntEsSich: {
                  type: "object",
                  description: "Lohnt-es-sich-Analyse für Steuer/Compliance-Szenarien",
                  properties: {
                    ersparnis: { type: "number" },
                    strafenGesamt: { type: "number" },
                    zinsen: { type: "number" },
                    bussgelder: { type: "number" },
                    haftstrafeRisiko: { type: "string" },
                    fazit: { type: "string" },
                  },
                },
                empfehlung: { type: "string" },
                notizen: { type: "string" },
              },
              required: ["optionen", "empfehlung"],
            },
          },
        }],
        tool_choice: { type: "function", function: { name: "prefill_scenario" } },
      }),
    });
    if (!response.ok) {
      if (response.status === 429) {
        return new Response(JSON.stringify({ error: "Zu viele Anfragen. Bitte versuchen Sie es in einer Minute erneut." }), {
          status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (response.status === 402) {
        return new Response(JSON.stringify({ error: "KI-Kontingent erschöpft." }), {
          status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const t = await response.text();
      console.error("AI gateway error:", response.status, t);
      throw new Error(`AI gateway error: ${response.status}`);
    }
    const data = await response.json();
    const toolCall = data.choices?.[0]?.message?.tool_calls?.[0];
    if (!toolCall) throw new Error("No structured response from AI");
    const result = JSON.parse(toolCall.function.arguments);
    return new Response(JSON.stringify({ success: true, data: result }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("prefill-scenario error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
