// Erzeugt die Sprecherinnen-Stimme pro Szene mit ElevenLabs (Deutsch, weiblich).
// Aufruf (Mac/Linux):  ELEVENLABS_API_KEY=xxx VOICE_ID=yyy npm run voice
// Windows PowerShell:  $env:ELEVENLABS_API_KEY="xxx"; $env:VOICE_ID="yyy"; npm run voice
import fs from "node:fs";
import path from "node:path";

const key = process.env.ELEVENLABS_API_KEY;
const voice = process.env.VOICE_ID;
if (!key || !voice) { console.error("Bitte ELEVENLABS_API_KEY und VOICE_ID setzen."); process.exit(1); }

const V = JSON.parse(fs.readFileSync(new URL("../src/voice.json", import.meta.url), "utf8"));
const scenes = Object.entries(V).map(([id, lines]) => ({ id, text: lines.join(" ") }));
const only = process.argv[2]; // optional: nur eine Szene, z. B. "npm run voice s9"
const outDir = path.resolve("public/voice");
fs.mkdirSync(outDir, { recursive: true });

for (const s of scenes.filter((x) => !only || x.id === only)) {
  // "..." im Skript = bewusste Pause
  const text = s.text.replace(/\s*\.\.\.\s*/g, ' <break time="1.2s" /> ');
  const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}?output_format=mp3_44100_192`, {
    method: "POST",
    headers: { "xi-api-key": key, "Content-Type": "application/json" },
    body: JSON.stringify({
      text, model_id: "eleven_multilingual_v2", language_code: "de",
      // ruhig, tief, souverän: mittlere Stabilität, etwas Stil, leicht verlangsamt
      voice_settings: { stability: 0.5, similarity_boost: 0.85, style: 0.3, use_speaker_boost: true, speed: 0.92 },
    }),
  });
  if (!res.ok) { console.error(s.id, res.status, await res.text()); process.exit(1); }
  fs.writeFileSync(path.join(outDir, `${s.id}.mp3`), Buffer.from(await res.arrayBuffer()));
  console.log("✓", s.id);
}
console.log("Fertig. Die Szenenlängen passen sich beim nächsten Start automatisch an.");
