
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { FolderOpen, Folder, Plus, X, Pencil, User, Building2, Check, ChevronRight } from "lucide-react";

const FOLDER_COLORS = [
  "#0A84FF", "#1DB954", "#FF9500", "#FF3B30",
  "#5856D6", "#FF2D55", "#AF52DE", "#636366",
];

const SF = { fontFamily: "-apple-system,'SF Pro Text','Helvetica Neue',Arial,sans-serif" };
const C = {
  separator: "rgba(0,0,0,0.08)",
  label: "#1C1C1E",
  label2: "#636366",
  label3: "#AEAEB2",
  card: "#FFFFFF",
  shadowSm: "0 1px 4px rgba(0,0,0,0.07)",
};

function FolderModal({ folder, onSave, onClose }) {
  const [form, setForm] = useState({
    name: folder?.name || "",
    color: folder?.color || "#0A84FF",
    mandant_name: folder?.mandant_name || "",
    mandant_email: folder?.mandant_email || "",
    mandant_typ: folder?.mandant_typ || "Privatperson",
    description: folder?.description || "",
  });
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!form.name.trim()) return;
    setSaving(true);
    if (folder?.id) {
      await base44.entities.CaseFolder.update(folder.id, form);
    } else {
      await base44.entities.CaseFolder.create(form);
    }
    setSaving(false);
    onSave();
  };

  return (
    <div style={{
      position: "fixed", inset: 0, zIndex: 60,
      display: "flex", alignItems: "center", justifyContent: "center",
      background: "rgba(0,0,0,0.40)", backdropFilter: "blur(10px)",
    }} onClick={e => e.target
