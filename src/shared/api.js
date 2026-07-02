const BASE = "/api";

async function req(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: options.body && !(options.body instanceof FormData) ? { "Content-Type": "application/json" } : undefined,
    ...options,
  });
  if (res.status === 204) return null;
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || `Anfrage fehlgeschlagen (${res.status})`);
  return data;
}

export const api = {
  subscriptions: {
    list: () => req("/subscriptions"),
    create: (body) => req("/subscriptions", { method: "POST", body: JSON.stringify(body) }),
    update: (id, body) => req(`/subscriptions/${id}`, { method: "PATCH", body: JSON.stringify(body) }),
    remove: (id) => req(`/subscriptions/${id}`, { method: "DELETE" }),
    password: (id) => req(`/subscriptions/${id}/password`),
  },
  accounts: {
    list: () => req("/accounts"),
    connect: (id) => req(`/accounts/${id}/connect`, { method: "POST" }),
    disconnect: (id) => req(`/accounts/${id}/disconnect`, { method: "POST" }),
  },
  etfs: {
    list: (q) => req(`/etfs${q ? `?q=${encodeURIComponent(q)}` : ""}`),
  },
  user: {
    get: () => req("/user"),
    save: (body) => req("/user", { method: "PUT", body: JSON.stringify(body) }),
  },
  ai: {
    analyzeStatement: (text, file) => {
      const form = new FormData();
      if (text) form.append("text", text);
      if (file) form.append("file", file);
      return req("/ai/analyze-statement", { method: "POST", body: form });
    },
    companyReport: (subscriptionId) => req("/ai/company-report", { method: "POST", body: JSON.stringify({ subscriptionId }) }),
    cancellationLetter: (subscriptionId) => req("/ai/cancellation-letter", { method: "POST", body: JSON.stringify({ subscriptionId }) }),
    autoClassify: () => req("/ai/auto-classify", { method: "POST", body: JSON.stringify({}) }),
  },
};
