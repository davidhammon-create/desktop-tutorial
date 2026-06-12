
import { useState, useEffect, useMemo } from "react";
import { base44 } from "@/api/base44Client";
import { Network, Clock, Zap, Filter, X } from "lucide-react";

const GraphView = ({ args, evidence, deadlines, persons }) => {
  const [selected, setSelected] = useState(null);
  const [view, setView] = useState("network"); // network, timeline, sankey
  const [filterType, setFilterType] = useState("all");

  const nodes = useMemo(() => {
    const items = [];
    args.forEach((a) =>
      items.push({
        id: a.id,
        label: a.title,
        type: "argument",
        strength: a.ki_strength || a.strength || 5,
        color: a.side === "eigen" ? "#3b82f6" : "#ef4444",
      })
    );
    evidence.forEach((e) =>
      items.push({
        id: e.id,
        label: e.title,
        type: "evidence",
        strength: e.ki_weight || e.weight || 5,
        color: "#10b981",
      })
    );
    deadlines.forEach((d) =>
      items.push({
        id: d.id,
        label: d.title,
        type: "deadline",
        strength: 7,
        color: "#f59e0b",
        date: d.due_date,
      })
    );
    persons.forEach((p) =>
      items.push({
        id: p.id,
        label: p.name,
        type: "person",
        strength: p.glaubwuerdigkeit || 5,
        color: "#a855f7",
      })
    );
    return items;
  }, [args, evidence, deadlines, persons]);

  const edges = useMemo(() => {
    const links = [];
    args.forEach((a) => {
      if (a.evidence_ids && a.evidence_ids.length > 0) {
        a.evidence_ids.forEach((eid) => {
          links.push({
            source: eid,
            target: a.id,
            weight: a.ki_strength || a.strength || 5,
            type: "supports",
          });
        });
      }
    });
    return links;
  }, [args]);

  const filteredNodes =
    filterType === "all"
      ? nodes
      : nodes.filter((n) => n.type
