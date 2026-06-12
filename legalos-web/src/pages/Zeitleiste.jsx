
import { useState, useEffect } from "react";
import { base44 } from "@/api/base44Client";
import { Calendar, AlertTriangle, Clock, Check, Download } from "lucide-react";
import { getTByLanguage } from "../lib/jurisdictionConfig";
import { useUserProfile } from "../hooks/useUserProfile";
import { exportIcal } from "@/functions/exportIcal";

function getStatusColor(deadline) {
  if (deadline.status === "erledigt") return "bg-green-100 text-green-700 border-green-200";
  if (deadline.status === "versaeumt") return "bg-red-100 text-red-700 border-red-200";
  const days = Math.ceil((new Date(deadline.due_date) - new Date()) / 86400000);
  if (days < 0) return "bg-red-100 text-red-700 border-red-200";
  if (days <= 7) return "bg-orange-100 text-orange-700 border-orange-200";
  if (days <= 30) return "bg-yellow-100 text-yellow-700 border-yellow-200";
  return "bg-[#fafafa] text-[#666] border-[#f0f0f0]";
}

function getDaysLabel(due_date, status, t) {
  if (status === "erledigt") return t.doneStatus;
  if (status === "versaeumt") return t.missedStatus;
  const days = Math.ceil((new Date(due_date) - new Date()) / 86400000);
  if (days < 0) return t.daysOverdueLabel(Math.abs(days));
  if (days
