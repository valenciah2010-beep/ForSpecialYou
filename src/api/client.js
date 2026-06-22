const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '';

export function apiFetch(path, options) {
  return fetch(`${apiBaseUrl}${path}`, {
    credentials: 'include',
    ...(options || {})
  });
}
