import { jsPDF } from 'jspdf';
import { LexaraCase } from '@/types/lexara';
export function generateCaseReportPdf(c: LexaraCase) {
  const pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const W = 210;
  const M = 20;
  const CW = W - 2 * M;
  let y = M;
  const addHeader = () => {
    pdf.setFillColor(29, 29, 31);
    pdf.rect(0, 0, W, 18, 'F');
    pdf.setTextColor(255, 255, 255);
    pdf.setFontSize(11);
    pdf.setFont('helvetica', 'bold');
    pdf.text('MachiavelLEX ? Fallbericht', M, 12);
    pdf.setFontSize(8);
    pdf.setFont('helvetica', 'normal');
    pdf.text(new Date().toLocaleDateString('de-DE'), W - M, 12, { align: 'right' });
    y = 28;
  };
  const checkPage = (needed: number) => {
    if (y + needed > 280) {
      pdf.addPage();
      addHeader();
    }
  };
  const sectionTitle = (title: string) => {
    checkPage(14);
    pdf.setFontSize(14);
    pdf.setFont('helvetica', 'bold');
    pdf.setTextColor(29, 29, 31);
    pdf.text(title, M, y);
    y += 2;
    pdf.setDrawColor(0, 122, 255);
    pdf.setLineWidth(0.5);
    pdf.line(M, y, M + CW, y);
    y += 8;
  };
  const kv = (label: string, value: string) => {
    checkPage(8);
    pdf.setFontSize(9);
    pdf.setFont('helvetica', 'bold');
    pdf.setTextColor(134, 134, 139);
    pdf.text(label, M, y);
    pdf.setFont('helvetica', 'normal');
    pdf.setTextColor(29, 29, 31);
    pdf.text(value || '?', M + 40, y);
    y += 6;
  };
  const bodyText = (text: string) => {
    checkPage(10);
    pdf.setFontSize(10);
    pdf.setFont('helvetica', 'normal');
    pdf.setTextColor(60, 60, 67);
    const lines = pdf.splitTextToSize(text, CW);
    pdf.text(lines, M, y);
    y += lines.length * 5 + 4;
  };
  // === HEADER ===
  addHeader();
  // === CASE INFO ===
  pdf.setFontSize(22);
  pdf.setFont('helvetica', 'bold');
  pdf.setTextColor(29, 29, 31);
  pdf.text(c.name, M, y);
  y += 10;
  kv('Aktenzeichen', c.number);
  kv('Gericht', c.court);
  kv('Typ', c.type);
  kv('Status', c.status);
  kv('Ziel', c.goal);
  kv('Erstellt', c.created);
  y += 6;
  // === PROGNOSE ===
  sectionTitle('Prognose');
  const ownArgs = c.arguments.filter(a => a.side === 'own');
  const oppArgs = c.arguments.filter(a => a.side === 'opp');
  const avgOwn = ownArgs.length ? ownArgs.reduce((s, a) => s + a.strength, 0) / ownArgs.length : 0;
  const avgOpp = oppArgs.length ? oppArgs.reduce((s, a) => s + a.strength, 0) / oppArgs.length : 0;
  const winProb = ownArgs.length + oppArgs.length > 0 ? Math.round((avgOwn / (avgOwn + avgOpp || 1)) * 100) : 50;
  kv('Eigene Argumente', `${ownArgs.length} (? Stärke: ${avgOwn.toFixed(1)})`);
  kv('Gegner-Argumente', `${oppArgs.length} (? Stärke: ${avgOpp.toFixed(1)})`);
  kv('Erfolgswahrsch.', `${winProb}%`);
  // Win probability bar
  checkPage(10);
  pdf.setFillColor(228, 228, 237);
  pdf.roundedRect(M, y, CW, 6, 3, 3, 'F');
  pdf.setFillColor(0, 122, 255);
  pdf.roundedRect(M, y, CW * winProb / 100, 6, 3, 3, 'F');
  y += 14;
  // === ARGUMENTE ===
  sectionTitle('Argumente ? Eigene Seite');
  if (ownArgs.length === 0) {
    bodyText('Keine eigenen Argumente vorhanden.');
  } else {
    ownArgs.forEach((a, i) => {
      checkPage(16);
      pdf.setFontSize(11);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(0, 122, 255);
      pdf.text(`${i + 1}. ${a.label}`, M, y);
      pdf.setFontSize(9);
      pdf.setTextColor(134, 134, 139);
      pdf.text(`Stärke: ${a.strength}/10`, W - M, y, { align: 'right' });
      y += 6;
      if (a.description) bodyText(a.description);
      y += 2;
    });
  }
  sectionTitle('Argumente ? Gegnerseite');
  if (oppArgs.length === 0) {
    bodyText('Keine Gegner-Argumente vorhanden.');
  } else {
    oppArgs.forEach((a, i) => {
      checkPage(16);
      pdf.setFontSize(11);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(255, 59, 48);
      pdf.text(`${i + 1}. ${a.label}`, M, y);
      pdf.setFontSize(9);
      pdf.setTextColor(134, 134, 139);
      pdf.text(`Stärke: ${a.strength}/10`, W - M, y, { align: 'right' });
      y += 6;
      if (a.description) bodyText(a.description);
      y += 2;
    });
  }
  // === BEWEISE ===
  sectionTitle('Beweise');
  const allEvidence = Object.entries(c.evidence || {}).flatMap(([argId, evList]) =>
    evList.map(ev => ({ ...ev, argId }))
  );
  if (allEvidence.length === 0) {
    bodyText('Keine Beweismittel vorhanden.');
  } else {
    allEvidence.forEach((ev, i) => {
      checkPage(14);
      const arg = c.arguments.find(a => a.id === ev.argId);
      pdf.setFontSize(10);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(29, 29, 31);
      pdf.text(`${i + 1}. ${ev.name}`, M, y);
      y += 5;
      pdf.setFontSize(9);
      pdf.setFont('helvetica', 'normal');
      pdf.setTextColor(134, 134, 139);
      pdf.text(`Typ: ${ev.type || '?'}  |  Validität: ${ev.validity ?? '?'}%  |  Argument: ${arg?.label || ev.argId}`, M + 4, y);
      y += 5;
      if (ev.desc) {
        pdf.setTextColor(60, 60, 67);
        const lines = pdf.splitTextToSize(ev.desc, CW - 4);
        pdf.text(lines, M + 4, y);
        y += lines.length * 4.5 + 2;
      }
      y += 3;
    });
  }
  // === PERSONEN ===
  if (c.persons && c.persons.length > 0) {
    sectionTitle('Beteiligte Personen');
    c.persons.forEach((p, i) => {
      checkPage(10);
      pdf.setFontSize(10);
      pdf.setFont('helvetica', 'bold');
      pdf.setTextColor(29, 29, 31);
      pdf.text(`${i + 1}. ${p.name}`, M, y);
      pdf.setFont('helvetica', 'normal');
      pdf.setTextColor(134, 134, 139);
      pdf.text(`Rolle: ${p.role}${p.party ? ` | Partei: ${p.party}` : ''}`, M + 50, y);
      y += 7;
    });
  }
  // === FOOTER ===
  const pageCount = pdf.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    pdf.setPage(i);
    pdf.setFontSize(8);
    pdf.setTextColor(134, 134, 139);
    pdf.text(`Seite ${i} von ${pageCount}`, W / 2, 292, { align: 'center' });
    pdf.text('Vertraulich ? MachiavelLEX', M, 292);
  }
  pdf.save(`Fallbericht_${c.name.replace(/\s+/g, '_')}_${Date.now()}.pdf`);
}
