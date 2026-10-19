export const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL || "").replace(
  /\/$/,
  "",
);
export async function apiFetch(path, options = {}) {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    ...options,
    credentials: "include",
    headers: { "X-Requested-With": "CarePortal", ...options.headers },
  });
  if (response.status === 401 && path !== "/api/admin/login") {
    window.dispatchEvent(new Event("admin-session-expired"));
  }
  return response;
}
