import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};
function arrayBufferToBase64(buffer: ArrayBuffer): string {
  let binary = '';
  const bytes = new Uint8Array(buffer);
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}
/** Extract text from DOCX by parsing the XML inside the ZIP */
async function extractDocxText(arrayBuffer: ArrayBuffer): string {
  try {
    const bytes = new Uint8Array(arrayBuffer);
    // DOCX is a ZIP file. Find document.xml inside it.
    // Look for PK signature and find document.xml entry
    const textDecoder = new TextDecoder('utf-8', { fatal: false });

    // Simple approach: decode raw bytes, find XML content between tags
    const raw = textDecoder.decode(bytes);

    // Try to find word/document.xml content within the ZIP
    // DOCX XML has <w:t> tags containing text
    const textParts: string[] = [];
    const wtRegex = /<w:t[^>]*>([^<]*)<\/w:t>/g;
    let match;
    while ((match = wtRegex.exec(raw)) !== null) {
      if (match[1]) textParts.push(match[1]);
    }

    if (textParts.length > 0) {
      const result = textParts.join(' ').replace(/\s+/g, ' ').trim();
      if (result.length > 50) return result;
    }

    // Fallback: also try extracting from paragraphs
    const paraRegex = /<w:p\b[^>]*>([\s\S]*?)<\/w:p>/g;
    const paragraphs: string[] = [];
    while ((match = paraRegex.exec(raw)) !== null) {
      const inner = match[1];
      const texts: string[] = [];
      const innerWt = /<w:t[^>]*>([^<]*)<\/w:t>/g;
      let m2;
      while ((m2 = innerWt.exec(inner)) !== null) {
        if (m2[1]) texts.push(m2[1]);
      }
      if (texts.length > 0) paragraphs.push(texts.join(''));
    }

    if (paragraphs.length > 0) {
      return paragraphs.join('\n').slice(0, 40000);
    }

    return '';
  } catch (e) {
    console.error('DOCX extraction error:', e);
    return '';
  }
}
/** Use Gemini Vision API to OCR a document (PDF or image) */
async function ocrWithVision(fileBytes: ArrayBuffer, mimeType: string, apiKey: string): Promise<string> {
  const base64 = arrayBufferToBase64(fileBytes);

  const response = await fetch("https://ai.gateway.lovable.dev/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "google/gemini-2.5-flash",
      messages: [{
        role: "user",
        content: [
          {
            type: "text",
            text: "Extrahiere den GESAMTEN Text aus diesem Dokument, Seite für Seite. Gib NUR den extrahierten Text zurück, ohne Kommentare oder Formatierung. Markiere Seitenwechsel mit '--- Seite X ---'. Lies ALLE Seiten vollständig."
          },
          {
            type: "image_url",
            image_url: {
              url: `data:${mimeType};base64,${base64}`,
            },
          },
        ],
      }],
    }),
  });
  if (!response.ok) {
    const errText = await response.text().catch(() => '');
    console.error("Vision OCR error:", response.status, errText);
    throw new Error(`Vision OCR failed: ${response.status}`);
  }
  const data = await response.json();
  return data.choices?.[0]?.message?.content || '';
}
/** Check if extracted text is usable (not garbage) */
function isTextUsable(text: string): boolean {
  if (!text || text.length < 50) return false;
  const words = text.match(/[a-zA-ZäöüÄÖÜß]{3,}/g) || [];
  const wordChars = words.join('').length;
  const totalChars = text.replace(/\s/g, '').length;
  if (totalChars === 0) return false;
  return wordChars > totalChars * 0.25;
}
async function extractFileText(supabase: any, storagePath: string, mimeType: string, apiKey: string): Promise<string> {
  try {
    const { data, error } = await supabase.storage.from('business-files').download(storagePath);
    if (error || !data) {
      console.error('Storage download error:', error);
      return '';
    }

    // Plain text formats
    if (['text/csv', 'text/plain', 'application/json', 'application/xml'].includes(mimeType)) {
      return (await data.text()).slice(0, 40000);
    }

    // Word documents ? parse XML structure, fallback to Vision OCR
    if (mimeType.includes('word') || mimeType.includes('document')) {
      try {
        const arrayBuffer = await data.arrayBuffer();
        const docxText = await extractDocxText(arrayBuffer);

        if (isTextUsable(docxText)) {
          console.log(`DOCX XML extraction successful (${docxText.length} chars)`);
          return docxText.slice(0, 40000);
        }

        // Fallback: Vision OCR with correct MIME type
        console.log('DOCX XML extraction poor, using Vision OCR...');
        // Convert to images isn't possible, so we send as-is with correct mime
        // Gemini supports docx directly
        const ocrText = await ocrWithVision(arrayBuffer, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', apiKey);
        if (ocrText && ocrText.length > 20) {
          console.log(`DOCX Vision OCR successful (${ocrText.length} chars)`);
          return ocrText.slice(0, 40000);
        }

        return '[Word-Datei ? Text konnte nicht extrahiert werden. Bitte Text manuell einfügen.]';
      } catch (e) {
        console.error('DOCX extraction error:', e);
        return '[Word-Datei ? Textextraktion fehlgeschlagen]';
      }
    }

    // PDF: Always use Vision OCR (native extraction produces garbage on most legal PDFs)
    if (mimeType === 'application/pdf') {
      try {
        const arrayBuffer = await data.arrayBuffer();

        console.log('Using Vision OCR for PDF...');
        const ocrText = await ocrWithVision(arrayBuffer, 'application/pdf', apiKey);

        if (ocrText && isTextUsable(ocrText)) {
          console.log(`PDF Vision OCR successful (${ocrText.length} chars)`);
          return ocrText.slice(0, 40000);
        }

        return '[PDF-Datei ? Text konnte nicht extrahiert werden. Bitte Text manuell einfügen.]';
      } catch (e) {
        console.error('PDF extraction error:', e);
        return '[PDF-Datei ? Textextraktion fehlgeschlagen]';
      }
    }

    // Images ? use Vision OCR directly
    if (mimeType.startsWith('image/')) {
      try {
        const arrayBuffer = await data.arrayBuffer();
        const ocrText = await ocrWithVision(arrayBuffer, mimeType, apiKey);
        if (ocrText && ocrText.length > 10) return ocrText.slice(0, 40000);
        return '[Bild ? Text konnte nicht extrahiert werden]';
      } catch (e) {
        console.error('Image OCR error:', e);
        return '[Bild ? OCR fehlgeschlagen]';
      }
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
    const { text, caseName, caseType, uploadedFiles } = await req.json();
    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY is not configured");
    let combinedText = text || '';
    if (uploadedFiles?.length) {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, serviceKey);
      for (const file of uploadedFiles) {
        const fileText = await extractFileText(supabase, file.storagePath, file.type, LOVABLE_API_KEY);
        if (fileText) {
          combinedText += `\n\n--- Dokument: ${file.name} ---\n${fileText}`;
        }
      }
      // DSGVO: Delete uploaded files after extraction
      for (const file of uploadedFiles) {
        try {
          await supabase.storage.from('business-files').remove([file.storagePath]);
        } catch (e) {
          console.error('File cleanup error:', e);
        }
      }
    }
    if (!combinedText.trim()) {
      return new Response(JSON.stringify({ error: "Text oder Dokument ist erforderlich" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const systemPrompt = `Du bist ein erfahrener juristischer Analyst mit Expertise in deutscher Rechtsprechung.
Analysiere den folgenden Text EXTREM GRÜNDLICH und DETAILLIERT. Lies JEDES Wort.
WICHTIG: Deine Analyse ist ein Vorschlag. Der Anwalt muss alle extrahierten Argumente nachträglich prüfen und validieren.
## DEINE AUFGABEN:
### 1. ARGUMENTE EXTRAHIEREN
- Finde ALLE rechtlichen Argumente, Tatsachenbehauptungen und Schlussfolgerungen
- Kategorisiere als 'own' (eigene Seite/Kläger) oder 'opp' (Gegenseite/Beklagter)
- Bewerte die Stärke von 1-10 mit Begründung
- Nenne IMMER die exakten Paragraphen (§§) die im Text erwähnt oder impliziert werden (z.B. "§823 Abs. 1 BGB", "§280 Abs. 1 BGB")
- Wenn ein Paragraph nur impliziert wird, kennzeichne ihn als "(impliziert)"
### 2. WIDERSPRÜCHE FINDEN
- Suche nach Widersprüchen INNERHALB des Textes (z.B. widersprüchliche Datumsangaben, sich widersprechende Aussagen)
- Suche nach Widersprüchen zu allgemeinem Recht oder gängiger Rechtsprechung
- Jeder Widerspruch ist ein potenzielles Angriffsziel!
### 3. DRUCKMITTEL IDENTIFIZIEREN
- Finde Punkte, die als Druckmittel/Hebel in Verhandlungen genutzt werden können
- z.B. Fristversäumnisse der Gegenseite, fehlerhafte Belehrungen, Formfehler, fehlende Nachweise
- Bewerte die Stärke des Druckmittels (1-10)
### 4. SCHWACHSTELLEN AUFDECKEN
- Wo fehlen Beweise? Wo sind Lücken in der Argumentation?
- Welche Gegenargumente könnte die andere Seite vorbringen?
- Wo sind formale Fehler?
- WICHTIG: Zeige auch Schwächen der EIGENEN Seite auf ? wo ist man angreifbar?
### 5. PARAGRAPHEN SAMMELN
- Liste ALLE im Text genannten oder relevanten Paragraphen auf
- Ergänze weitere anwendbare Paragraphen die der Text nicht nennt aber die relevant sein könnten
### 6. PSYCHOLOGISCHE SCHWÄCHEN & PROFILE (nach Machiavelli / 48 Laws of Power)
Analysiere den Text auf psychologische Hinweise BEIDER Seiten:
- Verteidiger/Eigene Seite: Welche psychischen Schwächen sind erkennbar? (z.B. Unsicherheit, Überheblichkeit, emotionale Reaktionen, Nachgiebigkeit, fehlende Konsequenz)
- Gegenseite: Welche psychischen Schwächen kann man ausnutzen? (z.B. Ungeduld, Kontrollzwang, Angst vor Öffentlichkeit, Reputationsrisiko)
- Welche der 48 Laws of Power sind anwendbar? (z.B. Law 3: Conceal your Intentions, Law 6: Court Attention, Law 15: Crush your Enemy Totally, Law 17: Keep Others in Suspended Terror, Law 33: Discover Each Man's Thumbscrew)
- Welche machiavellistischen Taktiken ergeben sich aus dem Text? (z.B. Spaltung, Zeitdruck, Informationsasymmetrie, kontrollierte Eskalation)
- Identifiziere konkrete Textstellen die auf psychologische Muster hindeuten
- WICHTIG: Zeige auch wo der Mandant selbst psychologisch angreifbar ist (Selbstschutz-Analyse)
### 7. STRÄNGE (KAUSALZUSAMMENHÄNGE) ? SEHR WICHTIG!
Wenn du Kausalzusammenhänge zwischen Argumenten erkennst, erstelle automatisch einen Strang:
- Identifiziere welche Argumente sich gegenseitig STÜTZEN (z.B. "Vertragsverletzung" ? "Schadensersatzanspruch")
- Identifiziere welche Argumente andere SCHWÄCHEN (z.B. "Mitverschulden" schwächt "Schadensersatzanspruch")
- Identifiziere KAUSALE Zusammenhänge (z.B. "Pflichtverletzung" ? "Schaden" ? "Kausalität" ? "Anspruch")
- Nutze die INDEX-Nummern der Argumente (0-basiert, in der Reihenfolge wie sie in "argumente" erscheinen)
- Erstelle so viele Verbindungen wie sinnvoll ? jede erkannte Kette stärkt die Analyse!
- Typen: "supports" (stützt), "weakens" (schwächt), "causal" (Kausalzusammenhang)
SEITENREFERENZEN: Gib für jedes Argument eine ungefähre Seitenangabe an (seite Feld).
Schätze die Seite basierend auf der Position im Text (ca. 3000 Zeichen = 1 Seite).
Falls der Text kurz ist (unter 3000 Zeichen), setze seite auf null.
SEI GRÜNDLICH! Lieber zu viele Argumente als zu wenige. Übersehe NICHTS.`;
    const userPrompt = `${caseName ? `Fall: ${caseName}\n` : ''}${caseType ? `Typ: ${caseType}\n\n` : ''}Text zur Analyse (JEDES Detail beachten!):
${combinedText.slice(0, 25000)}`;
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
        tools: [{
          type: "function",
          function: {
            name: "extract_arguments",
            description: "Extrahiere Argumente, Widersprüche, Druckmittel und Paragraphen aus dem juristischen Text",
            parameters: {
              type: "object",
              properties: {
                argumente: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      label: { type: "string", description: "Kurzer prägnanter Titel des Arguments" },
                      content: { type: "string", description: "Ausführliche Beschreibung mit Zitaten aus dem Text" },
                      side: { type: "string", enum: ["own", "opp"] },
                      strength: { type: "number", description: "Stärke 1-10" },
                      legal_basis: { type: "string", description: "Exakte Paragraphen z.B. '§823 Abs. 1 BGB, §280 Abs. 1 BGB'" },
                      seite: { type: "number", description: "Ungefähre Seitenzahl im Originaldokument (null wenn kurzer Text)" },
                      arg_type: { type: "string", enum: ["Rechtsargument", "Tatsachenargument", "Beweisargument", "Verfahrensargument", "Druckmittel", "Widerspruch", "Schwachstelle"], description: "Art des Arguments" },
                    },
                    required: ["label", "content", "side", "strength", "arg_type"],
                  },
                },
                widersprueche: {
                  type: "array",
                  description: "Gefundene Widersprüche im Text",
                  items: {
                    type: "object",
                    properties: {
                      titel: { type: "string", description: "Kurze Bezeichnung des Widerspruchs" },
                      beschreibung: { type: "string", description: "Detaillierte Erklärung mit Textstellen" },
                      schwere: { type: "number", description: "Schwere des Widerspruchs 1-10" },
                      seite: { type: "number", description: "Ungefähre Seitenzahl" },
                      angreifbar: { type: "boolean", description: "Ob der Widerspruch juristisch angreifbar ist" },
                    },
                    required: ["titel", "beschreibung", "schwere"],
                  },
                },
                druckmittel: {
                  type: "array",
                  description: "Identifizierte Druckmittel und Hebel",
                  items: {
                    type: "object",
                    properties: {
                      titel: { type: "string", description: "Bezeichnung des Druckmittels" },
                      beschreibung: { type: "string", description: "Warum dies ein Druckmittel ist" },
                      staerke: { type: "number", description: "Stärke 1-10" },
                      zielseite: { type: "string", enum: ["own", "opp"], description: "Gegen welche Seite das Druckmittel wirkt" },
                      legal_basis: { type: "string", description: "Rechtliche Grundlage" },
                    },
                    required: ["titel", "beschreibung", "staerke", "zielseite"],
                  },
                },
                paragraphen: {
                  type: "array",
                  description: "Alle im Text genannten und zusätzlich relevanten Paragraphen",
                  items: {
                    type: "object",
                    properties: {
                      paragraph: { type: "string", description: "z.B. '§823 Abs. 1 BGB'" },
                      kontext: { type: "string", description: "Wie/warum dieser Paragraph relevant ist" },
                      im_text_genannt: { type: "boolean", description: "Ob im Originaltext explizit genannt" },
                    },
                    required: ["paragraph", "kontext", "im_text_genannt"],
                  },
                },
                psycho_profile: {
                  type: "array",
                  description: "Psychologische Schwächen und Profile beider Seiten nach Machiavelli / 48 Laws of Power",
                  items: {
                    type: "object",
                    properties: {
                      seite: { type: "string", enum: ["own", "opp"], description: "Welche Partei betroffen ist" },
                      schwaeche: { type: "string", description: "Identifizierte psychologische Schwäche oder Muster" },
                      beschreibung: { type: "string", description: "Detaillierte Analyse mit Textbelegen" },
                      taktik: { type: "string", description: "Anwendbare Taktik/Law (z.B. 'Law 33: Discover Each Man's Thumbscrew')" },
                      ausnutzbar: { type: "number", description: "Wie stark ausnutzbar 1-10" },
                      kategorie: { type: "string", enum: ["Angst", "Eitelkeit", "Ungeduld", "Kontrollverlust", "Emotionalität", "Naivität", "Überheblichkeit", "Inkonsistenz", "Abhängigkeit", "Sonstige"], description: "Psychologische Kategorie" },
                      textstelle: { type: "string", description: "Relevante Textstelle die auf diese Schwäche hindeutet" },
                    },
                    required: ["seite", "schwaeche", "beschreibung", "ausnutzbar", "kategorie"],
                  },
                },
                eigen_schwaechen: {
                  type: "array",
                  description: "Schwächen und Angriffspunkte der EIGENEN Position ? wo ist man verwundbar?",
                  items: {
                    type: "object",
                    properties: {
                      titel: { type: "string", description: "Kurze Bezeichnung der Schwäche" },
                      beschreibung: { type: "string", description: "Warum dies eine Schwäche ist und wie die Gegenseite sie nutzen könnte" },
                      schwere: { type: "number", description: "Schwere 1-10" },
                      gegenmassnahme: { type: "string", description: "Empfohlene Gegenmaßnahme" },
                      seite: { type: "number", description: "Ungefähre Seitenzahl" },
                    },
                    required: ["titel", "beschreibung", "schwere"],
                  },
                },
                beweismittel: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      name: { type: "string" },
                      type: { type: "string", enum: ["Dokument", "Zeuge", "Gutachten", "Digital", "Sonstige"] },
                      description: { type: "string" },
                      relevanz: { type: "number", description: "1-10" },
                    },
                    required: ["name", "type", "description"],
                  },
                },
                straenge: {
                  type: "array",
                  description: "Kausalzusammenhänge und Stränge zwischen Argumenten. Verwende die Index-Nummern aus dem argumente-Array (0-basiert).",
                  items: {
                    type: "object",
                    properties: {
                      from_index: { type: "number", description: "Index des Quell-Arguments im argumente-Array (0-basiert)" },
                      to_index: { type: "number", description: "Index des Ziel-Arguments im argumente-Array (0-basiert)" },
                      type: { type: "string", enum: ["supports", "weakens", "causal"], description: "Art der Verbindung: supports=stützt, weakens=schwächt, causal=Kausalzusammenhang" },
                      beschreibung: { type: "string", description: "Kurze Erklärung des Zusammenhangs" },
                    },
                    required: ["from_index", "to_index", "type", "beschreibung"],
                  },
                },
                zusammenfassung: { type: "string", description: "Detaillierte Zusammenfassung der Analyse" },
                kernproblem: { type: "string" },
                empfohlene_strategie: { type: "string", description: "Konkrete Strategieempfehlung basierend auf den Erkenntnissen" },
                konfidenz: { type: "string", enum: ["hoch", "mittel", "niedrig"] },
                warnungen: { type: "array", items: { type: "string" }, description: "Wichtige Warnhinweise für den Anwalt" },
              },
              required: ["argumente", "zusammenfassung", "konfidenz", "paragraphen", "psycho_profile", "eigen_schwaechen"],
            },
          },
        }],
        tool_choice: { type: "function", function: { name: "extract_arguments" } },
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
    console.error("extract-arguments error:", e);
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : "Unbekannter Fehler" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
