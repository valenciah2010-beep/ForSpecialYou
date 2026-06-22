export function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function isValidPassword(password) {
  return String(password || '').length >= 6 && /\d/.test(password);
}

export function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}
