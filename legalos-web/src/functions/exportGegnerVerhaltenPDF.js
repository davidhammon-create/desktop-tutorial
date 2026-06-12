export async function exportGegnerVerhaltenPDF({ caseId } = {}) {
  await new Promise(r => setTimeout(r, 800));
  const blob = new Blob([`LegalOS – Gegner-Verhalten Export\nFall: ${caseId}\n\n[Demo-Modus]`], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = `Gegnerverhalten_${caseId}.pdf`; a.click();
  URL.revokeObjectURL(url);
  return { success: true };
}
