import { COMMANDS } from "@/atmos/commands";
import { useAtmos } from "@/atmos/provider";
import { useEffect, useMemo, useRef, useState } from "react";
export function CommandBar({ autofocus = false }: { autofocus?: boolean }) {
  const { run, state } = useAtmos();
  const [value, setValue] = useState("");
  const [open, setOpen] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        inputRef.current?.focus();
        setOpen(true);
      }
      if (e.key === "/" && document.activeElement?.tagName !== "INPUT" && document.activeElement?.tagName !== "TEXTAREA") {
        e.preventDefault();
        setValue("/");
        inputRef.current?.focus();
        setOpen(true);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  useEffect(() => {
    if (autofocus) inputRef.current?.focus();
  }, [autofocus]);
  const suggestions = useMemo(() => {
    const q = value.startsWith("/") ? value.slice(1).toLowerCase() : value.toLowerCase();
    if (!value.startsWith("/") && value.length > 0) return [];
    return COMMANDS.filter(
      (c) => !q || c.id.includes(q) || c.aliases.some((a) => a.includes(q)) || c.beschreibung.toLowerCase().includes(q),
    ).slice(0, 8);
  }, [value]);
  const submit = (raw?: string) => {
    const input = (raw ?? value).trim();
    if (!input) return;
    run(input);
    setValue("");
    setOpen(false);
  };
  return (
    <div className="atmos-command">
      <div className="atmos-command__row">
        <span className="atmos-command__prompt" aria-hidden>
          ?
        </span>
        <input
          ref={inputRef}
          className="atmos-command__input"
          value={value}
          disabled={state.stop && !value.startsWith("/fortsetzen") && !value.startsWith("/vital") && !value.startsWith("/hilfe")}
          placeholder="Was willst du lösen?  /effort  /suche  /mach  ? ?K"
          onChange={(e) => {
            setValue(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 150)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              submit();
            }
            if (e.key === "Escape") setOpen(false);
          }}
          aria-label="AtmOS Befehl"
        />
        <button type="button" className="atmos-command__go" onClick={() => submit()}>
          Lösen
        </button>
      </div>
      {open && suggestions.length > 0 && (
        <ul className="atmos-command__menu" role="listbox">
          {suggestions.map((c) => (
            <li key={c.id}>
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => {
                  setValue(`${c.label} `);
                  inputRef.current?.focus();
                }}
              >
                <span className="atmos-command__cmd">{c.label}</span>
                <span className="atmos-muted">{c.beschreibung}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
