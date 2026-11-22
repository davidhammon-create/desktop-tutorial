import { describe, it, expect } from "vitest";
import { renderHook, act } from "@testing-library/react";
import { useGraphState } from "@/hooks/useGraphState";
describe("useGraphState - drag-to-connect (addEdge)", () => {
  it("should add an edge between two nodes", () => {
    const { result } = renderHook(() => useGraphState());
    // Initial state has 5 edges
    expect(result.current.state.edges.length).toBe(5);
    // Add a new edge from node 2 (Delivery Records) to node 5 (Pre-existing Conditions)
    act(() => {
      result.current.addEdge("2", "5", "support", "Corroborates timeline");
    });
    expect(result.current.state.edges.length).toBe(6);
    const newEdge = result.current.state.edges[5];
    expect(newEdge.source).toBe("2");
    expect(newEdge.target).toBe("5");
    expect(newEdge.relation).toBe("support");
    expect(newEdge.label).toBe("Corroborates timeline");
  });
  it("should add edge with no label", () => {
    const { result } = renderHook(() => useGraphState());
    act(() => {
      result.current.addEdge("3", "6", "attack");
    });
    const newEdge = result.current.state.edges.find(
      (e) => e.source === "3" && e.target === "6"
    );
    expect(newEdge).toBeDefined();
    expect(newEdge!.relation).toBe("attack");
    expect(newEdge!.label).toBeUndefined();
  });
  it("should delete an edge", () => {
    const { result } = renderHook(() => useGraphState());
    const initialCount = result.current.state.edges.length;
    act(() => {
      result.current.deleteEdge("e1");
    });
    expect(result.current.state.edges.length).toBe(initialCount - 1);
    expect(result.current.state.edges.find((e) => e.id === "e1")).toBeUndefined();
  });
  it("should update a node", () => {
    const { result } = renderHook(() => useGraphState());
    act(() => {
      result.current.updateNode("1", { title: "Updated Title", strength: 2 });
    });
    const updated = result.current.state.nodes.find((n) => n.id === "1");
    expect(updated?.title).toBe("Updated Title");
    expect(updated?.strength).toBe(2);
  });
  it("should delete a node and its connected edges", () => {
    const { result } = renderHook(() => useGraphState());
    // Node 1 has edges e1, e2, e3 connected to it
    act(() => {
      result.current.deleteNode("1");
    });
    expect(result.current.state.nodes.find((n) => n.id === "1")).toBeUndefined();
    // Edges that referenced node 1 should be removed
    expect(result.current.state.edges.find((e) => e.source === "1" || e.target === "1")).toBeUndefined();
  });
});
