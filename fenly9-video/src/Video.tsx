import React from "react";
import { AbsoluteFill, Audio, Sequence, Series, staticFile, interpolate, useVideoConfig } from "remotion";
import { SCENES, SceneId, sceneFrames, VOICE_ENABLED, MUSIC_ENABLED, SUBTITLES, TOTAL_FRAMES } from "./config";
import { SceneFade, Subtitle } from "./components";
import * as S from "./scenes";

const MAP: Record<SceneId, React.FC> = {
  schatten: S.Schatten, machiavelli: S.Machiavelli, suntzu: S.SunTzu, reiche: S.Reiche,
  reveal: S.Reveal, module: S.Module, vertrag: S.Vertrag, zukunft: S.Zukunft,
  unternehmen: S.Unternehmen, briefing: S.Briefing, angriff: S.Angriff, finale: S.Finale,
};

export const FenlyFilm: React.FC = () => {
  const { fps } = useVideoConfig();
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {MUSIC_ENABLED && (
        <Audio src={staticFile("music/score.mp3")} loop
          volume={(f) => interpolate(f, [0, 2 * fps, TOTAL_FRAMES - 3 * fps, TOTAL_FRAMES], [0, 0.32, 0.32, 0], { extrapolateRight: "clamp" })} />
      )}
      <Series>
        {SCENES.map((s) => {
          const C = MAP[s.id];
          const d = sceneFrames(s);
          return (
            <Series.Sequence key={s.id} durationInFrames={d}>
              <C />
              <SceneFade duration={d} />
              {SUBTITLES && <Subtitle text={s.voice} duration={d} />}
              {VOICE_ENABLED && (
                <Sequence from={10}><Audio src={staticFile(`voice/${s.id}.mp3`)} volume={1} /></Sequence>
              )}
            </Series.Sequence>
          );
        })}
      </Series>
    </AbsoluteFill>
  );
};
