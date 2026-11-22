import { AtmosProvider } from "@/atmos/provider";
import { CommandOverlay } from "./CommandOverlay";
import { FreigabeDialog } from "./FreigabeDialog";
/**
 * AtmOS main chrome = App Store?style Entdecken shell only.
 * Copper hero / aurora / grid removed ? first paint is the store overlay.
 */
function ShellInner() {
  return (
    <div className="atmos-app">
      <CommandOverlay />
      <FreigabeDialog />
    </div>
  );
}
export function AtmosShell() {
  return (
    <AtmosProvider>
      <ShellInner />
    </AtmosProvider>
  );
}
