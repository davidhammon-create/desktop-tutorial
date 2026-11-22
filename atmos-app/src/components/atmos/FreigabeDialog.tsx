import { useAtmos } from "@/atmos/provider";
export function FreigabeDialog() {
  const { pendingFreigabe, approve, reject } = useAtmos();
  if (!pendingFreigabe) return null;
  return (
    <div className="atmos-freigabe" role="dialog" aria-labelledby="freigabe-title">
      <div className="atmos-freigabe__panel">
        <p className="atmos-kicker">Mensch hält den Schlüssel</p>
        <h2 id="freigabe-title">{pendingFreigabe.titel}</h2>
        <p>{pendingFreigabe.beschreibung}</p>
        <div className="atmos-freigabe__actions">
          <button type="button" className="atmos-btn atmos-btn--ghost" onClick={() => reject(pendingFreigabe.id)}>
            Ablehnen
          </button>
          <button type="button" className="atmos-btn atmos-btn--primary" onClick={() => approve(pendingFreigabe.id)}>
            Freigeben
          </button>
        </div>
      </div>
    </div>
  );
}
