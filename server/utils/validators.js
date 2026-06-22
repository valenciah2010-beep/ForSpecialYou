export const roles = new Set(['patient', 'parent', 'caregiver', 'doctor', 'admin']);

export function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function isValidPassword(password) {
  return String(password || '').length >= 6 && /\d/.test(password);
}

export function clampNumber(value, min, max, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.min(Math.max(Math.round(number), min), max);
}

export function normalizeNutrientDailyLimit(value) {
  return clampNumber(value, 0, 20, 3);
}
