import { ArgumentNode, ArgumentEdge } from '@/types/argument';
import { NODE_WIDTH, NODE_HEIGHT } from '@/components/graph/GraphNode';
const H_GAP = 80;
const V_GAP = 100;
interface TreeNode {
  id: string;
  children: TreeNode[];
  width: number;
  x: number;
  y: number;
}
/**
 * Computes a hierarchical top-down tree layout.
 * Roots = nodes that are only targets (claims typically) or nodes with no incoming edges.
 * Children = sources that point to a parent (support/attack ? parent).
 */
export function computeAutoLayout(
  nodes: ArgumentNode[],
  edges: ArgumentEdge[]
): { id: string; x: number; y: number }[] {
  if (nodes.length === 0) return [];
  // Build adjacency: edge source ? target means source supports/attacks target
  // So target is the "parent" and source is the "child" in visual hierarchy
  const childrenMap = new Map<string, string[]>();
  const hasParent = new Set<string>();
  for (const edge of edges) {
    // target is parent, source is child
    const parent = edge.target;
    const child = edge.source;
    if (!childrenMap.has(parent)) childrenMap.set(parent, []);
    childrenMap.get(parent)!.push(child);
    hasParent.add(child);
  }
  // Find roots: nodes that are not children of any other node
  const rootIds = nodes.filter(n => !hasParent.has(n.id)).map(n => n.id);
  // If no roots found (circular), just use all nodes
  if (rootIds.length === 0) {
    rootIds.push(nodes[0].id);
  }
  // Track visited to handle cycles
  const visited = new Set<string>();
  function buildTree(id: string): TreeNode {
    visited.add(id);
    const children = (childrenMap.get(id) || [])
      .filter(cid => !visited.has(cid))
      .map(cid => buildTree(cid));
    return { id, children, width: 0, x: 0, y: 0 };
  }
  const trees = rootIds.map(id => buildTree(id));
  // Add orphan nodes (not connected at all)
  const placedIds = new Set(visited);
  const orphans = nodes.filter(n => !placedIds.has(n.id));
  // Calculate subtree widths
  function calcWidth(tree: TreeNode): number {
    if (tree.children.length === 0) {
      tree.width = NODE_WIDTH;
      return tree.width;
    }
    tree.width = tree.children.reduce((sum, c) => sum + calcWidth(c), 0) +
      (tree.children.length - 1) * H_GAP;
    tree.width = Math.max(tree.width, NODE_WIDTH);
    return tree.width;
  }
  function assignPositions(tree: TreeNode, x: number, y: number) {
    tree.x = x + tree.width / 2 - NODE_WIDTH / 2;
    tree.y = y;
    let childX = x;
    for (const child of tree.children) {
      assignPositions(child, childX, y + NODE_HEIGHT + V_GAP);
      childX += child.width + H_GAP;
    }
  }
  // Layout each tree side by side
  let totalX = 100;
  for (const tree of trees) {
    calcWidth(tree);
    assignPositions(tree, totalX, 100);
    totalX += tree.width + H_GAP * 2;
  }
  // Place orphans in a row at the bottom
  const maxY = Math.max(...flatten(trees).map(t => t.y), 100);
  let orphanX = 100;
  const orphanResults: { id: string; x: number; y: number }[] = orphans.map(n => {
    const result = { id: n.id, x: orphanX, y: maxY + NODE_HEIGHT + V_GAP };
    orphanX += NODE_WIDTH + H_GAP;
    return result;
  });
  return [...flatten(trees).map(t => ({ id: t.id, x: t.x, y: t.y })), ...orphanResults];
}
function flatten(trees: TreeNode[]): TreeNode[] {
  const result: TreeNode[] = [];
  function walk(t: TreeNode) {
    result.push(t);
    t.children.forEach(walk);
  }
  trees.forEach(walk);
  return result;
}
