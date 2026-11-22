import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
/** Anonymize names ? generic labels */
function anonymize(text: string, nameMap: Map<string, string>): string {
  let result = text;
  for (const [real, alias] of nameMap) {
    if (real.length > 2) result = result.replaceAll(real, alias);
  }
  return result;
}
/** Build LEGAL-focused learning context from past completed cases */
async function buildCaseLearningContext(supabase: any, caseType: string): Promise<string> {
  try {
    const { data: pastCases, error } = await supabase
      .from('cases')
      .select('name, type, goal, status, kernfrage, outcome_rating, outcome_notes')
      .not('outcome_rating', 'is', null)
      .order('updated_at', { ascending: false })
      .limit(10);
    if (error || !pastCases?.length) return '';
    const sameCat = pastCases.filter((c: any) => c.type === caseType);
    const others = pastCases.filter((c: any) => c.type !== caseType);
    const ordered = [...sameCat, ...others].slice(0, 5);
    if (!ordered.length) return '';
    const nameMap = new Map<string, string>();
    let idx = 1;
    ordered.forEach((c: any) => {
      if (c.name && !nameMap.has(c.name)) nameMap.set(c.name, `Fall_${idx++}`);
    });
    const learnings = ordered.map((c: any, i: number) => {
      const parts = [
        `Erfahrung ${i + 1} (${c.type || 'Allgemein'}):`,
        `Kernfrage: ${anonymize(c.kernfrage || c.goal || '', nameMap).slice(0, 200)}`,
        `Bewertung: ${c.outcome_rating}/5`,
      ];
      if (c.outcome_notes) {
        parts.push(`Feedback: ${anonymize(c.outcome_notes, nameMap).slice(0, 200)}`);
      }
      return parts.join('\n  ');
    });
    return `\n\nERFAHRUNGSWISSEN ? JURISTISCHE ANALYSE (anonymisiert, ${ordered.length} Fälle):
${learnings.join('\n\n')}
LERNFOKUS JURA: Nutze diese Erfahrungen um juristische Taktiken zu verbessern:
- Welche Argumentationsstrategien haben funktioniert (hohe Ratings)?
- Welche taktischen Ansätze waren ineffektiv (niedrige Ratings)?
- Welche Rechtsgebiete/Gerichte zeigen Muster?
DATENSCHUTZ: Diese Daten sind anonymisiert. Gib KEINE identifizierbaren Details weiter. Daten verlassen NICHT das System.`;
  } catch (e) {
    console.error('Case learning context error:', e);
    return '';
  }
}
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  try {
    const { module, caseData, gegnerProfil, eigenePosition, kontext } = await req.json();
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY not configured");
    // Build learning context
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);
    const learningContext = await buildCaseLearningContext(supabase, caseData?.type || '');
    const systemPrompt = buildSystemPrompt(module, learningContext);
    const userPrompt = buildUserPrompt(module, caseData, gegnerProfil, eigenePosition, kontext);
    const tools = [{
      type: "function",
      function: {
        name: "strategy_analysis",
        description: "Return the strategic analysis result",
        parameters: getSchemaForModule(module),
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
        tool_choice: { type: "function", function: { name: "strategy_analysis" } },
      }),
    });
    if (!response.ok) {
      const status = response.status;
      if (status === 429) {
        return new Response(JSON.stringify({ error: "Rate limit erreicht. Bitte versuchen Sie es in einer Minute erneut." }), {          status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (status === 402) {
        return new Response(JSON.stringify({ error: "Guthaben aufgebraucht. Bitte laden Sie Ihr Konto auf." }), {
          status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const t = await response.text();
      console.error("AI gateway error:", status, t);
      throw new Error("AI gateway error");
    }
    const data = await response.json();
    const toolCall = data.choices?.[0]?.message?.tool_calls?.[0];
    let result;
    if (toolCall?.function?.arguments) {
      try {
        result = JSON.parse(toolCall.function.arguments);
      } catch {
        result = { raw: toolCall.function.arguments };
      }
    } else {
      result = { raw: data.choices?.[0]?.message?.content || "Keine Analyse verfügbar." };
    }
    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Strategy advisor error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
function buildSystemPrompt(module: string, learningContext: string): string {
  const base = `Du bist ein strategischer KI-Berater für Anwälte, spezialisiert auf taktische und psychologische Prozessanalyse.
RECHTSHINWEIS: Diese Analyse dient der Vorbereitung auf mögliche gegnerische Taktiken und der Entwicklung legitimer Verhandlungsstrategien. Sie ersetzt nicht die ethische und rechtliche Bewertung durch den Anwalt.
Theoretische Grundlagen: Machiavelli ("Der Fürst"), Sun Tzu ("Die Kunst des Krieges"), Robert Cialdini ("Influence"), Chris Voss ("Never Split the Difference"), Game Theory (Nash-Gleichgewicht).
DATENSCHUTZ: Alle Erfahrungsdaten aus vergangenen Fällen sind anonymisiert. Gib KEINE identifizierbaren Details, Firmennamen oder Personennamen aus vergangenen Fällen in deiner Antwort wieder. Die Daten verlassen NICHT das System und werden nicht an Entwickler oder Dritte weitergegeben.
Antworte IMMER auf Deutsch. Sei konkret, praxisnah und direkt anwendbar.${learningContext}`;
  const moduleInstructions: Record<string, string> = {
    profiling: `${base}\n\nDu führst ein psychologisches Profiling durch basierend auf Big Five + Dark Triad Assessment. Analysiere Persönlichkeit, Trigger, Schwachpunkte und empfehle den optimalen Ansatz.`,
    leverage: `${base}\n\nDu identifizierst Druckmittel und Schwachstellen der Gegenseite. Kategorisiere nach: Zeitdruck, finanzielle Schwäche, Reputationsrisiko, rechtliche Risiken, persönliche Risiken, dritte Parteien. Bewerte Stärke 1-10 und Risiko. Denke wie Machiavelli: "Greife dort an, wo der Feind nicht verteidigt ist."`,
    tactics: `${base}\n\nDu generierst 3-5 alternative taktische Strategien von kooperativ bis aggressiv: Win-Win (Harvard), Controlled Escalation, Hardball, Trojan Horse, Divide & Conquer. Bewerte Erfolgswahrscheinlichkeit und Risiko.`,
    timing: `${base}\n\nDu analysierst optimales Timing und Momentum. Identifiziere kritische Zeitfenster, wann der Gegner schwach ist, und empfehle den nächsten optimalen Schritt. Sun Tzu: "Der Sieg wird errungen bevor die Schlacht beginnt."`,
    infowar: `${base}\n\nDu planst die Informationsstrategie: Was sofort offenlegen, was verbergen bis zum Prozess, was als Bluff nutzen. Ethische Grenzen klar markieren! Kategorisiere jeden Vorschlag als GRÜN (unbedenklich), GELB (Grauzone) oder ROT (verboten).`,
    negotiation: `${base}\n\nDu erstellst ein maßgeschneidertes Verhandlungsskript basierend auf FBI-Techniken (Chris Voss) und Machiavelli. Inkludiere: Opening, Argumentation, Einwandbehandlung, Closing. Gib konkrete Formulierungen, nicht nur Theorie.`,  };
  return moduleInstructions[module] || base;
}
function buildUserPrompt(module: string, caseData: any, gegnerProfil: any, eigenePosition: any, kontext: any): string {
  const caseInfo = caseData ? `
FALLDATEN:
- Name: ${caseData.name || "N/A"}
- Aktenzeichen: ${caseData.number || "N/A"}
- Gericht: ${caseData.court || "N/A"}
- Rechtsgebiet: ${caseData.type || "N/A"}
- Prozessziel: ${caseData.goal || "N/A"}
- Status: ${caseData.status || "N/A"}
- Argumente eigene Seite: ${caseData.arguments?.filter((a: any) => a.side === 'own')?.length || 0}
- Argumente Gegenseite: ${caseData.arguments?.filter((a: any) => a.side === 'opp')?.length || 0}
- Beweismittel: ${caseData.evidence ? Object.values(caseData.evidence).flat().length : 0}
- Personen: ${caseData.persons?.map((p: any) => `${p.name} (${p.role})`).join(", ") || "Keine"}
- Fristen: ${caseData.fristen?.length || 0} (${caseData.fristen?.filter((f: any) => f.status === 'offen')?.length || 0} offen)
` : "";
  const gegnerInfo = gegnerProfil ? `
GEGNER-PROFIL:
${JSON.stringify(gegnerProfil, null, 2)}
` : "";
  const eigeneInfo = eigenePosition ? `
EIGENE POSITION:
${JSON.stringify(eigenePosition, null, 2)}
` : "";
  const kontextInfo = kontext ? `
KONTEXT:
${JSON.stringify(kontext, null, 2)}
` : "";
  const modulePrompts: Record<string, string> = {
    profiling: `Erstelle ein vollständiges psychologisches Profiling der Gegenpartei.\n${caseInfo}${gegnerInfo}${kontextInfo}`,    leverage: `Identifiziere alle Druckmittel und Schwachstellen.\n${caseInfo}${gegnerInfo}${eigeneInfo}${kontextInfo}`,
    tactics: `Generiere 3-5 taktische Strategien mit Erfolgswahrscheinlichkeit.\n${caseInfo}${gegnerInfo}${eigeneInfo}${kontextInfo}`,
    timing: `Analysiere optimales Timing und Momentum für den nächsten Schritt.\n${caseInfo}${gegnerInfo}${kontextInfo}`,
    infowar: `Erstelle eine Informationsstrategie: Was offenlegen, verbergen, bluffen.\n${caseInfo}${gegnerInfo}${eigeneInfo}`,    negotiation: `Erstelle ein detailliertes Verhandlungsskript mit konkreten Formulierungen.\n${caseInfo}${gegnerInfo}${eigeneInfo}${kontextInfo}`,
  };
  return modulePrompts[module] || `Analysiere diesen Fall strategisch.\n${caseInfo}${gegnerInfo}${eigeneInfo}${kontextInfo}`;
}
function getSchemaForModule(module: string): any {
  const schemas: Record<string, any> = {
    profiling: {
      type: "object",
      properties: {
        big_five: {
          type: "object",
          properties: {
            machtmotivation: { type: "number" },
            risikobereitschaft: { type: "number" },
            gesichtswahrung: { type: "number" },
            verhandlungsstil: { type: "number" },
            emotionale_kontrolle: { type: "number" },
            entscheidungsgeschwindigkeit: { type: "number" },
          },
          required: ["machtmotivation", "risikobereitschaft", "gesichtswahrung", "verhandlungsstil", "emotionale_kontrolle", "entscheidungsgeschwindigkeit"],
        },
        dark_triad: {
          type: "object",
          properties: {
            narzissmus: { type: "number" },
            machiavellismus: { type: "number" },
            psychopathie: { type: "number" },
          },
          required: ["narzissmus", "machiavellismus", "psychopathie"],
        },
        trigger: {
          type: "array",
          items: {
            type: "object",
            properties: {
              kategorie: { type: "string" },
              beschreibung: { type: "string" },
              intensitaet: { type: "string", enum: ["hoch", "mittel", "niedrig"] },
            },
            required: ["kategorie", "beschreibung", "intensitaet"],
          },
        },
        empfohlener_ansatz: { type: "string" },
        begruendung: { type: "string" },
      },
      required: ["big_five", "dark_triad", "trigger", "empfohlener_ansatz", "begruendung"],
    },
    leverage: {
      type: "object",
      properties: {
        druckmittel: {
          type: "array",
          items: {
            type: "object",
            properties: {
              kategorie: { type: "string" },
              hebel: { type: "string" },
              wie_nutzen: { type: "string" },
              wann_einsetzen: { type: "string" },
              staerke: { type: "number" },
              risiko: { type: "string" },
              ethik: { type: "string", enum: ["gruen", "gelb", "rot"] },
              zitat: { type: "string" },
            },
            required: ["kategorie", "hebel", "wie_nutzen", "staerke", "risiko", "ethik"],
          },
        },
        empfohlene_reihenfolge: {
          type: "array",
          items: {
            type: "object",
            properties: {
              schritt: { type: "number" },
              aktion: { type: "string" },
              ziel: { type: "string" },
              erwartete_reaktion: { type: "string" },
            },
            required: ["schritt", "aktion", "ziel"],
          },
        },
      },
      required: ["druckmittel", "empfohlene_reihenfolge"],
    },
    tactics: {
      type: "object",
      properties: {
        strategien: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              ansatz: { type: "string" },
              taktiken: { type: "array", items: { type: "string" } },
              erfolgswahrscheinlichkeit: { type: "number" },
              risiko: { type: "string" },
              empfohlen: { type: "boolean" },
              zitat: { type: "string" },
            },
            required: ["name", "ansatz", "taktiken", "erfolgswahrscheinlichkeit", "risiko"],
          },
        },
        empfehlung: { type: "string" },
        begruendung: { type: "string" },
      },
      required: ["strategien", "empfehlung", "begruendung"],
    },
    timing: {
      type: "object",
      properties: {
        momentum: { type: "string" },
        momentum_score: { type: "number" },
        kritische_zeitfenster: {
          type: "array",
          items: {
            type: "object",
            properties: {
              zeitraum: { type: "string" },
              ereignis: { type: "string" },
              taktik: { type: "string" },
              druck_level: { type: "string" },
            },
            required: ["zeitraum", "ereignis", "taktik"],
          },
        },
        naechster_schritt: {
          type: "object",
          properties: {
            aktion: { type: "string" },
            wann: { type: "string" },
            wie: { type: "string" },
            ziel: { type: "string" },
          },
          required: ["aktion", "wann", "ziel"],
        },
      },
      required: ["momentum", "momentum_score", "kritische_zeitfenster", "naechster_schritt"],
    },
    infowar: {
      type: "object",
      properties: {
        sofort_offenlegen: {
          type: "array",
          items: {
            type: "object",
            properties: {
              was: { type: "string" },
              warum: { type: "string" },
              wie_praesentieren: { type: "string" },
              effekt: { type: "string" },
            },
            required: ["was", "warum"],
          },
        },
        verbergen: {
          type: "array",
          items: {
            type: "object",
            properties: {
              was: { type: "string" },
              warum: { type: "string" },
              wann_offenlegen: { type: "string" },
              risiko: { type: "string" },
            },
            required: ["was", "warum"],
          },
        },
        als_bluff: {
          type: "array",
          items: {
            type: "object",
            properties: {
              was: { type: "string" },
              formulierung: { type: "string" },
              ziel: { type: "string" },
              risiko: { type: "string" },
            },
            required: ["was", "formulierung", "ziel"],
          },
        },
        empfehlung: { type: "string" },
      },
      required: ["sofort_offenlegen", "verbergen", "als_bluff", "empfehlung"],
    },
    negotiation: {
      type: "object",
      properties: {
        vorbereitung: { type: "string" },
        opening: { type: "string" },
        argumentation: { type: "string" },
        einwandbehandlung: {
          type: "array",
          items: {
            type: "object",
            properties: {
              einwand: { type: "string" },
              antwort: { type: "string" },
              technik: { type: "string" },
            },
            required: ["einwand", "antwort"],
          },
        },
        closing: { type: "string" },
        backup_plan: { type: "string" },
        psychologische_notizen: {
          type: "array",
          items: { type: "string" },
        },
      },
      required: ["vorbereitung", "opening", "argumentation", "einwandbehandlung", "closing"],
    },
  };
  return schemas[module] || { type: "object", properties: { analyse: { type: "string" } }, required: ["analyse"] };
}
