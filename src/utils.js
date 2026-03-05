/**
 * createPageUrl – converts a PascalCase page name to a kebab-case URL path.
 * e.g. 'KanzleiDashboard' → '/kanzlei-dashboard'
 */
export function createPageUrl(pageName) {
  const kebab = pageName.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
  return `/${kebab}`;
}
