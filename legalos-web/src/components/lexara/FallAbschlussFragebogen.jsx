
import { useState } from "react";
import { base44 } from "@/api/base44Client";
import { X, ChevronDown, ChevronUp, CheckCircle2, Star } from "lucide-react";

const JaNein = ({ label, value, onChange }) => (
  <div className="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
    <span className="text-sm text-gray-700">{label}</span>
    <div className="flex gap-2">
      <button
        onClick={() => onChange(true)}
        className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
          value
