import React from "react";
import { Composition, CalculateMetadataFunction, staticFile } from "remotion";
import { getAudioDurationInSeconds } from "@remotion/media-utils";
import { FenlyFilm, FilmProps } from "./Video";
import { FPS, SCENES, has } from "./config";

/** Szenenlänge = max(Mindestdauer, Länge der Sprachaufnahme + 1,4 s Luft) */
const calc: CalculateMetadataFunction<FilmProps> = async ({ props }) => {
  const durations = await Promise.all(SCENES.map(async (s) => {
    let sec = s.min;
    const v = `voice/${s.id}.mp3`;
    if (has(v)) sec = Math.max(sec, (await getAudioDurationInSeconds(staticFile(v))) + 1.4);
    return Math.round(sec * FPS);
  }));
  const pick = props.only === undefined ? durations : [durations[props.only]];
  return { durationInFrames: pick.reduce((a, b) => a + b, 0), props: { ...props, durations } };
};

export const Root: React.FC = () => (
  <>
    <Composition id="Fenly9" component={FenlyFilm} fps={FPS} width={1920} height={1080}
      durationInFrames={2700} defaultProps={{ durations: [] } as FilmProps} calculateMetadata={calc} />
    <Composition id="Fenly9Vertical" component={FenlyFilm} fps={FPS} width={1080} height={1920}
      durationInFrames={2700} defaultProps={{ durations: [] } as FilmProps} calculateMetadata={calc} />
    {/* QHD 2560×1440 für Präsentation und Vollbild am iPhone/Mac */}
    <Composition id="Fenly9QHD" component={FenlyFilm} fps={FPS} width={2560} height={1440}
      durationInFrames={2700} defaultProps={{ durations: [] } as FilmProps} calculateMetadata={calc} />
    {/* Einzelne Szene rendern: --props='{"only":3}'  (0 = Szene 1) */}
    <Composition id="Szene" component={FenlyFilm} fps={FPS} width={1920} height={1080}
      durationInFrames={300} defaultProps={{ durations: [], only: 3 } as FilmProps} calculateMetadata={calc} />
  </>
);
