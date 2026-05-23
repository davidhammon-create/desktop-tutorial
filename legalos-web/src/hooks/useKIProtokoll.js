import { useState, useCallback } from "react";

export function useKIProtokoll(caseId) {
  const [protokoll, setProtokoll] = useState([]);
  const addEntry = useCallback((entry) => {
    setProtokoll(p => [{ id: Date.now(), timestamp: new Date().toISOString(), ...entry }, ...p]);
  }, []);
  return { protokoll, addEntry, isLoading: false };
}
