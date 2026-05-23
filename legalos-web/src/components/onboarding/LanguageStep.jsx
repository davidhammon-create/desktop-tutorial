
import { Languages, ArrowLeft } from "lucide-react";

const LANGUAGES = [
  { code: "DE", label: "Deutsch", flag: "🇩🇪", sub: "German", notice: null },
  { code: "EN", label: "English", flag: "🇬🇧", sub: "English", notice: "🚧 Platform is currently displayed mostly in German. Full English translation is in progress." },
  { code: "FR", label: "Français", flag: "🇫🇷", sub: "French", notice: "🚧 La plateforme s'affiche actuellement principalement en allemand. La traduction complète est en cours." },
];

const TITLES = {
  DE: "Sprache wählen",
  EN: "Select Language",
  FR: "Choisir la langue",
};

export default function LanguageStep({ language, onSelect, onBack }) {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-7">
      <div className="flex items-center gap-3 mb-6">
        <div className="w-9 h-9 bg-violet-50 rounded-xl flex items-center justify-center">
          <Languages className="w-5 h-5 text-violet-600" />
        </div>
        <h2 className="text-base font-bold text-slate-900">{TITLES[language] || TITLES.DE}</h2>
      </div>

      <div className="space-y-2 mb-5">
        {LANGUAGES.map(lang => (
          <button key={lang.code} onClick={() => onSelect(lang.code)}
            className={`w-full flex items-center gap-4 p-4 rounded-xl border text-left transition-all ${
              language
