import { h } from "./dom.js";

// Ambient background gradients — plain absolutely-positioned divs animated
// purely by the CSS keyframes in animations.css.
export function orbs() {
  const frag = document.createDocumentFragment();
  frag.appendChild(
    h("div", {
      class: "orb",
      style: {
        position: "fixed", top: "-10%", right: "-5%", width: "600px", height: "600px",
        borderRadius: "50%", background: "radial-gradient(circle, rgba(48,209,88,0.14), transparent 65%)",
        filter: "blur(60px)", animation: "float1 14s ease-in-out infinite", pointerEvents: "none", zIndex: "0",
      },
    })
  );
  frag.appendChild(
    h("div", {
      class: "orb",
      style: {
        position: "fixed", bottom: "-15%", left: "-10%", width: "700px", height: "700px",
        borderRadius: "50%", background: "radial-gradient(circle, rgba(100,210,255,0.10), transparent 65%)",
        filter: "blur(70px)", animation: "float2 18s ease-in-out infinite", pointerEvents: "none", zIndex: "0",
      },
    })
  );
  return frag;
}
