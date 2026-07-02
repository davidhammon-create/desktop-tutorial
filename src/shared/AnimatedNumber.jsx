import React, { useEffect, useState } from "react";
import { useReveal } from "./Reveal";

// Counts up from 0 to `value` once it scrolls into view.
export function AnimatedNumber({ value, format, duration = 1400 }) {
  const [ref, vis] = useReveal();
  const [display, setDisplay] = useState(0);

  useEffect(() => {
    if (!vis) return;
    let raf;
    const start = performance.now();
    const tick = (now) => {
      const t = Math.min(1, (now - start) / duration);
      const eased = 1 - Math.pow(1 - t, 3);
      setDisplay(value * eased);
      if (t < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [vis, value, duration]);

  return <span ref={ref}>{format ? format(display) : Math.round(display)}</span>;
}
