export function normalizeProfileImage(profileImage) {
  if (!profileImage) return null;
  const trimmedImage = String(profileImage).trim();
  return trimmedImage.startsWith('data:image/') ? trimmedImage : null;
}

export function publicUser(user) {
  return {
    id: user.id,
    nickname: user.username,
    email: user.email,
    role: user.role,
    profileImage: user.profile_image
  };
}

export function serializeUser(user) {
  return {
    id: user.id,
    nickname: user.username,
    email: user.email,
    role: user.role,
    profileImage: user.profile_image
  };
}

export function blockFieldsSQL(prefix = '') {
  const tablePrefix = prefix ? `${prefix}.` : '';
  return `
    ${tablePrefix}blocked_indefinitely AS blockedIndefinitely,
    DATE_FORMAT(${tablePrefix}blocked_until, '%Y-%m-%d %H:%i') AS blockedUntil,
    CASE
      WHEN ${tablePrefix}blocked_indefinitely = 1
        OR (${tablePrefix}blocked_until IS NOT NULL AND ${tablePrefix}blocked_until > NOW())
      THEN 1
      ELSE 0
    END AS isBlocked,
  `;
}

export function activeBlockMessage(user) {
  if (Number(user.blockedIndefinitely || user.blocked_indefinitely) === 1) {
    return 'This account is blocked until an admin unblocks it.';
  }

  const blockedUntil = user.blockedUntil || user.blocked_until;
  if (blockedUntil) {
    return `This account is blocked until ${blockedUntil}.`;
  }

  return 'This account is currently blocked.';
}

export function parseStoredJSON(value, fallback) {
  if (!value) return fallback;

  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}
