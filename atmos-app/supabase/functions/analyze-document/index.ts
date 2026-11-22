import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
async function extractFileText(supabase: any, storagePath: string, mimeType: string): Promise<string> {
  try {
    const { data, error } = await supabase.storage.from('business-files').download(storagePath);
    if (error || !data) return '';
    if (['text/csv', 'text/plain', 'application/json', 'application/xml'].includes(mimeType)) {
      return (await data.text()).slice(0, 12000);
    }
    if (mimeType.includes('spreadsheet') || mimeType.includes('excel')) {
      return '[Excel-Datei ? Inhalte nicht direkt lesbar]';
    }
    if (mimeType.includes('word') || mimeType.includes('document')) {
      return '[Word-Datei ? Inhalte nicht direkt lesbar]';
    }
    if (mimeType === 'application/pdf') {
      return '[PDF-Datei ? Inhalte nicht direkt lesbar]';
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
    const { fragestellung, uploadedFiles } = await req.json();
    let fileContext = '';
    if (uploadedFiles?.length) {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, serviceKey);
      const fileTexts: string[] = [];
      for (const file of uploadedFiles) {
        const text = await extractFileText(supabase, file.storagePath, file.type);
        if (text) fileTexts.push(`\n--- Datei: ${file.name} (${file.type}) ---\n${text}`);
      }
      if (fileTexts.length) fileContext = `\n\nDateiinhalte:${fileTexts.join('\n')}`;
    }
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY is not configured");
    const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "google/gemini-3-flash-preview",
        messages: [
          {
            role: "system",
            content: `Du bist ein juristischer Dokumentenanalyst. Analysiere hochgeladene Dokumente und Fragestellungen.
REGELN:
- Nenne IMMER konkrete deutsche Paragraphen (z.B. § 823 BGB, § 370 AO)
- Identifiziere Risiken mit Schweregrad (hoch/mittel/niedrig)
- Gib konkrete, umsetzbare Empfehlungen
- Bei Finanz-/Steuerdokumenten: Berechne Lohnt-es-sich-Analyse
- Analysiere CSV/Text-Daten konkret mit Zahlen
Antworte ausschließlich über den Tool-Call.`
          },
          {
            role: "user",
            content: `Analysiere folgende Dokumente und beantworte die Fragestellung:\n\nFragestellung: ${fragestellung || 'Allgemeine Analyse ? Risiken, Empfehlungen, relevante Gesetze'}${fileContext}`
          }
        ],
        tools: [{
          type: "function",
          function: {
            name: "analyze_document",
            description: "Analysiere Dokumente und gib strukturierte Ergebnisse",
            parameters: {
              type: "object",
              properties: {
                zusammenfassung: { type: "string" },
                risiken: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      label: { type: "string" },
                      schwere: { type: "string", enum: ["hoch", "mittel", "niedrig"] },
                      beschreibung: { type: "string" }
                    },
                    required: ["label", "schwere", "beschreibung"]
                  }
                },
                empfehlungen: { type: "array", items: { type: "string" } },
                relevanteParagraphen: { type: "array", items: { type: "string" } },
                lohntEsSich: {
                  type: "object",
                  properties: {
                    ersparnis: { type: "number" },
                    kosten: { type: "number" },
                    fazit: { type: "string" }
                  }
                }
              },
              required: ["zusammenfassung", "risiken", "empfehlungen", "relevanteParagraphen"]
            }
          }
        }],
        tool_choice: { type: "function", function: { name: "analyze_document" } },
      }),
    });
    if (!response.ok) {
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
    console.error("analyze-document error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
