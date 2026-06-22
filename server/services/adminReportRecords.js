function dateFromStoredTimestamp(timestamp) {
  if (!timestamp) return '';

  let normalizedTimestamp = timestamp;
  if (typeof timestamp === 'number') {
    const swiftReferenceDateOffsetSeconds = 978307200;
    const timestampSeconds = timestamp < 1000000000
      ? timestamp + swiftReferenceDateOffsetSeconds
      : timestamp;

    normalizedTimestamp = timestampSeconds < 100000000000
      ? timestampSeconds * 1000
      : timestampSeconds;
  }

  const date = new Date(normalizedTimestamp);
  return Number.isNaN(date.getTime()) ? null : date;
}

function dateInputFromTimestamp(timestamp) {
  const date = dateFromStoredTimestamp(timestamp);
  if (!date) return '';

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function timestampInInputDateRange(timestamp, startDate, endDate) {
  const dateValue = dateInputFromTimestamp(timestamp);
  if (!dateValue) return false;
  if (startDate && dateValue < startDate) return false;
  if (endDate && dateValue > endDate) return false;
  return true;
}

function adminHistorySectionKey(log) {
  const category = String(log?.categoryID || '').toLowerCase();
  const title = String(log?.title || '').toLowerCase();

  if (category === 'medsfood' || category === 'medicine' || title.includes('medicine')) return 'medicine';
  if (category === 'sleep' || title.includes('sleep')) return 'sleep';
  if (category === 'seizure' || title.includes('seizure')) return 'seizure';
  if (category === 'therapy' || title.includes('therapy')) return 'therapy';
  return category || title.replace(/\s+/g, '-') || 'other';
}

function adminHistoryPageKey(log) {
  return adminHistorySectionKey(log) === 'therapy' ? 'therapy' : 'health';
}

function formatAdminRecordTime(timestamp) {
  const date = dateFromStoredTimestamp(timestamp);
  if (date) {
    return date.toLocaleString();
  }
  return String(timestamp || '');
}

export function buildAdminReportRecords({ healthLogs, savedMeals, filters }) {
  const selectedHealthSections = new Set(filters.healthSections || []);
  const allHealthSectionsSelected = selectedHealthSections.size === 0;
  const records = [];

  if (filters.includeHealth || filters.includeTherapy) {
    healthLogs
      .filter((log) => timestampInInputDateRange(log.timestamp, filters.startDate, filters.endDate))
      .forEach((log) => {
        const pageKey = adminHistoryPageKey(log);
        const sectionKey = adminHistorySectionKey(log);

        if (pageKey === 'therapy' && !filters.includeTherapy) return;
        if (pageKey === 'health') {
          if (!filters.includeHealth) return;
          if (!allHealthSectionsSelected && !selectedHealthSections.has(sectionKey)) return;
        }

        records.push({
          page: pageKey,
          section: sectionKey,
          title: log.title || sectionKey,
          type: log.type || '',
          timestamp: formatAdminRecordTime(log.timestamp),
          severity: log.severity ?? null,
          value: String(log.value || '').slice(0, 1200),
          comments: String(log.comments || '').slice(0, 1200)
        });
      });
  }

  if (filters.includeNutrient) {
    savedMeals
      .filter((meal) => timestampInInputDateRange(meal.savedAt, filters.startDate, filters.endDate))
      .forEach((meal) => {
        const estimate = meal.estimate || {};
        records.push({
          page: 'nutrient',
          section: 'nutrition',
          title: 'AI meal estimate',
          timestamp: formatAdminRecordTime(meal.savedAt),
          calories: estimate.calories ?? null,
          protein: estimate.protein ?? null,
          carbs: estimate.carbs ?? null,
          fat: estimate.fat ?? null,
          fiber: estimate.fiber ?? null,
          sugar: estimate.sugar ?? null,
          summary: String(estimate.summary || '').slice(0, 700),
          recommendations: Array.isArray(estimate.recommendations) ? estimate.recommendations.slice(0, 5) : [],
          notes: Array.isArray(estimate.notes) ? estimate.notes.slice(0, 5) : []
        });
      });
  }

  return records.slice(0, 220);
}
