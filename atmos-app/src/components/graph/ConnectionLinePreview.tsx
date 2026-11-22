import React from 'react';
interface ConnectionLinePreviewProps {
  startX: number;
  startY: number;
  endX: number;
  endY: number;
}
export const ConnectionLinePreview: React.FC<ConnectionLinePreviewProps> = ({
  startX, startY, endX, endY,
}) => {
  const dx = endX - startX;
  const dy = endY - startY;
  const dist = Math.sqrt(dx * dx + dy * dy);
  const curvature = Math.min(dist * 0.3, 80);
  const midX = startX + dx / 2;
  const midY = startY + dy / 2;
  const nx = dist > 0 ? -dy / dist * curvature * 0.15 : 0;
  const ny = dist > 0 ? dx / dist * curvature * 0.15 : 0;
  const path = `M ${startX} ${startY} Q ${midX + nx} ${midY + ny} ${endX} ${endY}`;
  return (
    <g>
      <path
        d={path}
        fill="none"
        stroke="hsl(211, 100%, 50%)"
        strokeWidth={2}
        strokeDasharray="6,4"
        opacity={0.6}
        strokeLinecap="round"
      />
      <circle
        cx={endX}
        cy={endY}
        r={6}
        fill="hsl(211, 100%, 50%)"
        opacity={0.4}
      />
    </g>
  );
};
