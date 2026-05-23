export async function exportIcal({ deadlines = [] } = {}) {
  await new Promise(r => setTimeout(r, 500));
  const lines = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//LegalOS//Demo//DE'];
  for (const d of deadlines) {
    lines.push('BEGIN:VEVENT', `SUMMARY:${d.bezeichnung || 'Frist'}`, `DTSTART:${(d.datum||new Date().toISOString()).replace(/[-:]/g,'').slice(0,15)}Z`, 'END:VEVENT');
  }
  lines.push('END:VCALENDAR');
  const blob = new Blob([lines.join('\r\n')], { type: 'text/calendar' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = 'LegalOS_Fristen.ics'; a.click();
  URL.revokeObjectURL(url);
  return { success: true };
}
