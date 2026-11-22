import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  try {
    const { text, contractType, perspective, clauseList, context } = await req.json();
    if (!text) {
      return new Response(JSON.stringify({ error: "Vertragstext ist erforderlich" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY is not configured");
    const perspLabel = perspective === 'A'
      ? 'Auftraggeber/Käufer/Lizenznehmer'
      : 'Leistungserbringer/Verkäufer/Lizenzgeber';
    const systemPrompt = `Du bist ein spezialisierter Vertragsanalyse-Algorithmus. Du analysierst Verträge klauselweise nach einem definierten Inventar.
VERTRAGSTYP: ${contractType}vertrag
ANALYSEPERSPEKTIVE: ${perspLabel} (${perspective}-Perspektive)
KLAUSEL-INVENTAR (zu analysierende Klauseln):
${clauseList}
AUFGABE:
1. Durchsuche den Vertragstext nach JEDER Klausel aus dem Inventar
2. Für jede gefundene Klausel: Extrahiere den Rohwert, bewerte mit Score 0-100
3. Für nicht gefundene Klauseln: Markiere als "nicht gefunden" und bewerte das Fehlen
4. Bewerte IMMER aus der ${perspLabel}-Perspektive
BEWERTUNGSREGELN:
- Score 0-100: 0 = maximal ungünstig, 100 = maximal günstig für ${perspLabel}
- Klasse I (Existenziell): Fehlen = automatisch Score 0-20
- Klasse II (Strategisch): Fehlen = Score 20-40 je nach gesetzlicher Lage
- Klasse III-V: Fehlen = Score 40-60
- Confidence: 0-100 wie sicher du bist, die richtige Stelle gefunden zu haben
HISTORISCHE BENCHMARKS (für Kontext):
- Haftungsdeckel: Median bei 100-150% Vertragswert
- Zahlungsziel: Median 30 Tage (DL), 14-30 Tage (Kauf)
- Gewährleistung: Median 24 Monate
- Kündigungsfrist: Median 3 Monate
Antworte NUR über den Tool-Call.`;
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
          { role: "user", content: `Analysiere diesen ${contractType}vertrag klauselweise:\n\n${context ? `Kontext: ${context}\n\n` : ''}${text.slice(0, 12000)}` },
        ],
        tools: [{
          type: "function",
          function: {
            name: "extract_clause_scores",
            description: "Extrahiere Klausel-Scores aus dem Vertrag",
            parameters: {
              type: "object",
              properties: {
                zusammenfassung: { type: "string", description: "Executive Summary: 3-4 Sätze Gesamtbewertung" },
                clauses: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      clauseId: { type: "string", description: "Klausel-ID z.B. DL-07, KV-03, LV-12" },
                      rawValue: { type: "string", description: "Extrahierter Rohwert oder 'nicht gefunden'" },
                      score: { type: "number", description: "0-100 Score aus der gewählten Perspektive" },
                      confidence: { type: "number", description: "0-100 Konfidenz der Extraktion" },
                      comment: { type: "string", description: "Kurzer Kommentar zur Klausel" },
                      bewertung: { type: "string", description: "Business-Bewertung: Was bedeutet das konkret?" },
                      verhandlungsempfehlung: { type: "string", description: "Konkrete Verhandlungsempfehlung wenn Score < 60" },
                    },
                    required: ["clauseId", "rawValue", "score", "confidence"],
                  },
                },
              },
              required: ["zusammenfassung", "clauses"],
            },
          },
        }],
        tool_choice: { type: "function", function: { name: "extract_clause_scores" } },
      }),
    });
    if (!response.ok) {
      if (response.status === 429) {
        return new Response(JSON.stringify({ error: "Zu viele Anfragen. Bitte warten." }), {
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
    console.error("analyze-contract-clauses error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
