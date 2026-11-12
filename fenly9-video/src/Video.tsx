import React from "react";
import { AbsoluteFill, Audio, Sequence, Series, interpolate, useVideoConfig } from "remotion";
import { SCENES, SUBTITLES, has, asset } from "./config";
import { SceneFade, Subtitle } from "./components";
import { SCENE_COMPONENTS } from "./scenes";

export type FilmProps = { durations: number[]; only?: number };

export const FenlyFilm: React.FC<FilmProps> = ({ durations, only }) => {
  const { fps, durationInFrames } = useVideoConfig();
  const idx = SCENES.map((_, i) => i).filter((i) => only === undefined || i === only);
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {has("music/score.mp3") && (
        <Audio src={asset("music/score.mp3")} loop volume={(f) =>
          interpolate(f, [0, 2 * fps, durationInFrames - 4 * fps, durationInFrames], [0, 0.28, 0.4, 0], { extrapolateRight: "clamp" })} />
      )}
      {has("sfx/city.mp3") && <Audio src={asset("sfx/city.mp3")} loop volume={0.08} />}
      <Series>
        {idx.map((i) => {
          const s = SCENES[i];
          const d = durations[i] ?? s.min * fps;
          const C = SCENE_COMPONENTS[i];
          return (
            <Series.Sequence key={s.id} durationInFrames={d}>
              <C dur={d} />
              <SceneFade duration={d} />
              {has("sfx/impact.mp3") && [0, 2, 3, 8].includes(i) && <Audio src={asset("sfx/impact.mp3")} volume={0.55} />}
              {has(`voice/${s.id}.mp3`) && (
                <Sequence from={Math.round(0.5 * fps)}><Audio src={asset(`voice/${s.id}.mp3`)} /></Sequence>
              )}
              {SUBTITLES && <Subtitle text={s.voice.replace(" ...", "")} duration={d} />}
            </Series.Sequence>
          );
        })}
      </Series>
    </AbsoluteFill>
  );
};
