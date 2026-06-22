import { formatLogTime, logTimestampMs } from './date.js';

export function childInfoRows(childProfile = {}) {
  return [
    { label: 'Child Name', value: childProfile.fullName },
    { label: 'Date of Birth', value: childProfile.birthDate },
    { label: 'Support Needs', value: childProfile.supportNeeds },
    { label: 'Home / School Notes', value: childProfile.homeSchoolNotes },
    { label: 'Emergency Contact', value: childProfile.emergencyContact },
    { label: 'Care Notes', value: childProfile.careNotes }
  ];
}

export function hasChildInfo(childProfile = {}) {
  return childInfoRows(childProfile).some((row) => String(row.value || '').trim());
}

export function logTypeLabel(log) {
  return log?.type === 'snapshot' ? 'Daily Snapshot' : 'Quick Log';
}

export function buildParentHistorySections(logs = [], meals = []) {
  const sectionMap = new Map();

  logs.forEach((log) => {
    const key = historySectionKey(log);
    if (!sectionMap.has(key)) {
      sectionMap.set(key, {
        key,
        title: historySectionTitle(log),
        icon: historySectionIcon(key),
        logs: []
      });
    }

    sectionMap.get(key).logs.push(log);
  });

  if (meals.length) {
    sectionMap.set('nutrition', {
      key: 'nutrition',
      title: 'Nutrition',
      icon: historySectionIcon('nutrition'),
      logs: [],
      meals
    });
  }

  return Array.from(sectionMap.values()).sort((left, right) => {
    const preferredOrder = ['nutrition', 'medicine', 'sleep', 'seizure'];
    const leftIndex = preferredOrder.indexOf(left.key);
    const rightIndex = preferredOrder.indexOf(right.key);

    if (leftIndex !== -1 || rightIndex !== -1) {
      return (leftIndex === -1 ? 99 : leftIndex) - (rightIndex === -1 ? 99 : rightIndex);
    }

    return left.title.localeCompare(right.title);
  });
}

export function historyPageKey(log) {
  return historySectionKey(log) === 'therapy' ? 'therapy' : 'health';
}

export function historySectionKey(log) {
  const category = String(log?.categoryID || '').toLowerCase();
  const title = String(log?.title || '').toLowerCase();

  if (category === 'medsfood' || category === 'medicine' || title.includes('medicine')) return 'medicine';
  if (category === 'sleep' || title.includes('sleep')) return 'sleep';
  if (category === 'seizure' || title.includes('seizure')) return 'seizure';
  if (category === 'therapy' || title.includes('therapy')) return 'therapy';
  return category || title.replace(/\s+/g, '-') || 'other';
}

export function historySectionTitle(log) {
  const key = historySectionKey(log);

  if (key === 'medicine') return 'Medicine';
  if (key === 'sleep') return 'Sleep & Rest';
  if (key === 'seizure') return 'Seizure';
  return log?.title || 'Other';
}

export function historySectionIcon(key) {
  const icons = {
    medicine: '💊',
    sleep: '🌙',
    seizure: '⏱️',
    pain: '📍',
    bowel: '🚽',
    therapy: '🧩',
    nutrition: '🍽️'
  };

  return icons[key] || '📌';
}

export function historySectionCount(section) {
  return (section?.logs?.length || 0) + (section?.meals?.length || 0);
}

export function savedMealMetricText(meal) {
  const estimate = meal?.estimate || {};
  const pieces = [];

  if (Number.isFinite(Number(estimate.calories))) pieces.push(`${estimate.calories} kcal`);
  if (Number.isFinite(Number(estimate.protein))) pieces.push(`${estimate.protein}g protein`);
  if (Number.isFinite(Number(estimate.carbs))) pieces.push(`${estimate.carbs}g carbs`);
  if (Number.isFinite(Number(estimate.fat))) pieces.push(`${estimate.fat}g fat`);

  return pieces.join(' · ') || 'No nutrient totals saved.';
}

export function savedMealList(items) {
  return Array.isArray(items) ? items.filter(Boolean) : [];
}

export function medicineRows(log) {
  const sourceText = String(log?.comments || log?.value || '').trim();
  if (!sourceText) return [];

  const rows = [];
  let currentTime = formatLogTime(log.timestamp);

  sourceText
    .split(/\n/)
    .flatMap((line) => line.split(';'))
    .map((part) => part.trim())
    .filter(Boolean)
    .forEach((part) => {
      const checkedMatch = part.match(/^(.*?)(Checked|Not checked)\s*-\s*(.+)$/i);
      if (!checkedMatch) return;

      const timePrefix = checkedMatch[1].trim().replace(/:\s*$/, '');
      if (timePrefix) {
        currentTime = timePrefix;
      }

      rows.push({
        time: currentTime,
        checked: checkedMatch[2].toLowerCase() === 'checked',
        name: checkedMatch[3].trim()
      });
    });

  return rows;
}

export function summarizedMedicineRows(logs) {
  const rowsByMedication = new Map();

  [...(logs || [])]
    .sort((left, right) => logTimestampMs(left.timestamp) - logTimestampMs(right.timestamp))
    .forEach((log) => {
      medicineRows(log).forEach((row) => {
        const key = `${row.name.toLowerCase()}|${row.time.toLowerCase()}`;
        const editTime = formatLogTime(log.timestamp);
        const editTimestamp = logTimestampMs(log.timestamp);

        if (!rowsByMedication.has(key)) {
          rowsByMedication.set(key, {
            name: row.name,
            time: row.time,
            checked: row.checked,
            checkedAt: row.checked ? editTime : '',
            latestTimestamp: editTimestamp,
            previousChecked: row.checked,
            editTimes: row.checked ? [editTime] : []
          });
          return;
        }

        const savedRow = rowsByMedication.get(key);
        if (row.checked && savedRow.previousChecked !== true) {
          savedRow.checkedAt = editTime;
          savedRow.editTimes = [editTime];
        } else if (!row.checked) {
          savedRow.checkedAt = '';
          savedRow.editTimes = [];
        }

        savedRow.previousChecked = row.checked;
        if (editTimestamp >= savedRow.latestTimestamp) {
          savedRow.checked = row.checked;
          savedRow.latestTimestamp = editTimestamp;
        }
      });
    });

  return Array.from(rowsByMedication.values())
    .map((row) => ({
      ...row,
      editTimes: row.checked && row.checkedAt ? [row.checkedAt] : []
    }))
    .sort((left, right) => {
      const doseOrder = {
        morning: 0,
        noon: 1,
        evening: 2
      };
      const leftOrder = doseOrder[left.time.toLowerCase()] ?? 99;
      const rightOrder = doseOrder[right.time.toLowerCase()] ?? 99;

      return leftOrder - rightOrder || left.name.localeCompare(right.name);
    });
}

export function logHasIntensityBar(log) {
  const severity = Number(log?.severity);
  const noIntensityCategories = new Set(['sleep', 'seizure', 'medsFood', 'medicine']);

  return Number.isFinite(severity)
    && severity >= 1
    && severity <= 5
    && !noIntensityCategories.has(log?.categoryID);
}
