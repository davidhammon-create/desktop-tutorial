export async function sendMandantUpdate({ caseId, recipientEmail, message } = {}) {
  await new Promise(r => setTimeout(r, 600));
  console.log('[MOCK] sendMandantUpdate', { caseId, recipientEmail });
  return { success: true, message: 'E-Mail-Update simuliert (Demo-Modus).' };
}
