import React from "react";
import { Composition } from "remotion";
import { FenlyFilm } from "./Video";
import { FPS, TOTAL_FRAMES } from "./config";

export const Root: React.FC = () => (
  <>
    {/* Querformat: YouTube, Website, Messe, Pitch */}
    <Composition id="Fenly9" component={FenlyFilm} durationInFrames={TOTAL_FRAMES}
      fps={FPS} width={1920} height={1080} />
    {/* Hochkant: Instagram Reels, TikTok, LinkedIn Mobile */}
    <Composition id="Fenly9Vertical" component={FenlyFilm} durationInFrames={TOTAL_FRAMES}
      fps={FPS} width={1080} height={1920} />
  </>
);
