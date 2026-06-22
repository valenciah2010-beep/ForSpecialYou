export function normalizedLogTimestamp(timestamp) {
  if (!timestamp) return '';

  if (typeof timestamp !== 'number') {
    return timestamp;
  }

  const swiftReferenceDateOffsetSeconds = 978307200;
  const timestampSeconds = timestamp < 1000000000
    ? timestamp + swiftReferenceDateOffsetSeconds
    : timestamp;

  return timestampSeconds < 100000000000
    ? timestampSeconds * 1000
    : timestampSeconds;
}

export function logDate(timestamp) {
  const normalizedTimestamp = normalizedLogTimestamp(timestamp);
  if (!normalizedTimestamp) return null;

  const date = new Date(normalizedTimestamp);
  return Number.isNaN(date.getTime()) ? null : date;
}

export function logTimestampMs(timestamp) {
  return logDate(timestamp)?.getTime() || 0;
}

export function dateInputValue(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function logDateInputValue(timestamp) {
  const date = logDate(timestamp);
  if (!date) return '';

  return dateInputValue(date);
}

export function timestampInDateRange(timestamp, startDate, endDate) {
  const dateValue = logDateInputValue(timestamp);
  if (!dateValue) return false;

  if (startDate && dateValue < startDate) return false;
  if (endDate && dateValue > endDate) return false;

  return true;
}

export function defaultBlockUntilDate() {
  const date = new Date();
  date.setDate(date.getDate() + 7);
  return dateInputValue(date);
}

export function inputDateToLocalDate(value) {
  if (!value) return null;

  const [year, month, day] = value.split('-').map(Number);
  if (!year || !month || !day) return null;

  return new Date(year, month - 1, day);
}

export function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export function formatDateInputLabel(dateValue) {
  if (!dateValue) return '';
  const [year, month, day] = dateValue.split('-').map(Number);
  const date = new Date(year, month - 1, day);
  return date.toLocaleDateString(undefined, {
    month: 'long',
    day: 'numeric',
    year: 'numeric'
  });
}

export function formatLogTimestamp(timestamp) {
  const date = logDate(timestamp);
  return date ? date.toLocaleString() : timestamp;
}

export function formatLogTime(timestamp) {
  const date = logDate(timestamp);
  return date
    ? date.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
    : '';
}
