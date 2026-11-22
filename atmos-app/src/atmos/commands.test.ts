import { describe, expect, it } from "vitest";
import { approveFreigabe, executeCommand } from "./commands";
import { createInitialState } from "./store";
describe("AtmOS commands", () => {
  it("sets effort / router stufe", () => {
    const { state, result } = executeCommand(createInitialState(), "/effort 5");
    expect(result.ok).toBe(true);
    expect(state.effort).toBe(5);
  });
  it("stop and fortsetzen", () => {
    let { state, result } = executeCommand(createInitialState(), "/stop");
    expect(state.stop).toBe(true);
    expect(result.ok).toBe(true);
    ({ state, result } = executeCommand(state, "/mach test"));
    expect(result.ok).toBe(false);
    ({ state, result } = executeCommand(state, "/fortsetzen"));
    expect(state.stop).toBe(false);
    expect(result.ok).toBe(true);
  });
  it("github search and install freigabe", () => {
    let { state, result } = executeCommand(createInitialState(), "/suche pdf");
    expect(result.ok).toBe(true);
    expect(result.message).toContain("pdfplumber");
    ({ state, result } = executeCommand(state, "/install jsvine/pdfplumber"));
    expect(result.needsFreigabe).toBeTruthy();
    ({ state, result } = approveFreigabe(state, result.needsFreigabe!.id));
    expect(state.module.some((m) => m.name === "jsvine/pdfplumber" && m.status === "aus")).toBe(true);
  });
  it("mach starts a lauf with freigabe halt", () => {
    const { state, result } = executeCommand(createInitialState(), "/mach Website bauen");
    expect(result.ok).toBe(true);
    expect(state.laeufe.length).toBeGreaterThan(0);
    expect(state.laeufe[0].stand).toBe("halt");
  });
});
