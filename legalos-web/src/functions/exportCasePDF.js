export async function exportCasePDF({ caseId, caseData } = {}) {
  await new Promise(r => setTimeout(r, 800));
  const blob = new Blob([`LegalOS PDF Export - Fall: ${caseData?.fallname || caseId}\n\n[Demo-Modus: PDF-Inhalt würde hier erscheinen]`], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = `Fall_${caseId}_Export.pdf`; a.click();
  URL.revokeObjectURL(url);
  return { success: true };
}
