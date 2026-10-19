const allowed = new Set([
  "page",
  "section",
  "type",
  "category",
  "categoryID",
  "title",
  "timestamp",
  "savedAt",
  "severity",
  "value",
  "calories",
  "protein",
  "carbs",
  "fat",
  "fiber",
  "sugar",
  "confidence",
  "date",
  "intensity",
  "duration",
  "count",
  "unit",
]);
export function deidentify(value) {
  if (Array.isArray(value)) return value.slice(-500).map(deidentify);
  if (!value || typeof value !== "object")
    return typeof value === "string" ? value.slice(0, 120) : value;
  return Object.fromEntries(
    Object.entries(value)
      .filter(
        ([key, item]) =>
          allowed.has(key) &&
          (key !== "value" ||
            typeof item === "number" ||
            (/^[-+\d., :/%°]+(?:\s*(?:kg|g|mg|ml|cm|mm|hours?|mins?|minutes?|bpm|kcal|lb|lbs|oz))?$/i.test(
              String(item),
            ) &&
              /\d/.test(String(item)))),
      )
      .map(([key, item]) => [key, deidentify(item)]),
  );
}
