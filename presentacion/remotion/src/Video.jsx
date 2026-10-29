import React from "react";
import {
  AbsoluteFill,
  Audio,
  Img,
  Series,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";

const NAVY = "#08243f";
const CYAN = "#00c2d1";
const WHITE = "#ffffff";

const pad = (n) => String(n).padStart(2, "0");

const Scene = ({ slide }) => {
  const frame = useCurrentFrame();
  const durationInFrames = slide.durationInFrames;

  const opacity = interpolate(frame, [0, 14], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const zoom = interpolate(frame, [0, durationInFrames], [1.0, 1.018], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const progress = Math.min(1, (frame + 1) / durationInFrames);
  const captionOpacity = interpolate(
    frame,
    [0, 8, 68, 88],
    [0, 1, 1, 0],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }
  );

  return (
    <AbsoluteFill style={{ backgroundColor: WHITE }}>
      <Img
        src={staticFile(`slides/slide-${pad(slide.n)}.png`)}
        style={{
          position: "absolute",
          inset: 0,
          width: "100%",
          height: "100%",
          objectFit: "cover",
          opacity,
          transform: `scale(${zoom})`,
          transformOrigin: "center center",
        }}
      />

      {/* Número de diapositiva */}
      <div
        style={{
          position: "absolute",
          top: 32,
          right: 36,
          padding: "9px 16px",
          borderRadius: 999,
          backgroundColor: "rgba(8,36,63,0.86)",
          border: "1px solid rgba(255,255,255,0.22)",
          color: WHITE,
          fontFamily: '"Segoe UI", Arial, sans-serif',
          fontSize: 17,
          fontWeight: 600,
          letterSpacing: 1.2,
          opacity,
        }}
      >
        {pad(slide.n)} / 31
      </div>

      {/* Lower third */}
      <div
        style={{
          position: "absolute",
          left: 36,
          bottom: 34,
          maxWidth: 1320,
          display: "flex",
          alignItems: "stretch",
          borderRadius: 18,
          overflow: "hidden",
          backgroundColor: "rgba(8,36,63,0.92)",
          border: "1px solid rgba(0,194,209,0.42)",
          boxShadow: "0 18px 45px rgba(0,0,0,0.30)",
          opacity: captionOpacity,
          transform: `translateY(${interpolate(frame, [0, 18], [18, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px)`,
        }}
      >
        <div style={{ width: 6, backgroundColor: CYAN, flexShrink: 0 }} />
        <div style={{ padding: "14px 24px 15px 20px" }}>
          <div
            style={{
              color: CYAN,
              fontFamily: '"Segoe UI", Arial, sans-serif',
              fontSize: 13,
              fontWeight: 700,
              letterSpacing: 2.1,
              textTransform: "uppercase",
              marginBottom: 6,
            }}
          >
            {slide.speaker} · IS-1023
          </div>
          <div
            style={{
              color: WHITE,
              fontFamily: '"Segoe UI", Arial, sans-serif',
              fontSize: 27,
              fontWeight: 600,
              lineHeight: 1.22,
              letterSpacing: 0.1,
            }}
          >
            {slide.caption}
          </div>
        </div>
      </div>

      {/* Progreso */}
      <div
        style={{
          position: "absolute",
          left: 0,
          bottom: 0,
          height: 5,
          width: `${progress * 100}%`,
          backgroundColor: CYAN,
          boxShadow: "0 0 12px rgba(0,194,209,0.8)",
        }}
      />

      <Audio src={staticFile(slide.audio)} />
    </AbsoluteFill>
  );
};

export const PHP2ShellVideo = ({ timeline }) => {
  return (
    <Series>
      {timeline.map((slide) => (
        <Series.Sequence
          key={slide.n}
          durationInFrames={slide.durationInFrames}
        >
          <Scene slide={slide} />
        </Series.Sequence>
      ))}
    </Series>
  );
};
