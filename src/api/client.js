const defaultApiBaseUrl = import.meta.env.DEV ? '' : 'https://fsyadmin.top';
export const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL || defaultApiBaseUrl).replace(/\/$/, '');

export function apiFetch(path, options) {
  return fetch(`${apiBaseUrl}${path}`, {
    credentials: 'include',
    ...(options || {})
  });
}
