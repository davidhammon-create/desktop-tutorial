
export default function BeweismatrixChart({ args, evidence }) {
  if (!args.length || !evidence.length) return null;

  const getEvForArg = (arg) => {
    const byId = (arg.evidence_ids || []).map(id => evidence.find(e => e.id
