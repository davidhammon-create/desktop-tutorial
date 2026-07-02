import React, { useState, useEffect, useRef } from "react";

export function useReveal() {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([e]) => e.isIntersecting && setVisible(true),
      { threshold: 0.15 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, []);
  return [ref, visible];
}

export const Reveal = ({ children, delay = 0, style = {} }) => {
  const [ref, vis] = useReveal();
  return (
    <div
      ref={ref}
      style={{
        opacity: vis ? 1 : 0,
        transform: vis ? "translateY(0)" : "translateY(40px)",
        transition: `opacity 0.8s ease ${delay}s, transform 0.8s cubic-bezier(0.16,1,0.3,1) ${delay}s`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

export const Orbs = () => (
  <>
    <style>{`
      @keyframes float1 { 0%,100%{transform:translate(0,0) scale(1)} 50%{transform:translate(60px,-40px) scale(1.15)} }
      @keyframes float2 { 0%,100%{transform:translate(0,0) scale(1)} 50%{transform:translate(-50px,50px) scale(0.9)} }
      @media (prefers-reduced-motion: reduce) { .orb { animation: none !important; } }
    `}</style>
    <div className="orb" style={{ position: "fixed", top: "-10%", right: "-5%", width: 600, height: 600, borderRadius: "50%", background: "radial-gradient(circle, rgba(48,209,88,0.14), transparent 65%)", filter: "blur(60px)", animation: "float1 14s ease-in-out infinite", pointerEvents: "none", zIndex: 0 }} />
    <div className="orb" style={{ position: "fixed", bottom: "-15%", left: "-10%", width: 700, height: 700, borderRadius: "50%", background: "radial-gradient(circle, rgba(100,210,255,0.10), transparent 65%)", filter: "blur(70px)", animation: "float2 18s ease-in-out infinite", pointerEvents: "none", zIndex: 0 }} />
  </>
);
