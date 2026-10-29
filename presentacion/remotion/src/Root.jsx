import React from "react";
import { Composition } from "remotion";
import timeline from "./timeline.json";
import { PHP2ShellVideo } from "./Video.jsx";

const totalFrames = timeline.reduce((sum, item) => sum + item.durationInFrames, 0);

export const RemotionRoot = () => {
  return (
    <Composition
      id="PHP2ShellVideo"
      component={PHP2ShellVideo}
      durationInFrames={totalFrames}
      fps={15}
      width={1920}
      height={1080}
      defaultProps={{ timeline }}
    />
  );
};
