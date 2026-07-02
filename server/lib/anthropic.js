const API_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-sonnet-5";

export class AnthropicNotConfigured extends Error {
  constructor() {
    super("ANTHROPIC_API_KEY ist nicht gesetzt. Bitte in server/.env eintragen.");
    this.name = "AnthropicNotConfigured";
  }
}

async function callMessages({ messages, maxTokens = 1000, tools }) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new AnthropicNotConfigured();

  const res = await fetch(API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: maxTokens,
      messages,
      ...(tools ? { tools } : {}),
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Anthropic API Fehler (${res.status}): ${body.slice(0, 300)}`);
  }
  const data = await res.json();
  return data.content
    .filter((c) => c.type === "text")
    .map((c) => c.text)
    .join("\n");
}

export function analyzeStatement(statementText) {
  return callMessages({
    maxTokens: 1500,
    messages: [
      {
        role: "user",
        content: `Analysiere diesen Kontoauszug/Zahlungsexport. Finde ALLE wiederkehrenden Zahlungen (Abos, Mitgliedschaften, Mobilfunk etc.) und markiere verdächtige Abbuchungen (unbekannte Firmen, ausländische/unplausible IBANs, plötzliche Betragssprünge, generische Firmennamen). Antworte NUR mit validem JSON, ohne Markdown-Codeblock:
{"subs":[{"name":"...","amount":0.00,"iban":"...","suspicious":false,"reason":"..."}],"summary":"kurze Zusammenfassung auf Deutsch"}

Kontoauszug:
${statementText}`,
      },
    ],
  });
}

export function companyReport({ name, ibanCountry, amount }) {
  return callMessages({
    maxTokens: 900,
    tools: [{ type: "web_search_20250305", name: "web_search" }],
    messages: [
      {
        role: "user",
        content: `Erstelle einen kurzen Seriositäts-Bericht über die Firma "${name}" (IBAN-Land: ${ibanCountry || "unbekannt"}, monatliche Abbuchung: ${amount}€). Recherchiere: Existiert die Firma? Gibt es Betrugswarnungen oder auffällig viele Beschwerden? Ist der Betrag plausibel für diese Art von Dienstleistung? Bewerte das Risiko (niedrig/mittel/hoch) und begründe kurz. Max. 150 Wörter, auf Deutsch. Wichtig: Formuliere als Wahrscheinlichkeits-Einschätzung, nicht als Tatsachenbehauptung.`,
      },
    ],
  });
}

export function cancellationLetter({ name, since, note }) {
  return callMessages({
    maxTokens: 500,
    messages: [
      {
        role: "user",
        content: `Verfasse eine kurze, höfliche, aber bestimmte Kündigung für das Abo/den Vertrag "${name}" (Kunde seit ${since || "unbekannt"}). Kontext: ${note || "keiner"}. Format: Betreff-Zeile, dann Brieftext auf Deutsch, zum ordentlichen nächstmöglichen Termin, mit Bitte um schriftliche Bestätigung. Antworte NUR mit validem JSON ohne Markdown: {"subject":"...","body":"..."}`,
      },
    ],
  });
}
