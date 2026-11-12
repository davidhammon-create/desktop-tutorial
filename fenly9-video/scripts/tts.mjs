// Erzeugt die Sprecherstimme pro Szene mit ElevenLabs (deutsch, weiblich).
// Aufruf:  ELEVENLABS_API_KEY=xxx VOICE_ID=yyy npm run voice
import fs from "node:fs";
import path from "node:path";

const key = process.env.ELEVENLABS_API_KEY;
const voice = process.env.VOICE_ID; // in ElevenLabs: Voice Library -> weibliche, tiefe, ruhige Stimme -> ID kopieren
if (!key || !voice) { console.error("ELEVENLABS_API_KEY und VOICE_ID setzen."); process.exit(1); }

const cfg = fs.readFileSync(new URL("../src/config.ts", import.meta.url), "utf8");
const scenes = [...cfg.matchAll(/id: "(\w+)", seconds: [\d.]+,\s*voice: "([^"]+)"/g)].map((m) => ({ id: m[1], text: m[2] }));
const outDir = path.resolve("public/voice");
fs.mkdirSync(outDir, { recursive: true });

for (const s of scenes) {
  const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}?output_format=mp3_44100_128`, {
    method: "POST",
    headers: { "xi-api-key": key, "Content-Type": "application/json" },
    body: JSON.stringify({
      text: s.text,
      model_id: "eleven_multilingual_v2",
      // niedrige Stabilität = mehr Ausdruck; hoher Style = dramatischer
      voice_settings: { stability: 0.45, similarity_boost: 0.8, style: 0.35, use_speaker_boost: true },
    }),
  });
  if (!res.ok) { console.error(s.id, res.status, await res.text()); process.exit(1); }
  fs.writeFileSync(path.join(outDir, `${s.id}.mp3`), Buffer.from(await res.arrayBuffer()));
  console.log("✓", s.id);
}
console.log("Fertig. Jetzt in src/config.ts VOICE_ENABLED = true setzen.");
