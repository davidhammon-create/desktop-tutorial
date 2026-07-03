const BASE = "/api";

// Device-local profile selection: the chosen profile id travels as a header.
export function getCurrentUserId() {
  return Number(localStorage.getItem("abw_user") || 0) || null;
}
export function setCurrentUserId(id) {
  if (id) localStorage.setItem("abw_user", String(id));
  else localStorage.removeItem("abw_user");
}

async function req(path, options = {}) {
  const userId = getCurrentUserId();
  const res = await fetch(`${BASE}${path}`, {
    ...options,
    headers: {
      ...(options.body && !(options.body instanceof FormData) ? { "Content-Type": "application/json" } : {}),
      ...(userId ? { "x-user-id": String(userId) } : {}),
      ...(options.headers || {}),
    },
  });
  if (res.status === 204) return null;
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || `Anfrage fehlgeschlagen (${res.status})`);
  return data;
}

export const api = {
  users: {
    list: () => req("/users"),
    create: (name) => req("/users", { method: "POST", body: JSON.stringify({ name }) }),
  },
  subscriptions: {
    list: () => req("/subscriptions"),
    create: (body) => req("/subscriptions", { method: "POST", body: JSON.stringify(body) }),
    update: (id, body) => req(`/subscriptions/${id}`, { method: "PATCH", body: JSON.stringify(body) }),
    remove: (id) => req(`/subscriptions/${id}`, { method: "DELETE" }),
    password: (id) => req(`/subscriptions/${id}/password`),
  },
  accounts: {
    list: () => req("/accounts"),
    providers: () => req("/accounts/providers"),
    connect: (body) => req("/accounts/connect", { method: "POST", body: JSON.stringify(body) }),
    disconnect: (id) => req(`/accounts/${id}/disconnect`, { method: "POST" }),
    remove: (id) => req(`/accounts/${id}`, { method: "DELETE" }),
    transactions: (accountId) => req(`/accounts/transactions${accountId ? `?accountId=${encodeURIComponent(accountId)}` : ""}`),
    import: (id, text) => req(`/accounts/${id}/import`, { method: "POST", body: JSON.stringify({ text }) }),
  },
  scan: {
    run: () => req("/scan", { method: "POST", body: JSON.stringify({}) }),
  },
  etfs: {
    list: (q) => req(`/etfs${q ? `?q=${encodeURIComponent(q)}` : ""}`),
  },
  invest: {
    list: ({ q, cls } = {}) => {
      const params = new URLSearchParams();
      if (q) params.set("q", q);
      if (cls) params.set("class", cls);
      const qs = params.toString();
      return req(`/invest${qs ? `?${qs}` : ""}`);
    },
  },
  tips: {
    list: () => req("/tips"),
  },
  user: {
    get: () => req("/user"),
    save: (body) => req("/user", { method: "PUT", body: JSON.stringify(body) }),
    saveSettings: (settings) => req("/user/settings", { method: "PATCH", body: JSON.stringify(settings) }),
  },
  admin: {
    overview: () => req("/admin/overview"),
    updateUser: (id, body) => req(`/admin/users/${id}`, { method: "PATCH", body: JSON.stringify(body) }),
    deleteUser: (id) => req(`/admin/users/${id}`, { method: "DELETE" }),
    setApi: (name, key) => req(`/admin/apis/${name}`, { method: "PUT", body: JSON.stringify({ key }) }),
    deleteApi: (name) => req(`/admin/apis/${name}`, { method: "DELETE" }),
    reset: () => req("/admin/reset", { method: "POST", body: JSON.stringify({}) }),
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
    investPicks: ({ monthly, years, risk }) => req("/ai/invest-picks", { method: "POST", body: JSON.stringify({ monthly, years, risk }) }),
    financeRadar: ({ topicId, topicTitle }) => req("/ai/finance-radar", { method: "POST", body: JSON.stringify({ topicId, topicTitle }) }),
  },
};
