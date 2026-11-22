import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  try {
    const { person, caseContext } = await req.json();
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY not configured");
    const systemPrompt = `Du bist ein forensischer Psychologe, spezialisiert auf die Einschätzung von Prozessbeteiligten.
Basierend auf den bereitgestellten Notizen, früheren Aussagen und dem Fallkontext schätzt du psychologische Dimensionen ein.
Antworte IMMER auf Deutsch. Sei zurückhaltend und differenziert ? keine Diagnosen, nur taktische Einschätzungen.
Begründe jede Einschätzung kurz mit Bezug auf die vorliegenden Informationen.`;
    const userPrompt = `Schätze folgende Person psychologisch ein:
NAME: ${person.name}
ROLLE: ${person.role}
PARTEI: ${person.party || "Nicht angegeben"}
GERICHT: ${person.court || "Nicht angegeben"}
BISHERIGE AUSSAGEN/FÄLLE: ${person.historicalCases}
BEKANNTE WIDERSPRÜCHE: ${person.priorContradictions}
NOTIZEN / AUFFÄLLIGKEITEN:
${person.pastCaseNotes || "Keine Notizen vorhanden."}
${caseContext ? `FALLKONTEXT:
- Rechtsgebiet: ${caseContext.type || "N/A"}
- Prozessziel: ${caseContext.goal || "N/A"}
- Instanz: ${caseContext.instanz || "N/A"}` : ""}
Schätze die psychologischen Dimensionen auf einer Skala von 0-100 ein und begründe jede Einschätzung.`;
    const tools = [{
      type: "function",
      function: {
        name: "psycho_profile",
        description: "Return psychological profile estimation",
        parameters: {
          type: "object",
          properties: {
            narcissism: { type: "number", description: "0-100: Selbstüberschätzung, Geltungsdrang" },
            cognitiveEmpathy: { type: "number", description: "0-100: Fähigkeit Emotionen anderer zu lesen" },
            affectiveEmpathy: { type: "number", description: "0-100: Echtes Mitgefühl" },
            manipulationSkill: { type: "number", description: "0-100: Strategisches Kalkül, Täuschungstalent" },
            coldness: { type: "number", description: "0-100: Emotionale Kälte, fehlende Reue" },
            conflictOfInterest: { type: "number", description: "0-100: Befangenheit / Eigeninteresse" },
            hiddenMotive: { type: "number", description: "0-100: Verdeckte Agenda" },
            selfPreservation: { type: "number", description: "0-100: Wahrheit beugen zum Selbstschutz" },
            fearFactor: { type: "number", description: "0-100: Unter Druck manipulierbar" },
            loyaltySignals: { type: "number", description: "0-100: Erkennbare Nähe zu einer Seite" },
            competenceLevel: { type: "number", description: "0-100: Fachliche Eignung" },
            historicalConsistency: { type: "number", description: "0-100: Beständigkeit früherer Aussagen" },
            reasoning: { type: "string", description: "Kurze Begründung der Einschätzung (2-4 Sätze)" },
            suggestedPsychLevers: {
              type: "array",
              items: { type: "string" },
              description: "Empfohlene psychologische Hebel aus: Geschwätzigkeit provozieren, Eitelkeit ausnutzen, Angst / Unsicherheit schüren, Übertreibung provozieren, Autoritätshörigkeit testen, Kontrollverlust herbeiführen"
            },
            suggestedLegalLevers: {
              type: "array",
              items: { type: "string" },
              description: "Empfohlene juristische Hebel aus: Befangenheitsangriff, Widerspruch zur Beweislage, Glaubwürdigkeitsangriff, Zeugnisverweigerungsrecht prüfen, Vereidigung thematisieren, Protokollgenauigkeit erzwingen"
            },
          },
          required: ["narcissism", "cognitiveEmpathy", "affectiveEmpathy", "manipulationSkill", "coldness", "conflictOfInterest", "hiddenMotive", "selfPreservation", "fearFactor", "loyaltySignals", "competenceLevel", "historicalConsistency", "reasoning"],
        },
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
        tool_choice: { type: "function", function: { name: "psycho_profile" } },
      }),
    });
    if (!response.ok) {
      const status = response.status;
      if (status === 429) {
        return new Response(JSON.stringify({ error: "Rate limit erreicht. Bitte versuchen Sie es in einer Minute erneut." }), {          status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (status === 402) {
        return new Response(JSON.stringify({ error: "Guthaben aufgebraucht." }), {
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
        result = null;
      }
    }
    if (!result) {
      throw new Error("Keine verwertbare Analyse erhalten.");
    }
    return new Response(JSON.stringify({ success: true, result }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Profile person error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
