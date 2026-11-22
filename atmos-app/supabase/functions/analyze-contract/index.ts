import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
/** Anonymize names */
function anonymize(text: string, nameMap: Map<string, string>): string {
  let result = text;
  for (const [real, alias] of nameMap) {
    if (real.length > 2) result = result.replaceAll(real, alias);
  }
  return result;
}
/** Build risk-management-focused learning context from past business scenarios */
async function buildRiskLearningContext(category: string): Promise<string> {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);
    const { data: past, error } = await supabase
      .from('business_scenarios')
      .select('title, description, category, company, status, notes, outcome_rating, outcome_notes')
      .eq('status', 'Abgeschlossen')
      .not('outcome_rating', 'is', null)
      .order('updated_at', { ascending: false })
      .limit(15);
    if (error || !past?.length) return '';
    const sameCat = past.filter((s: any) => s.category === category);
    const others = past.filter((s: any) => s.category !== category);
    const ordered = [...sameCat, ...others].slice(0, 6);
    if (!ordered.length) return '';
    const nameMap = new Map<string, string>();
    let idx = 1;
    ordered.forEach((s: any) => {
      if (s.company && !nameMap.has(s.company)) nameMap.set(s.company, `Unternehmen_${idx++}`);
    });
    const learnings = ordered.map((s: any, i: number) => {
      const parts = [
        `Szenario ${i + 1} (${s.category}):`,
        `Problem: ${anonymize(s.description || s.title, nameMap).slice(0, 250)}`,
        `Bewertung: ${s.outcome_rating}/5`,
      ];
      if (s.outcome_notes) parts.push(`Feedback: ${anonymize(s.outcome_notes, nameMap).slice(0, 200)}`);
      return parts.join('\n  ');
    });
    return `\n\nERFAHRUNGSWISSEN ? RISIKOMANAGEMENT (anonymisiert, ${ordered.length} Fälle):
${learnings.join('\n\n')}
Nutze diese Erfahrungen für realistischere Risikoeinschätzungen. Lerne aus den Bewertungen: hohe Ratings = gute Analyse, niedrige = verbesserungswürdig.
DATENSCHUTZ: Gib KEINE identifizierbaren Details aus vergangenen Fällen weiter.`;
  } catch (e) {
    console.error('Risk learning context error:', e);
    return '';
  }
}
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  try {
    const { text, context, fileBase64, fileMimeType, files } = await req.json();
    if (!text && !fileBase64 && (!files || files.length === 0)) {
      return new Response(JSON.stringify({ error: "Text oder Datei ist erforderlich" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY is not configured");
    // Build learning context from past risk analyses
    const learningContext = await buildRiskLearningContext(context || '');
    const systemPrompt = `Du bist ein KI-Assistent für geschäftliche Risikoanalyse und Vertragsanalyse.
Du bist KEIN Anwalt ? du denkst wie ein Chief Risk Officer (CRO).
KERNAUFGABE: Zerlege Verträge und Dokumente in ihre Einzelteile und bewerte jedes Element einzeln:
- Identifiziere jede Klausel, jeden Absatz, jede Regelung
- Bewerte das Risiko jedes Bestandteils (hoch/mittel/niedrig)
- Erkenne versteckte Risiken und asymmetrische Klauseln
- Finde fehlende Schutzklauseln
RISIKOMANAGEMENT-FOKUS (nicht juristisch, sondern geschäftlich):
- Finanzielle Auswirkungen: Was kostet es im Best/Worst Case?
- Operationelles Risiko: Welche Geschäftsprozesse sind betroffen?
- Reputationsrisiko: Wie wirkt sich das auf die Marke aus?
- Compliance-Risiko: Welche regulatorischen Folgen drohen?
- Strategisches Risiko: Wie beeinflusst das die Geschäftsstrategie?
GESETZE: Nenne relevante Paragraphen, aber erkläre sie im Business-Kontext.
LERNFÄHIGKEIT: Nutze Erfahrungen aus vergangenen Analysen für bessere Einschätzungen.
${learningContext}
Antworte ausschließlich im geforderten JSON-Format über den Tool-Call.`;
    const fileCount = files?.length || (fileBase64 ? 1 : 0);
    const userPromptText = text
      ? `Analysiere diesen Text${fileCount > 0 ? ` und die ${fileCount} hochgeladenen Datei(en)` : ''} und extrahiere die Risikodaten. Zerlege den Vertrag in seine Einzelteile:\n\n${context ? `Kontext: ${context}\n\n` : ''}Dokumenttext:\n${text.slice(0, 8000)}`
      : `Analysiere die ${fileCount} hochgeladene(n) Datei(en), zerlege sie in Einzelteile und extrahiere die Risikodaten.${context ? `\n\nKontext: ${context}` : ''}`;
    const userContent: any[] = [];
    if (files && files.length > 0) {
      for (const f of files) {
        userContent.push({
          type: "image_url",
          image_url: { url: `data:${f.mimeType};base64,${f.base64}` },
        });
      }
    } else if (fileBase64 && fileMimeType) {
      userContent.push({
        type: "image_url",
        image_url: { url: `data:${fileMimeType};base64,${fileBase64}` },
      });
    }
    userContent.push({ type: "text", text: userPromptText });
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
          { role: "user", content: userContent },
        ],
        tools: [{
          type: "function",
          function: {
            name: "extract_risk_data",
            description: "Extrahiere strukturierte Risikodaten und Vertragsbestandteile aus dem Dokument",
            parameters: {
              type: "object",
              properties: {
                zusammenfassung: { type: "string", description: "Kurze Zusammenfassung (2-3 Sätze)" },
                kategorie: {
                  type: "string",
                  enum: ["Steueroptimierung", "IP-Streitigkeit", "Vertragsmanagement", "Forderungsmanagement", "Arbeitsrecht", "M&A / Transaktion", "Compliance / Regulierung", "Geschäftsbeziehung"],
                },
                vertragsbestandteile: {
                  type: "array",
                  description: "Zerlegung des Vertrags/Dokuments in Einzelteile mit Risikobewertung",
                  items: {
                    type: "object",
                    properties: {
                      titel: { type: "string", description: "Name der Klausel/des Abschnitts" },
                      inhalt: { type: "string", description: "Zusammenfassung des Inhalts" },
                      risiko: { type: "string", enum: ["hoch", "mittel", "niedrig"], description: "Risikostufe" },
                      bewertung: { type: "string", description: "Business-Bewertung: Was bedeutet das für das Unternehmen?" },
                    },
                    required: ["titel", "inhalt", "risiko", "bewertung"],
                  },
                },
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
                      bestCase: { type: "number" },
                      worstCase: { type: "number" },
                      likelyCase: { type: "number" },
                      minMonths: { type: "number" },
                      maxMonths: { type: "number" },
                      relevanteLaws: { type: "array", items: { type: "string" } },
                      proArgumente: { type: "array", items: { type: "string" } },
                      contraArgumente: { type: "array", items: { type: "string" } },
                    },
                    required: ["label", "description", "erfolgswahrscheinlichkeit"],
                  },
                },
                risiken: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      label: { type: "string" },
                      auftretenswahrscheinlichkeit: { type: "number", description: "1-10" },
                      bedeutung: { type: "number", description: "1-10" },
                      entdeckungswahrscheinlichkeit: { type: "number", description: "1-10" },
                    },
                    required: ["label"],
                  },
                },
                fristen: {
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
                    required: ["label"],
                  },
                },
                konfidenz: { type: "string", enum: ["hoch", "mittel", "niedrig"] },
                warnungen: { type: "array", items: { type: "string" } },
              },
              required: ["zusammenfassung", "kategorie", "optionen", "konfidenz"],
            },
          },
        }],
        tool_choice: { type: "function", function: { name: "extract_risk_data" } },
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
    console.error("analyze-contract error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
