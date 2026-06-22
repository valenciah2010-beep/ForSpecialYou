<script setup>
import { Ban, ChevronLeft, ChevronRight, Flower, Palette, Pencil, Plus, ShieldCheck, Trash2 } from '@lucide/vue';
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue';

const currentPath = ref(window.location.pathname);
const loginForm = ref({ username: '', password: '' });
const signupForm = ref({
  nickname: '',
  email: '',
  password: '',
  verifyPassword: ''
});
const createUserForm = ref({
  nickname: '',
  email: '',
  password: '',
  verifyPassword: ''
});
const editUserForm = ref({
  id: null,
  nickname: '',
  email: '',
  password: ''
});
const profileForm = ref({
  nickname: '',
  email: '',
  password: '',
  profileImage: ''
});
const loginMessage = ref('');
const loginStatus = ref('');
const signupMessage = ref('');
const signupStatus = ref('');
const createUserMessage = ref('');
const createUserStatus = ref('');
const editUserMessage = ref('');
const editUserStatus = ref('');
const profileMessage = ref('');
const profileStatus = ref('');
const deleteUserMessage = ref('');
const blockUserMessage = ref('');
const savedTheme = localStorage.getItem('carePortalTheme');
const currentTheme = ref(savedTheme || 'green');
const isThemeMenuOpen = ref(false);
const loggedInUser = ref(null);
const users = ref([]);
const usersMessage = ref('');
const isLoadingUsers = ref(false);
const isCreateUserOpen = ref(false);
const isEditUserOpen = ref(false);
const isDeleteUserOpen = ref(false);
const isBlockUserOpen = ref(false);
const isParentDetailOpen = ref(false);
const isParentExportOpen = ref(false);
const isParentExportPreviewOpen = ref(false);
const isPrintingParentReport = ref(false);
const isParentAIReportOpen = ref(false);
const isParentAIReportPreviewOpen = ref(false);
const isGeneratingParentAIReport = ref(false);
const isPrintingParentAIReport = ref(false);
const isCropperOpen = ref(false);
const isCropDragging = ref(false);
const isCreatingUser = ref(false);
const isSavingUser = ref(false);
const isSavingProfile = ref(false);
const isDeletingUser = ref(false);
const isSavingBlockUser = ref(false);
const userToDelete = ref(null);
const userToBlock = ref(null);
const blockMode = ref('indefinite');
const blockUntilDate = ref(defaultBlockUntilDate());
const selectedParentUser = ref(null);
const parentDetail = ref(null);
const parentDetailMessage = ref('');
const isLoadingParentDetail = ref(false);
const parentHistoryDateFilter = ref('');
const parentHistoryPageFilter = ref('health');
const parentHistorySectionFilter = ref('all');
const parentExportMessage = ref('');
const parentExportFilters = ref({
  startDate: '',
  endDate: '',
  includeHealth: true,
  includeTherapy: true,
  includeNutrient: true,
  healthSections: []
});
const parentAIReportMessage = ref('');
const parentAIReport = ref(null);
const parentAIReportMeta = ref(null);
const parentAIReportFilters = ref({
  startDate: '',
  endDate: '',
  language: 'english',
  includeHealth: true,
  includeTherapy: true,
  includeNutrient: true,
  healthSections: []
});
const isSavingNutrientLimit = ref(false);
const nutrientLimitDraft = ref('3');
const nutrientLimitMessage = ref('');
const isBusy = ref(false);
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '';
const maxProfileImageSize = 5 * 1024 * 1024;
const cropPosition = ref({
  x: 0,
  y: 0
});
const cropZoom = ref(1);
const cropPreview = ref('');
const clockTime = ref({
  hours: '00',
  minutes: '00',
  seconds: '00',
  period: 'AM',
  date: ''
});
const canManageUsers = computed(() => loggedInUser.value?.role === 'admin');
const blockUntilDateLabel = computed(() => {
  const date = inputDateToLocalDate(blockUntilDate.value);

  if (!date) return 'Choose a date';

  return date.toLocaleDateString(undefined, {
    month: 'long',
    day: 'numeric',
    year: 'numeric'
  });
});
const blockLengthText = computed(() => {
  const date = inputDateToLocalDate(blockUntilDate.value);
  if (!date) return 'Choose a valid date.';

  const today = startOfDay(new Date());
  const endDate = startOfDay(date);
  const dayCount = Math.ceil((endDate.getTime() - today.getTime()) / (24 * 60 * 60 * 1000));

  if (dayCount < 1) {
    return 'Choose a future date.';
  }

  if (dayCount >= 14) {
    const weekCount = Math.floor(dayCount / 7);
    const remainingDays = dayCount % 7;
    return `Blocked for ${weekCount} week${weekCount === 1 ? '' : 's'}${remainingDays ? ` and ${remainingDays} day${remainingDays === 1 ? '' : 's'}` : ''}.`;
  }

  return `Blocked for ${dayCount} day${dayCount === 1 ? '' : 's'}.`;
});
const filteredParentHistoryLogs = computed(() => {
  const logs = parentDetail.value?.healthLogs || [];
  const selectedDate = parentHistoryDateFilter.value;

  return logs
    .filter((log) => !selectedDate || logDateInputValue(log.timestamp) === selectedDate)
    .slice()
    .sort((left, right) => logTimestampMs(right.timestamp) - logTimestampMs(left.timestamp));
});
const filteredParentSavedMeals = computed(() => {
  const savedMeals = parentDetail.value?.savedMeals || [];
  const selectedDate = parentHistoryDateFilter.value;

  return savedMeals
    .filter((meal) => !selectedDate || logDateInputValue(meal.savedAt) === selectedDate)
    .slice()
    .sort((left, right) => logTimestampMs(right.savedAt) - logTimestampMs(left.savedAt));
});
const filteredParentHealthLogs = computed(() => (
  filteredParentHistoryLogs.value.filter((log) => historyPageKey(log) === 'health')
));
const filteredParentTherapyLogs = computed(() => (
  filteredParentHistoryLogs.value.filter((log) => historyPageKey(log) === 'therapy')
));
const parentHistoryPages = computed(() => [
  {
    key: 'health',
    title: 'Health',
    icon: '🩺',
    count: filteredParentHealthLogs.value.length
  },
  {
    key: 'therapy',
    title: 'Therapy',
    icon: '🧩',
    count: filteredParentTherapyLogs.value.length
  },
  {
    key: 'nutrient',
    title: 'Nutrient',
    icon: '🍽️',
    count: filteredParentSavedMeals.value.length
  }
]);
const activeParentHistoryPageTitle = computed(() => (
  parentHistoryPages.value.find((pageOption) => pageOption.key === parentHistoryPageFilter.value)?.title || 'History'
));
const activeParentHistorySections = computed(() => {
  if (parentHistoryPageFilter.value === 'nutrient') {
    return buildParentHistorySections([], filteredParentSavedMeals.value);
  }

  const logs = parentHistoryPageFilter.value === 'therapy'
    ? filteredParentTherapyLogs.value
    : filteredParentHealthLogs.value;

  return buildParentHistorySections(logs);
});
const activeParentHistoryItemCount = computed(() => (
  activeParentHistorySections.value.reduce((total, section) => total + historySectionCount(section), 0)
));
const hasParentHistoryForDate = computed(() => (
  filteredParentHistoryLogs.value.length > 0 || filteredParentSavedMeals.value.length > 0
));
const hasAnyParentHistory = computed(() => (
  Boolean(parentDetail.value?.healthLogs?.length) || Boolean(parentDetail.value?.savedMeals?.length)
));
const nutrientDailyLimit = computed(() => (
  clamp(Number(parentDetail.value?.nutrientDailyLimit ?? 3) || 0, 0, 20)
));
const nutrientUsageSummary = computed(() => {
  const limit = nutrientDailyLimit.value;
  const usage = parentDetail.value?.nutrientDailyUsage || {};
  const selectedDate = parentHistoryDateFilter.value;
  const usageDateMatches = usage?.dateKey && usage.dateKey === selectedDate;
  const syncedUsageCount = usageDateMatches ? Number(usage.estimateCount || 0) : NaN;
  const savedMealEstimateCount = filteredParentSavedMeals.value.length;
  const used = Number.isFinite(syncedUsageCount) ? syncedUsageCount : savedMealEstimateCount;

  return {
    used,
    limit
  };
});
const visibleParentHistorySections = computed(() => {
  if (parentHistorySectionFilter.value === 'all') {
    return activeParentHistorySections.value;
  }

  return activeParentHistorySections.value.filter((section) => section.key === parentHistorySectionFilter.value);
});
const availableParentExportHealthSections = computed(() => {
  const sectionMap = new Map();
  const logs = parentDetail.value?.healthLogs || [];

  logs
    .filter((log) => historyPageKey(log) === 'health')
    .filter((log) => timestampInDateRange(log.timestamp, parentExportFilters.value.startDate, parentExportFilters.value.endDate))
    .forEach((log) => {
      const key = historySectionKey(log);
      if (!sectionMap.has(key)) {
        sectionMap.set(key, {
          key,
          title: historySectionTitle(log),
          icon: historySectionIcon(key)
        });
      }
    });

  return Array.from(sectionMap.values()).sort((left, right) => left.title.localeCompare(right.title));
});
const availableParentAIReportHealthSections = computed(() => {
  const sectionMap = new Map();
  const logs = parentDetail.value?.healthLogs || [];

  logs
    .filter((log) => historyPageKey(log) === 'health')
    .filter((log) => timestampInDateRange(log.timestamp, parentAIReportFilters.value.startDate, parentAIReportFilters.value.endDate))
    .forEach((log) => {
      const key = historySectionKey(log);
      if (!sectionMap.has(key)) {
        sectionMap.set(key, {
          key,
          title: historySectionTitle(log),
          icon: historySectionIcon(key)
        });
      }
    });

  return Array.from(sectionMap.values()).sort((left, right) => left.title.localeCompare(right.title));
});
const parentExportHistorySections = computed(() => {
  if (!parentDetail.value) return [];

  const filters = parentExportFilters.value;
  const healthSectionKeys = new Set(filters.healthSections || []);
  const allHealthSectionsSelected = healthSectionKeys.size === 0;
  const logs = (parentDetail.value.healthLogs || [])
    .filter((log) => timestampInDateRange(log.timestamp, filters.startDate, filters.endDate))
    .filter((log) => {
      const pageKey = historyPageKey(log);
      if (pageKey === 'therapy') return filters.includeTherapy;
      if (!filters.includeHealth) return false;
      return allHealthSectionsSelected || healthSectionKeys.has(historySectionKey(log));
    });
  const meals = filters.includeNutrient
    ? (parentDetail.value.savedMeals || []).filter((meal) => timestampInDateRange(meal.savedAt, filters.startDate, filters.endDate))
    : [];

  return buildParentHistorySections(logs, meals);
});
const parentExportItemCount = computed(() => (
  parentExportHistorySections.value.reduce((total, section) => total + historySectionCount(section), 0)
));
const parentExportDateRangeLabel = computed(() => {
  const start = parentExportFilters.value.startDate;
  const end = parentExportFilters.value.endDate;

  if (start && end && start !== end) {
    return `${formatDateInputLabel(start)} - ${formatDateInputLabel(end)}`;
  }

  return formatDateInputLabel(start || end || dateInputValue(new Date()));
});
const parentAIReportHistorySections = computed(() => {
  if (!parentDetail.value) return [];

  const filters = parentAIReportFilters.value;
  const healthSectionKeys = new Set(filters.healthSections || []);
  const allHealthSectionsSelected = healthSectionKeys.size === 0;
  const logs = (parentDetail.value.healthLogs || [])
    .filter((log) => timestampInDateRange(log.timestamp, filters.startDate, filters.endDate))
    .filter((log) => {
      const pageKey = historyPageKey(log);
      if (pageKey === 'therapy') return filters.includeTherapy;
      if (!filters.includeHealth) return false;
      return allHealthSectionsSelected || healthSectionKeys.has(historySectionKey(log));
    });
  const meals = filters.includeNutrient
    ? (parentDetail.value.savedMeals || []).filter((meal) => timestampInDateRange(meal.savedAt, filters.startDate, filters.endDate))
    : [];

  return buildParentHistorySections(logs, meals);
});
const parentAIReportItemCount = computed(() => (
  parentAIReportHistorySections.value.reduce((total, section) => total + historySectionCount(section), 0)
));
const parentAIReportDateRangeLabel = computed(() => {
  const start = parentAIReportFilters.value.startDate;
  const end = parentAIReportFilters.value.endDate;

  if (start && end && start !== end) {
    return `${formatDateInputLabel(start)} - ${formatDateInputLabel(end)}`;
  }

  return formatDateInputLabel(start || end || dateInputValue(new Date()));
});
const parentAIReportLabels = computed(() => {
  const language = String(parentAIReport.value?.language || parentAIReportFilters.value.language || '').toLowerCase();
  const isChinese = language.includes('chinese') || language.includes('zh') || language.includes('中文');

  return isChinese
    ? {
        reportEyebrow: 'Care Portal AI 报告',
        parentAccount: '家长账号',
        username: '用户名',
        email: '邮箱',
        lastAppSync: '最后同步',
        reportDetails: '报告详情',
        recordsAnalyzed: '分析记录数',
        generated: '生成时间',
        summary: '总结',
        highlights: '重点发现',
        patterns: '深入模式分析',
        concerns: '需要关注',
        recommendations: '建议',
        dataQualityNotes: '数据质量说明',
        followUpQuestions: '后续问题',
        noHighlights: '没有返回明显重点发现。',
        noPatterns: '没有返回明确模式。',
        noConcerns: '没有返回具体关注点。',
        noRecommendations: '没有返回建议。',
        noDataQualityNotes: '没有返回数据质量说明。',
        noFollowUpQuestions: '没有返回后续问题。',
        disclaimer: 'AI 生成报告仅供管理员审核和整理信息使用，不是医疗建议、诊断或治疗。'
      }
    : {
        reportEyebrow: 'Care Portal AI Report',
        parentAccount: 'Parent Account',
        username: 'Username',
        email: 'Email',
        lastAppSync: 'Last App Sync',
        reportDetails: 'Report Details',
        recordsAnalyzed: 'Records Analyzed',
        generated: 'Generated',
        summary: 'Summary',
        highlights: 'Highlights',
        patterns: 'In-Depth Pattern Analysis',
        concerns: 'Concerns',
        recommendations: 'Recommendations',
        dataQualityNotes: 'Data Quality Notes',
        followUpQuestions: 'Follow-Up Questions',
        noHighlights: 'No major highlights returned.',
        noPatterns: 'No clear patterns returned.',
        noConcerns: 'No specific concerns returned.',
        noRecommendations: 'No recommendations returned.',
        noDataQualityNotes: 'No data quality notes returned.',
        noFollowUpQuestions: 'No follow-up questions returned.',
        disclaimer: 'AI-generated report for administrative review only. It is not medical advice, diagnosis, or treatment.'
      };
});
let cropImageElement;
let cropDragStart = {
  pointerX: 0,
  pointerY: 0,
  x: 0,
  y: 0
};

const page = computed(() => {
  if (currentPath.value === '/users') {
    if (!loggedInUser.value) return 'login';
    return canManageUsers.value ? 'users' : 'welcome';
  }
  if (currentPath.value === '/profile') {
    return loggedInUser.value ? 'profile' : 'login';
  }
  if (currentPath.value === '/welcome' || currentPath.value === '/home') {
    return loggedInUser.value ? 'welcome' : 'login';
  }
  if (currentPath.value === '/login') return 'login';
  if (currentPath.value === '/signup') return 'login';
  return loggedInUser.value ? 'welcome' : 'home';
});

const themeOptions = [
  { value: 'green', label: 'Green', color: '#27695d' },
  { value: 'blue', label: 'Blue', color: '#2f6df6' },
  { value: 'rose', label: 'Rose', color: '#be3455' },
  { value: 'gold', label: 'Gold', color: '#b7791f' },
  { value: 'sakura', label: 'Sakura', color: '#d95f8d', icon: 'flower' }
];

async function apiFetch(path, options) {
  return fetch(`${apiBaseUrl}${path}`, {
    credentials: 'include',
    ...(options || {})
  });
}

function setTheme(theme) {
  currentTheme.value = theme;
  localStorage.setItem('carePortalTheme', theme);
  isThemeMenuOpen.value = false;
}

function updateClock() {
  const now = new Date();
  const hours24 = now.getHours();
  const hours12 = hours24 % 12 || 12;

  clockTime.value = {
    hours: String(hours12).padStart(2, '0'),
    minutes: String(now.getMinutes()).padStart(2, '0'),
    seconds: String(now.getSeconds()).padStart(2, '0'),
    period: hours24 >= 12 ? 'PM' : 'AM',
    date: now.toLocaleDateString(undefined, {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    })
  };
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidPassword(password) {
  return password.length >= 6 && /\d/.test(password);
}

function sortUsersByImportance(userList) {
  return [...userList].sort((firstUser, secondUser) => {
    return String(firstUser.nickname || '').localeCompare(String(secondUser.nickname || ''));
  });
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function resetCreateUserForm() {
  createUserForm.value = {
    nickname: '',
    email: '',
    password: '',
    verifyPassword: ''
  };
}

function resetEditUserForm() {
  editUserForm.value = {
    id: null,
    nickname: '',
    email: '',
    password: ''
  };
}

function userInitials(user) {
  const name = user?.nickname || 'User';
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('');
}

function childInfoRows(childProfile = {}) {
  return [
    { label: 'Child Name', value: childProfile.fullName },
    { label: 'Date of Birth', value: childProfile.birthDate },
    { label: 'Support Needs', value: childProfile.supportNeeds },
    { label: 'Home / School Notes', value: childProfile.homeSchoolNotes },
    { label: 'Emergency Contact', value: childProfile.emergencyContact },
    { label: 'Care Notes', value: childProfile.careNotes }
  ];
}

function hasChildInfo(childProfile = {}) {
  return childInfoRows(childProfile).some((row) => String(row.value || '').trim());
}

function normalizedLogTimestamp(timestamp) {
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

function logDate(timestamp) {
  const normalizedTimestamp = normalizedLogTimestamp(timestamp);
  if (!normalizedTimestamp) return null;

  const date = new Date(normalizedTimestamp);
  return Number.isNaN(date.getTime()) ? null : date;
}

function logTimestampMs(timestamp) {
  return logDate(timestamp)?.getTime() || 0;
}

function logDateInputValue(timestamp) {
  const date = logDate(timestamp);
  if (!date) return '';

  return dateInputValue(date);
}

function timestampInDateRange(timestamp, startDate, endDate) {
  const dateValue = logDateInputValue(timestamp);
  if (!dateValue) return false;

  if (startDate && dateValue < startDate) return false;
  if (endDate && dateValue > endDate) return false;

  return true;
}

function dateInputValue(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function defaultBlockUntilDate() {
  const date = new Date();
  date.setDate(date.getDate() + 7);
  return dateInputValue(date);
}

function inputDateToLocalDate(value) {
  if (!value) return null;

  const [year, month, day] = value.split('-').map(Number);
  if (!year || !month || !day) return null;

  return new Date(year, month - 1, day);
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function shiftParentHistoryDate(dayOffset) {
  const selectedDate = parentHistoryDateFilter.value || dateInputValue(new Date());
  const [year, month, day] = selectedDate.split('-').map(Number);
  const date = new Date(year, month - 1, day);

  if (Number.isNaN(date.getTime())) {
    parentHistoryDateFilter.value = dateInputValue(new Date());
    return;
  }

  date.setDate(date.getDate() + dayOffset);
  parentHistoryDateFilter.value = dateInputValue(date);
}

function setParentHistoryPage(pageKey) {
  parentHistoryPageFilter.value = pageKey;
  parentHistorySectionFilter.value = 'all';
  nutrientLimitMessage.value = '';
}

function formatDateInputLabel(dateValue) {
  if (!dateValue) return '';
  const [year, month, day] = dateValue.split('-').map(Number);
  const date = new Date(year, month - 1, day);
  return date.toLocaleDateString(undefined, {
    month: 'long',
    day: 'numeric',
    year: 'numeric'
  });
}

function formatLogTimestamp(timestamp) {
  const date = logDate(timestamp);
  return date ? date.toLocaleString() : timestamp;
}

function formatLogTime(timestamp) {
  const date = logDate(timestamp);
  return date
    ? date.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
    : '';
}

function logTypeLabel(log) {
  return log?.type === 'snapshot' ? 'Daily Snapshot' : 'Quick Log';
}

function buildParentHistorySections(logs = [], meals = []) {
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

function historyPageKey(log) {
  return historySectionKey(log) === 'therapy' ? 'therapy' : 'health';
}

function historySectionKey(log) {
  const category = String(log?.categoryID || '').toLowerCase();
  const title = String(log?.title || '').toLowerCase();

  if (category === 'medsfood' || category === 'medicine' || title.includes('medicine')) return 'medicine';
  if (category === 'sleep' || title.includes('sleep')) return 'sleep';
  if (category === 'seizure' || title.includes('seizure')) return 'seizure';
  if (category === 'therapy' || title.includes('therapy')) return 'therapy';
  return category || title.replace(/\s+/g, '-') || 'other';
}

function historySectionTitle(log) {
  const key = historySectionKey(log);

  if (key === 'medicine') return 'Medicine';
  if (key === 'sleep') return 'Sleep & Rest';
  if (key === 'seizure') return 'Seizure';
  return log?.title || 'Other';
}

function historySectionIcon(key) {
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

function historySectionCount(section) {
  return (section?.logs?.length || 0) + (section?.meals?.length || 0);
}

function savedMealMetricText(meal) {
  const estimate = meal?.estimate || {};
  const pieces = [];

  if (Number.isFinite(Number(estimate.calories))) pieces.push(`${estimate.calories} kcal`);
  if (Number.isFinite(Number(estimate.protein))) pieces.push(`${estimate.protein}g protein`);
  if (Number.isFinite(Number(estimate.carbs))) pieces.push(`${estimate.carbs}g carbs`);
  if (Number.isFinite(Number(estimate.fat))) pieces.push(`${estimate.fat}g fat`);

  return pieces.join(' · ') || 'No nutrient totals saved.';
}

function savedMealList(items) {
  return Array.isArray(items) ? items.filter(Boolean) : [];
}

function medicineRows(log) {
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

function summarizedMedicineRows(logs) {
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

function logHasIntensityBar(log) {
  const severity = Number(log?.severity);
  const noIntensityCategories = new Set(['sleep', 'seizure', 'medsFood', 'medicine']);

  return Number.isFinite(severity)
    && severity >= 1
    && severity <= 5
    && !noIntensityCategories.has(log?.categoryID);
}

function syncProfileForm() {
  if (!loggedInUser.value) return;

  profileForm.value = {
    nickname: loggedInUser.value.nickname || '',
    email: loggedInUser.value.email || '',
    password: '',
    profileImage: loggedInUser.value.profileImage || ''
  };
}

function saveLoggedInUser(user) {
  loggedInUser.value = user;
}

function goTo(path) {
  window.history.pushState({}, '', path);
  currentPath.value = path;
  loginMessage.value = '';
  loginStatus.value = '';
  signupMessage.value = '';
  signupStatus.value = '';
  createUserMessage.value = '';
  createUserStatus.value = '';
  editUserMessage.value = '';
  editUserStatus.value = '';
  profileMessage.value = '';
  profileStatus.value = '';
  deleteUserMessage.value = '';

  if ((path === '/welcome' || path === '/users') && canManageUsers.value) {
    loadUsers();
  }

  if (path === '/profile') {
    syncProfileForm();
    loadCurrentUser();
  }
}

window.addEventListener('popstate', () => {
  currentPath.value = window.location.pathname;

  if (currentPath.value === '/users' && canManageUsers.value) {
    loadUsers();
  }

  if (currentPath.value === '/profile') {
    syncProfileForm();
    loadCurrentUser();
  }
});

let clockTimer;
onMounted(() => {
  updateClock();
  clockTimer = window.setInterval(updateClock, 1000);
  window.addEventListener('afterprint', finishParentReportPrint);
  window.addEventListener('afterprint', finishParentAIReportPrint);
  loadAdminSession();
});

onUnmounted(() => {
  window.clearInterval(clockTimer);
  window.removeEventListener('afterprint', finishParentReportPrint);
  window.removeEventListener('afterprint', finishParentAIReportPrint);
});

async function submitLogin() {
  loginMessage.value = '';
  loginStatus.value = '';
  isBusy.value = true;

  try {
    const response = await apiFetch('/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(loginForm.value)
    });
    const data = await response.json();

    if (response.ok) {
      saveLoggedInUser(data.user);
      loginForm.value = { username: '', password: '' };
      goTo('/welcome');
      return;
    }

    loginStatus.value = 'error';
    loginMessage.value = data.message;
  } catch {
    loginStatus.value = 'error';
    loginMessage.value = 'Unable to reach the server.';
  } finally {
    isBusy.value = false;
  }
}

async function loadAdminSession() {
  try {
    const response = await apiFetch('/api/admin/session');
    const data = await response.json();

    if (!response.ok) {
      loggedInUser.value = null;
      users.value = [];
      return;
    }

    saveLoggedInUser(data.user);
    syncProfileForm();

    if (currentPath.value === '/' || currentPath.value === '/login' || currentPath.value === '/signup') {
      goTo('/welcome');
    } else if (currentPath.value === '/users' && canManageUsers.value) {
      loadUsers();
    }
  } catch {
    loggedInUser.value = null;
    users.value = [];
  }
}

async function logOut() {
  try {
    await apiFetch('/api/admin/logout', {
      method: 'POST'
    });
  } catch {
    // Local cleanup still signs the admin out of this browser view.
  }

  loggedInUser.value = null;
  users.value = [];
  usersMessage.value = '';
  goTo('/');
}

async function loadCurrentUser() {
  if (!loggedInUser.value?.id) return;

  try {
    const response = await apiFetch('/api/admin/session');
    const data = await response.json();

    if (!response.ok) {
      profileStatus.value = 'error';
      profileMessage.value = data.message;
      return;
    }

    saveLoggedInUser(data.user);
    syncProfileForm();
  } catch {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to load your profile.';
  }
}

async function loadUsers() {
  isLoadingUsers.value = true;
  usersMessage.value = '';

  try {
    const response = await apiFetch('/api/admin/app-users');
    const data = await response.json();

    if (!response.ok) {
      usersMessage.value = data.message;
      users.value = [];
      return;
    }

    users.value = sortUsersByImportance(data.users);
  } catch {
    usersMessage.value = 'Unable to load users from the server.';
    users.value = [];
  } finally {
    isLoadingUsers.value = false;
  }
}

function openCreateUserModal() {
  resetCreateUserForm();
  createUserMessage.value = '';
  createUserStatus.value = '';
  isCreateUserOpen.value = true;
}

function closeCreateUserModal() {
  isCreateUserOpen.value = false;
  createUserMessage.value = '';
  createUserStatus.value = '';
}

function openEditUserModal(user) {
  editUserForm.value = {
    id: user.id,
    nickname: user.nickname,
    email: user.email,
    password: ''
  };
  editUserMessage.value = '';
  editUserStatus.value = '';
  isEditUserOpen.value = true;
}

function closeEditUserModal() {
  isEditUserOpen.value = false;
  editUserMessage.value = '';
  editUserStatus.value = '';
  resetEditUserForm();
}

function openDeleteUserModal(user) {
  userToDelete.value = user;
  deleteUserMessage.value = '';
  isDeleteUserOpen.value = true;
}

function closeDeleteUserModal() {
  isDeleteUserOpen.value = false;
  deleteUserMessage.value = '';
  userToDelete.value = null;
}

function openBlockUserModal(user) {
  userToBlock.value = user;
  blockUserMessage.value = '';
  blockMode.value = 'indefinite';
  blockUntilDate.value = defaultBlockUntilDate();
  isBlockUserOpen.value = true;
}

function closeBlockUserModal() {
  isBlockUserOpen.value = false;
  blockUserMessage.value = '';
  userToBlock.value = null;
  blockMode.value = 'indefinite';
  blockUntilDate.value = defaultBlockUntilDate();
}

async function openParentDetail(user) {
  selectedParentUser.value = user;
  parentDetail.value = null;
  parentDetailMessage.value = '';
  parentHistoryDateFilter.value = dateInputValue(new Date());
  parentHistoryPageFilter.value = 'health';
  parentHistorySectionFilter.value = 'all';
  nutrientLimitMessage.value = '';
  isParentDetailOpen.value = true;
  isLoadingParentDetail.value = true;

  await loadParentDetail(user.id);
}

function resetParentExportFilters() {
  const defaultDate = parentHistoryDateFilter.value || dateInputValue(new Date());
  parentExportFilters.value = {
    startDate: defaultDate,
    endDate: defaultDate,
    includeHealth: true,
    includeTherapy: true,
    includeNutrient: true,
    healthSections: []
  };
}

function openParentExportPanel() {
  resetParentExportFilters();
  parentExportMessage.value = '';
  isParentExportOpen.value = true;
}

function closeParentExportPanel() {
  isParentExportOpen.value = false;
  parentExportMessage.value = '';
}

function closeParentExportPreview() {
  isParentExportPreviewOpen.value = false;
  parentExportMessage.value = '';
}

function resetParentAIReportFilters() {
  const defaultDate = parentHistoryDateFilter.value || dateInputValue(new Date());
  parentAIReportFilters.value = {
    startDate: defaultDate,
    endDate: defaultDate,
    language: 'english',
    includeHealth: true,
    includeTherapy: true,
    includeNutrient: true,
    healthSections: []
  };
}

function openParentAIReportPanel() {
  resetParentAIReportFilters();
  parentAIReportMessage.value = '';
  parentAIReport.value = null;
  parentAIReportMeta.value = null;
  isParentAIReportOpen.value = true;
}

function closeParentAIReportPanel() {
  isParentAIReportOpen.value = false;
  parentAIReportMessage.value = '';
}

function closeParentAIReportPreview() {
  isParentAIReportPreviewOpen.value = false;
  parentAIReportMessage.value = '';
}

function backToParentAIReportOptions() {
  isParentAIReportPreviewOpen.value = false;
  isParentAIReportOpen.value = true;
}

function backToParentExportOptions() {
  isParentExportPreviewOpen.value = false;
  isParentExportOpen.value = true;
}

function selectAllParentExportHealthSections() {
  parentExportFilters.value.healthSections = availableParentExportHealthSections.value.map((section) => section.key);
}

function clearParentExportHealthSections() {
  parentExportFilters.value.healthSections = [];
}

function selectAllParentAIReportHealthSections() {
  parentAIReportFilters.value.healthSections = availableParentAIReportHealthSections.value.map((section) => section.key);
}

function clearParentAIReportHealthSections() {
  parentAIReportFilters.value.healthSections = [];
}

function hasValidParentExportRange() {
  const { startDate, endDate } = parentExportFilters.value;
  return Boolean(startDate && endDate && startDate <= endDate);
}

function validateParentExportSelection() {
  const filters = parentExportFilters.value;

  if (!hasValidParentExportRange()) {
    return 'Choose a valid start and end date.';
  }

  if (!filters.includeHealth && !filters.includeTherapy && !filters.includeNutrient) {
    return 'Choose at least one page to include.';
  }

  if (!parentExportItemCount.value) {
    return 'No selected history is available for this date range.';
  }

  return '';
}

function validateParentAIReportSelection() {
  const filters = parentAIReportFilters.value;

  if (!filters.startDate || !filters.endDate || filters.startDate > filters.endDate) {
    return 'Choose a valid start and end date.';
  }

  if (!filters.includeHealth && !filters.includeTherapy && !filters.includeNutrient) {
    return 'Choose at least one page to analyze.';
  }

  if (!parentAIReportItemCount.value) {
    return 'No selected history is available for this date range.';
  }

  return '';
}

function openParentExportPreview() {
  const validationMessage = validateParentExportSelection();
  if (validationMessage) {
    parentExportMessage.value = validationMessage;
    return;
  }

  parentExportMessage.value = '';
  isParentExportOpen.value = false;
  isParentExportPreviewOpen.value = true;
}

async function printParentReport() {
  const validationMessage = validateParentExportSelection();
  if (validationMessage) {
    parentExportMessage.value = validationMessage;
    return;
  }

  parentExportMessage.value = '';
  isPrintingParentReport.value = true;
  await nextTick();
  window.print();
}

function finishParentReportPrint() {
  isPrintingParentReport.value = false;
}

async function generateParentAIReport() {
  const validationMessage = validateParentAIReportSelection();
  const userId = parentDetail.value?.user?.id || selectedParentUser.value?.id;

  if (validationMessage) {
    parentAIReportMessage.value = validationMessage;
    return;
  }

  if (!userId) return;

  parentAIReportMessage.value = '';
  isGeneratingParentAIReport.value = true;

  try {
    const response = await apiFetch(`/api/admin/app-users/${userId}/ai-report`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(parentAIReportFilters.value)
    });
    const data = await response.json();

    if (!response.ok) {
      parentAIReportMessage.value = data.message || 'Could not create the AI report.';
      return;
    }

    parentAIReport.value = data.report;
    parentAIReportMeta.value = {
      recordCount: data.recordCount,
      generatedAt: data.generatedAt,
      language: parentAIReportFilters.value.language
    };
    isParentAIReportOpen.value = false;
    isParentAIReportPreviewOpen.value = true;
  } catch {
    parentAIReportMessage.value = 'Unable to reach the server.';
  } finally {
    isGeneratingParentAIReport.value = false;
  }
}

async function printParentAIReport() {
  if (!parentAIReport.value) return;

  isPrintingParentAIReport.value = true;
  await nextTick();
  window.print();
}

function finishParentAIReportPrint() {
  isPrintingParentAIReport.value = false;
}

async function refreshParentDetail() {
  if (!selectedParentUser.value?.id) return;
  parentDetailMessage.value = '';
  nutrientLimitMessage.value = '';
  isLoadingParentDetail.value = true;
  await loadParentDetail(selectedParentUser.value.id);
}

async function loadParentDetail(userId) {
  try {
    const response = await apiFetch(`/api/admin/app-users/${userId}/details`);
    const data = await response.json();

    if (!response.ok) {
      parentDetailMessage.value = data.message;
      return;
    }

    parentDetail.value = data;
    nutrientLimitDraft.value = String(clamp(Number(data.nutrientDailyLimit ?? 3) || 0, 0, 20));
  } catch {
    parentDetailMessage.value = 'Unable to load parent details.';
  } finally {
    isLoadingParentDetail.value = false;
  }
}

function closeParentDetail() {
  isParentDetailOpen.value = false;
  selectedParentUser.value = null;
  parentDetail.value = null;
  parentDetailMessage.value = '';
  parentHistoryDateFilter.value = '';
  parentHistoryPageFilter.value = 'health';
  parentHistorySectionFilter.value = 'all';
  closeParentExportPanel();
  closeParentExportPreview();
  closeParentAIReportPanel();
  closeParentAIReportPreview();
  resetParentExportFilters();
  resetParentAIReportFilters();
  parentAIReport.value = null;
  parentAIReportMeta.value = null;
  parentAIReportMessage.value = '';
  nutrientLimitMessage.value = '';
  nutrientLimitDraft.value = '3';
  isSavingNutrientLimit.value = false;
}

async function saveParentNutrientLimit() {
  const userId = parentDetail.value?.user?.id || selectedParentUser.value?.id;
  if (!userId) return;

  const typedLimit = Number(nutrientLimitDraft.value);
  if (!Number.isInteger(typedLimit) || typedLimit < 0 || typedLimit > 20) {
    nutrientLimitMessage.value = 'Enter a whole number from 0 to 20.';
    return;
  }

  const dailyLimit = clamp(typedLimit, 0, 20);
  if (dailyLimit === nutrientDailyLimit.value) {
    nutrientLimitMessage.value = 'This quota is already saved.';
    return;
  }

  const confirmed = window.confirm(`Are you sure you want to change this account to ${dailyLimit} estimates per day?`);
  if (!confirmed) {
    nutrientLimitDraft.value = String(nutrientDailyLimit.value);
    return;
  }

  nutrientLimitMessage.value = '';
  isSavingNutrientLimit.value = true;

  try {
    const response = await apiFetch(`/api/admin/app-users/${userId}/nutrient-limit`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ dailyLimit })
    });
    const data = await response.json();

    if (!response.ok) {
      nutrientLimitMessage.value = data.message || 'Could not update nutrient estimate limit.';
      return;
    }

    parentDetail.value = {
      ...parentDetail.value,
      nutrientDailyLimit: data.nutrientDailyLimit
    };
    nutrientLimitDraft.value = String(data.nutrientDailyLimit);
    nutrientLimitMessage.value = data.message;
  } catch {
    nutrientLimitMessage.value = 'Unable to reach the server.';
  } finally {
    isSavingNutrientLimit.value = false;
  }
}

async function submitEditUser() {
  editUserMessage.value = '';
  editUserStatus.value = '';

  if (!editUserForm.value.nickname || !editUserForm.value.email) {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Please fill out nickname and email.';
    return;
  }

  if (!isValidEmail(editUserForm.value.email)) {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (editUserForm.value.password && !isValidPassword(editUserForm.value.password)) {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  isSavingUser.value = true;

  try {
    const response = await apiFetch(`/api/users/${editUserForm.value.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nickname: editUserForm.value.nickname,
        username: editUserForm.value.nickname,
        email: editUserForm.value.email,
        password: editUserForm.value.password
      })
    });
    const data = await response.json();

    if (!response.ok) {
      editUserStatus.value = 'error';
      editUserMessage.value = data.message;
      return;
    }

    if (loggedInUser.value?.id === editUserForm.value.id) {
      saveLoggedInUser({
        ...loggedInUser.value,
        nickname: editUserForm.value.nickname,
        email: editUserForm.value.email
      });
    }

    closeEditUserModal();
    await loadUsers();
  } catch {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Unable to reach the server.';
  } finally {
    isSavingUser.value = false;
  }
}

function handleProfileImageChange(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  event.target.value = '';

  if (!file.type.startsWith('image/')) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please choose an image file.';
    return;
  }

  if (file.size > maxProfileImageSize) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please choose an image smaller than 5MB.';
    return;
  }

  const reader = new FileReader();
  reader.addEventListener('load', () => {
    openProfileImageCropper(String(reader.result || ''));
    profileMessage.value = '';
    profileStatus.value = '';
  });
  reader.addEventListener('error', () => {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to load that image.';
  });
  reader.readAsDataURL(file);
}

function openProfileImageCropper(imageSource) {
  cropPosition.value = {
    x: 0,
    y: 0
  };
  cropZoom.value = 1;
  isCropDragging.value = false;
  cropPreview.value = '';
  cropImageElement = new Image();
  cropImageElement.addEventListener('load', () => {
    isCropperOpen.value = true;
    renderCropPreview();
  });
  cropImageElement.addEventListener('error', () => {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to load that image.';
  });
  cropImageElement.src = imageSource;
}

function renderCropPreview() {
  if (!cropImageElement?.naturalWidth || !cropImageElement?.naturalHeight) return;

  const outputSize = 360;
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  if (!context) return;

  const cropSize = Math.min(cropImageElement.naturalWidth, cropImageElement.naturalHeight) / cropZoom.value;
  const maxLeft = Math.max(0, cropImageElement.naturalWidth - cropSize);
  const maxTop = Math.max(0, cropImageElement.naturalHeight - cropSize);
  const sourceX = maxLeft * ((Number(cropPosition.value.x) + 100) / 200);
  const sourceY = maxTop * ((Number(cropPosition.value.y) + 100) / 200);

  canvas.width = outputSize;
  canvas.height = outputSize;
  context.drawImage(
    cropImageElement,
    sourceX,
    sourceY,
    cropSize,
    cropSize,
    0,
    0,
    outputSize,
    outputSize
  );
  cropPreview.value = canvas.toDataURL('image/jpeg', 0.9);
}

function startCropDrag(event) {
  if (!cropPreview.value) return;

  isCropDragging.value = true;
  cropDragStart = {
    pointerX: event.clientX,
    pointerY: event.clientY,
    x: cropPosition.value.x,
    y: cropPosition.value.y
  };
  event.currentTarget.setPointerCapture?.(event.pointerId);
}

function moveCropImage(event) {
  if (!isCropDragging.value) return;

  const frameSize = event.currentTarget.getBoundingClientRect().width || 220;
  const deltaX = event.clientX - cropDragStart.pointerX;
  const deltaY = event.clientY - cropDragStart.pointerY;

  cropPosition.value = {
    x: clamp(cropDragStart.x - (deltaX / frameSize) * 200, -100, 100),
    y: clamp(cropDragStart.y - (deltaY / frameSize) * 200, -100, 100)
  };
  renderCropPreview();
}

function zoomCropImage(event) {
  const nextZoom = cropZoom.value + (event.deltaY < 0 ? 0.16 : -0.16);
  cropZoom.value = clamp(nextZoom, 1, 4);
  renderCropPreview();
}

function stopCropDrag(event) {
  if (!isCropDragging.value) return;

  isCropDragging.value = false;
  try {
    event.currentTarget.releasePointerCapture?.(event.pointerId);
  } catch {
    // The pointer may already be released when the browser fires lostpointercapture.
  }
}

function closeProfileImageCropper() {
  isCropperOpen.value = false;
  isCropDragging.value = false;
  cropPreview.value = '';
  cropImageElement = undefined;
}

function applyProfileImageCrop() {
  if (!cropPreview.value) return;

  profileForm.value.profileImage = cropPreview.value;
  profileMessage.value = '';
  profileStatus.value = '';
  closeProfileImageCropper();
}

function removeProfileImage() {
  profileForm.value.profileImage = '';
  closeProfileImageCropper();
}

async function submitProfile() {
  profileMessage.value = '';
  profileStatus.value = '';

  if (!profileForm.value.nickname || !profileForm.value.email) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please fill out nickname and email.';
    return;
  }

  if (!isValidEmail(profileForm.value.email)) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (profileForm.value.password && !isValidPassword(profileForm.value.password)) {
    profileStatus.value = 'error';
    profileMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  isSavingProfile.value = true;

  try {
    const response = await apiFetch(`/api/users/${loggedInUser.value.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nickname: profileForm.value.nickname,
        username: profileForm.value.nickname,
        email: profileForm.value.email,
        password: profileForm.value.password,
        profileImage: profileForm.value.profileImage
      })
    });
    const data = await response.json();

    if (!response.ok) {
      profileStatus.value = 'error';
      profileMessage.value = data.message;
      return;
    }

    saveLoggedInUser({
      ...loggedInUser.value,
      nickname: profileForm.value.nickname,
      email: profileForm.value.email,
      profileImage: profileForm.value.profileImage
    });
    profileForm.value.password = '';
    profileStatus.value = 'success';
    profileMessage.value = data.message;

    if (canManageUsers.value) {
      await loadUsers();
    }
  } catch {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to reach the server.';
  } finally {
    isSavingProfile.value = false;
  }
}

async function confirmDeleteUser() {
  if (!userToDelete.value) return;

  isDeletingUser.value = true;
  deleteUserMessage.value = '';

  try {
    const deletedUserId = userToDelete.value.id;
    const response = await apiFetch(`/api/users/${deletedUserId}`, {
      method: 'DELETE'
    });
    const data = await response.json();

    if (!response.ok) {
      deleteUserMessage.value = data.message;
      return;
    }

    closeDeleteUserModal();

    if (loggedInUser.value?.id === deletedUserId) {
      logOut();
      return;
    }

    await loadUsers();
  } catch {
    deleteUserMessage.value = 'Unable to reach the server.';
  } finally {
    isDeletingUser.value = false;
  }
}

async function confirmBlockUser() {
  if (!userToBlock.value) return;

  isSavingBlockUser.value = true;
  blockUserMessage.value = '';

  if (!userToBlock.value.isBlocked && blockMode.value === 'duration') {
    const untilDate = inputDateToLocalDate(blockUntilDate.value);

    if (!untilDate || startOfDay(untilDate) <= startOfDay(new Date())) {
      blockUserMessage.value = 'Please choose a future unblock date.';
      isSavingBlockUser.value = false;
      return;
    }
  }

  try {
    const userId = userToBlock.value.id;
    const response = await apiFetch(`/api/admin/app-users/${userId}/block`, {
      method: userToBlock.value.isBlocked ? 'DELETE' : 'PATCH',
      headers: userToBlock.value.isBlocked ? undefined : { 'Content-Type': 'application/json' },
      body: userToBlock.value.isBlocked
        ? undefined
        : JSON.stringify({
            mode: blockMode.value,
            untilDate: blockUntilDate.value
          })
    });
    const data = await response.json();

    if (!response.ok) {
      blockUserMessage.value = data.message;
      return;
    }

    closeBlockUserModal();
    await loadUsers();

    if (selectedParentUser.value?.id === userId) {
      await refreshParentDetail();
    }
  } catch {
    blockUserMessage.value = 'Unable to reach the server.';
  } finally {
    isSavingBlockUser.value = false;
  }
}

async function submitCreateUser() {
  createUserMessage.value = '';
  createUserStatus.value = '';

  if (!isValidEmail(createUserForm.value.email)) {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (!isValidPassword(createUserForm.value.password)) {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  if (createUserForm.value.password !== createUserForm.value.verifyPassword) {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Passwords do not match.';
    return;
  }

  isCreatingUser.value = true;

  try {
    const createUserPayload = {
      ...createUserForm.value,
      username: createUserForm.value.nickname
    };

    const response = await apiFetch('/api/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(createUserPayload)
    });
    const data = await response.json();

    if (!response.ok) {
      createUserStatus.value = 'error';
      createUserMessage.value = data.message;
      return;
    }

    closeCreateUserModal();
    await loadUsers();
  } catch {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Unable to reach the server.';
  } finally {
    isCreatingUser.value = false;
  }
}

async function submitSignup() {
  signupMessage.value = '';
  signupStatus.value = '';

  if (!isValidEmail(signupForm.value.email)) {
    signupStatus.value = 'error';
    signupMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (!isValidPassword(signupForm.value.password)) {
    signupStatus.value = 'error';
    signupMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  if (signupForm.value.password !== signupForm.value.verifyPassword) {
    signupStatus.value = 'error';
    signupMessage.value = 'Passwords do not match.';
    return;
  }

  isBusy.value = true;

  try {
    const signupPayload = {
      ...signupForm.value,
      username: signupForm.value.nickname
    };

    const response = await apiFetch('/api/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(signupPayload)
    });
    const data = await response.json();
    signupStatus.value = response.ok ? 'success' : 'error';
    signupMessage.value = data.message;

    if (response.ok) {
      const createdNickname = signupForm.value.nickname;
      signupForm.value = {
        nickname: '',
        email: '',
        password: '',
        verifyPassword: ''
      };
      loginForm.value = {
        username: createdNickname,
        password: ''
      };
      goTo('/login');
    }
  } catch {
    signupStatus.value = 'error';
    signupMessage.value = 'Unable to reach the server.';
  } finally {
    isBusy.value = false;
  }
}
</script>

<template>
  <main
    class="shell"
    :class="{
      'printing-parent-report': isPrintingParentReport,
      'previewing-parent-report': isParentExportPreviewOpen,
      'printing-ai-report': isPrintingParentAIReport,
      'previewing-ai-report': isParentAIReportPreviewOpen
    }"
    :data-theme="currentTheme"
  >
    <div class="theme-switcher">
      <button
        class="theme-toggle"
        type="button"
        aria-label="Open theme menu"
        :aria-expanded="isThemeMenuOpen"
        @click="isThemeMenuOpen = !isThemeMenuOpen"
      >
        <Palette :size="20" aria-hidden="true" />
      </button>
      <div v-if="isThemeMenuOpen" class="theme-menu" aria-label="Theme selector">
        <button
          v-for="theme in themeOptions"
          :key="theme.value"
          class="theme-menu-item"
          :class="{ active: currentTheme === theme.value }"
          type="button"
          :style="{ '--theme-color': theme.color }"
          @click="setTheme(theme.value)"
        >
          <span class="theme-swatch">
            <Flower v-if="theme.icon === 'flower'" :size="16" aria-hidden="true" />
          </span>
          <span>{{ theme.label }}</span>
        </button>
      </div>
    </div>

    <section v-if="page === 'home'" class="home-panel">
      <p class="eyebrow">Care Portal</p>
      <h1>Admin access</h1>
      <p class="intro">
        Sign in with an admin account to view simulator app users.
      </p>
      <div class="actions">
        <button class="primary-button" type="button" @click="goTo('/login')">Admin Log In</button>
      </div>
    </section>

    <section v-else-if="page === 'welcome'" class="users-page">
      <aside class="sidebar">
        <div class="brand">
          <div class="brand-mark">CP</div>
          <div>
            <strong>Care Portal</strong>
            <span>Welcome</span>
          </div>
        </div>
        <button class="nav-button active" type="button" @click="goTo('/welcome')">Welcome</button>
        <button class="nav-button" type="button" @click="goTo('/profile')">Profile</button>
        <button v-if="canManageUsers" class="nav-button" type="button" @click="goTo('/users')">Users</button>
      </aside>

      <section class="workspace">
        <header class="workspace-header">
          <h1>Welcome</h1>
          <div class="header-actions">
            <section class="live-clock" aria-label="Live clock">
              <div class="live-clock-main">
                <strong>{{ clockTime.hours }}</strong>
                <span>:</span>
                <strong>{{ clockTime.minutes }}</strong>
                <em>{{ clockTime.period }}</em>
              </div>
              <div class="live-clock-meta">
                <span>{{ clockTime.seconds }} sec</span>
                <span>{{ clockTime.date }}</span>
              </div>
            </section>
            <button v-if="loggedInUser" class="profile-trigger" type="button" @click="goTo('/profile')">
              <span class="avatar small">
                <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </span>
              <span>{{ loggedInUser.nickname }}</span>
            </button>
            <button class="link-button" type="button" @click="logOut">Log Out</button>
          </div>
        </header>

        <section class="table-panel welcome-panel">
          <div class="welcome-hero">
            <p class="eyebrow">Care Portal Admin</p>
            <h2>Welcome{{ loggedInUser ? `, ${loggedInUser.nickname}` : '' }}</h2>
          </div>
          <div class="welcome-card-grid">
            <article class="welcome-card">
              <strong>{{ users.length }}</strong>
              <span>Synced parent accounts</span>
            </article>
            <article class="welcome-card">
              <strong>{{ clockTime.date }}</strong>
              <span>Current portal date</span>
            </article>
            <article class="welcome-card">
              <strong>Ready</strong>
              <span>Admin portal status</span>
            </article>
          </div>
          <div class="actions welcome-actions">
            <button class="primary-button" type="button" @click="goTo('/users')">View Parent Users</button>
            <button class="secondary-button" type="button" @click="goTo('/profile')">Edit Profile</button>
          </div>
        </section>
      </section>
    </section>

    <section v-else-if="page === 'profile'" class="users-page">
      <aside class="sidebar">
        <div class="brand">
          <div class="brand-mark">CP</div>
          <div>
            <strong>Care Portal</strong>
            <span>Profile</span>
          </div>
        </div>
        <button class="nav-button" type="button" @click="goTo('/welcome')">Welcome</button>
        <button class="nav-button active" type="button" @click="goTo('/profile')">Profile</button>
        <button v-if="canManageUsers" class="nav-button" type="button" @click="goTo('/users')">Users</button>
      </aside>

      <section class="workspace">
        <header class="workspace-header">
          <h1>Profile</h1>
          <div class="header-actions">
            <section class="live-clock" aria-label="Live clock">
              <div class="live-clock-main">
                <strong>{{ clockTime.hours }}</strong>
                <span>:</span>
                <strong>{{ clockTime.minutes }}</strong>
                <em>{{ clockTime.period }}</em>
              </div>
              <div class="live-clock-meta">
                <span>{{ clockTime.seconds }} sec</span>
                <span>{{ clockTime.date }}</span>
              </div>
            </section>
            <button v-if="loggedInUser" class="profile-trigger" type="button" @click="goTo('/profile')">
              <span class="avatar small">
                <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </span>
              <span>{{ loggedInUser.nickname }}</span>
            </button>
            <button class="link-button" type="button" @click="logOut">Log Out</button>
          </div>
        </header>

        <section class="table-panel profile-panel">
          <div class="profile-layout">
            <div class="profile-photo-card">
              <div class="avatar large">
                <img v-if="profileForm.profileImage" :src="profileForm.profileImage" alt="Profile preview" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </div>
              <label class="secondary-button compact upload-button">
                Change Image
                <input type="file" accept="image/*" @change="handleProfileImageChange" />
              </label>
              <button class="text-action danger" type="button" @click="removeProfileImage">Remove Image</button>
            </div>

            <form class="profile-form" @submit.prevent="submitProfile">
              <div class="grid">
                <label>
                  Nickname
                  <input v-model="profileForm.nickname" autocomplete="nickname" required />
                </label>
                <label>
                  Email
                  <input v-model="profileForm.email" type="email" autocomplete="email" required />
                </label>
                <label>
                  New Password
                  <input
                    v-model="profileForm.password"
                    type="password"
                    autocomplete="new-password"
                    minlength="6"
                    pattern="(?=.*[0-9]).{6,}"
                    placeholder="Leave blank to keep current password"
                  />
                </label>
              </div>

              <button class="primary-button full" type="submit" :disabled="isSavingProfile">
                {{ isSavingProfile ? 'Saving...' : 'Save Profile' }}
              </button>
            </form>
          </div>

          <p v-if="profileMessage" class="message" :class="{ error: profileStatus === 'error' }">
            {{ profileMessage }}
          </p>
        </section>
      </section>

      <div v-if="isCropperOpen" class="modal-backdrop" @click.self="closeProfileImageCropper">
        <section class="modal-panel crop-panel" role="dialog" aria-modal="true" aria-labelledby="crop-image-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">Profile Image</p>
              <h2 id="crop-image-title">Crop Image</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close image cropper" @click="closeProfileImageCropper">
              X
            </button>
          </div>

          <div class="crop-layout">
            <div
              class="crop-preview-frame"
              :class="{ dragging: isCropDragging }"
              @pointerdown="startCropDrag"
              @pointermove="moveCropImage"
              @pointerup="stopCropDrag"
              @pointercancel="stopCropDrag"
              @lostpointercapture="stopCropDrag"
              @wheel.prevent="zoomCropImage"
            >
              <img v-if="cropPreview" :src="cropPreview" alt="Cropped profile preview" />
              <span v-else>{{ userInitials(loggedInUser) }}</span>
            </div>
          </div>

          <div class="confirm-actions">
            <button class="secondary-button compact" type="button" @click="closeProfileImageCropper">Cancel</button>
            <button class="primary-button compact" type="button" @click="applyProfileImageCrop">
              Use Cropped Image
            </button>
          </div>
        </section>
      </div>
    </section>

    <section v-else-if="page === 'users'" class="users-page">
      <aside class="sidebar">
        <div class="brand">
          <div class="brand-mark">CP</div>
          <div>
            <strong>Care Portal</strong>
            <span>Simulator Users</span>
          </div>
        </div>
        <button class="nav-button" type="button" @click="goTo('/welcome')">Welcome</button>
        <button class="nav-button" type="button" @click="goTo('/profile')">Profile</button>
        <button class="nav-button active" type="button" @click="goTo('/users')">Users</button>
      </aside>

      <section class="workspace">
        <header class="workspace-header">
          <h1>Simulator App Users</h1>
          <div class="header-actions">
            <section class="live-clock" aria-label="Live clock">
              <div class="live-clock-main">
                <strong>{{ clockTime.hours }}</strong>
                <span>:</span>
                <strong>{{ clockTime.minutes }}</strong>
                <em>{{ clockTime.period }}</em>
              </div>
              <div class="live-clock-meta">
                <span>{{ clockTime.seconds }} sec</span>
                <span>{{ clockTime.date }}</span>
              </div>
            </section>
            <button v-if="loggedInUser" class="profile-trigger" type="button" @click="goTo('/profile')">
              <span class="avatar small">
                <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </span>
              <span>{{ loggedInUser.nickname }}</span>
            </button>
            <button class="link-button" type="button" @click="logOut">Log Out</button>
          </div>
        </header>

        <section class="table-panel">
          <div class="table-heading">
            <div>
              <p class="eyebrow">Admin</p>
              <h2>Current Parent Users</h2>
            </div>
            <div class="table-actions">
              <button class="secondary-button compact" type="button" @click="openCreateUserModal">
                <Plus :size="18" aria-hidden="true" />
                <span>Create User</span>
              </button>
              <button class="primary-button compact" type="button" @click="loadUsers" :disabled="isLoadingUsers">
                {{ isLoadingUsers ? 'Loading...' : 'Refresh' }}
              </button>
            </div>
          </div>

          <p v-if="usersMessage" class="message error">{{ usersMessage }}</p>

          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Nickname</th>
                  <th>Email</th>
                  <th>Created Time</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="!isLoadingUsers && users.length === 0">
                  <td colspan="4" class="empty-cell">No users found.</td>
                </tr>
                <tr v-for="user in users" :key="user.id">
                  <td>
                    <div class="user-cell">
                      <span class="avatar tiny">
                        <img v-if="user.profileImage" :src="user.profileImage" alt="" />
                        <span v-else>{{ userInitials(user) }}</span>
                      </span>
                      <button class="text-action parent-name-button" type="button" @click="openParentDetail(user)">
                        {{ user.nickname }}
                      </button>
                      <span v-if="user.isBlocked" class="status-pill blocked">Blocked</span>
                    </div>
                  </td>
                  <td>{{ user.email }}</td>
                  <td>{{ user.createdAt }}</td>
                  <td>
                    <div class="row-actions">
                      <button class="text-action" type="button" @click="openEditUserModal(user)">
                        <Pencil :size="16" aria-hidden="true" />
                        <span>Edit</span>
                      </button>
                      <button class="text-action danger" type="button" @click="openDeleteUserModal(user)">
                        <Trash2 :size="16" aria-hidden="true" />
                        <span>Delete</span>
                      </button>
                      <button
                        class="text-action"
                        :class="{ success: user.isBlocked }"
                        type="button"
                        @click="openBlockUserModal(user)"
                      >
                        <ShieldCheck v-if="user.isBlocked" :size="16" aria-hidden="true" />
                        <Ban v-else :size="16" aria-hidden="true" />
                        <span>{{ user.isBlocked ? 'Unblock' : 'Block' }}</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="table-footer">
            Total {{ users.length }}
          </div>
        </section>
      </section>

      <div v-if="isParentDetailOpen" class="modal-backdrop parent-detail-backdrop" @click.self="closeParentDetail">
        <section class="modal-panel parent-detail-panel" role="dialog" aria-modal="true" aria-labelledby="parent-detail-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">Parent User</p>
              <h2 id="parent-detail-title">{{ selectedParentUser?.nickname }}</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close parent details" @click="closeParentDetail">
              X
            </button>
          </div>

          <p v-if="parentDetailMessage" class="message error">{{ parentDetailMessage }}</p>
          <p v-if="isLoadingParentDetail" class="message">Loading parent details...</p>

          <div v-if="parentDetail && !isLoadingParentDetail" class="parent-detail-grid">
            <div class="parent-detail-left">
              <section class="detail-section">
                <h3>Parent Account</h3>
                <dl class="detail-list">
                  <div>
                    <dt>Username</dt>
                    <dd>{{ parentDetail.user.nickname }}</dd>
                  </div>
                  <div>
                    <dt>Email</dt>
                    <dd>{{ parentDetail.user.email }}</dd>
                  </div>
                  <div>
                    <dt>Created</dt>
                    <dd>{{ parentDetail.user.createdAt }}</dd>
                  </div>
                  <div>
                    <dt>Last App Sync</dt>
                    <dd>{{ parentDetail.appDataUpdatedAt || 'Not synced yet' }}</dd>
                  </div>
                </dl>
              </section>

              <section class="detail-section">
                <h3>Child Information</h3>
                <div v-if="hasChildInfo(parentDetail.childProfile)" class="detail-list">
                  <div v-for="row in childInfoRows(parentDetail.childProfile)" :key="row.label">
                    <dt>{{ row.label }}</dt>
                    <dd>{{ row.value || '' }}</dd>
                  </div>
                </div>
                <p v-else class="empty-note">No child information synced yet.</p>
              </section>
            </div>

            <section class="detail-section parent-detail-history">
              <div class="history-filter-header">
                <div>
                  <h3>History</h3>
                  <p>{{ formatDateInputLabel(parentHistoryDateFilter) }}</p>
                </div>

                <div class="history-controls">
                  <button class="refresh-detail-button export-detail-button" type="button" @click="openParentExportPanel">
                    Export PDF
                  </button>

                  <button class="refresh-detail-button export-detail-button" type="button" @click="openParentAIReportPanel">
                    AI Report
                  </button>

                  <button class="refresh-detail-button" type="button" :disabled="isLoadingParentDetail" @click="refreshParentDetail">
                    Refresh
                  </button>

                  <label class="date-filter-control">
                    <span>Date</span>
                    <div class="date-stepper">
                      <button type="button" aria-label="Show previous day" @click="shiftParentHistoryDate(-1)">
                        <ChevronLeft :size="18" />
                      </button>
                      <input v-model="parentHistoryDateFilter" type="date" />
                      <button type="button" aria-label="Show next day" @click="shiftParentHistoryDate(1)">
                        <ChevronRight :size="18" />
                      </button>
                    </div>
                  </label>
                </div>
              </div>

              <div class="history-page-tabs" role="tablist" aria-label="Parent history pages">
                <button
                  v-for="historyPage in parentHistoryPages"
                  :key="historyPage.key"
                  type="button"
                  role="tab"
                  :aria-selected="parentHistoryPageFilter === historyPage.key"
                  :class="{ active: parentHistoryPageFilter === historyPage.key }"
                  @click="setParentHistoryPage(historyPage.key)"
                >
                  <span class="history-page-label">{{ historyPage.icon }} {{ historyPage.title }}</span>
                  <span class="history-page-count">{{ historyPage.count }}</span>
                </button>
              </div>

              <div v-if="parentHistoryPageFilter === 'nutrient'" class="nutrient-quota-card">
                <div>
                  <p class="eyebrow">Daily Estimate Quota</p>
                  <h4>{{ nutrientUsageSummary.used }} used · {{ nutrientUsageSummary.limit }} per day</h4>
                  <span>{{ formatDateInputLabel(parentHistoryDateFilter) }}</span>
                </div>

                <div class="nutrient-quota-control" aria-label="Nutrient estimate daily limit">
                  <input
                    v-model.number="nutrientLimitDraft"
                    type="number"
                    min="0"
                    max="20"
                    step="1"
                    aria-label="Daily nutrient estimate quota"
                    @keyup.enter="saveParentNutrientLimit"
                  />
                  <span>per day</span>
                  <button
                    type="button"
                    :disabled="isSavingNutrientLimit || String(nutrientLimitDraft) === String(nutrientDailyLimit)"
                    @click="saveParentNutrientLimit"
                  >
                    Save
                  </button>
                </div>

                <p v-if="nutrientLimitMessage" class="quota-message">{{ nutrientLimitMessage }}</p>
              </div>

              <div v-if="activeParentHistorySections.length" class="history-section-tabs">
                <button
                  type="button"
                  :class="{ active: parentHistorySectionFilter === 'all' }"
                  @click="parentHistorySectionFilter = 'all'"
                >
                  All
                  <span>{{ activeParentHistoryItemCount }}</span>
                </button>
                <button
                  v-for="section in activeParentHistorySections"
                  :key="section.key"
                  type="button"
                  :class="{ active: parentHistorySectionFilter === section.key }"
                  @click="parentHistorySectionFilter = section.key"
                >
                  {{ section.icon }} {{ section.title }}
                  <span>{{ historySectionCount(section) }}</span>
                </button>
              </div>

              <div v-if="visibleParentHistorySections.length" class="history-section-list">
                <article v-for="section in visibleParentHistorySections" :key="section.key" class="history-section-card">
                  <header>
                    <div>
                      <span class="history-section-icon">{{ section.icon }}</span>
                      <strong>{{ section.title }}</strong>
                    </div>
                    <span>{{ historySectionCount(section) }}</span>
                  </header>

                  <div v-if="section.key === 'medicine'" class="medicine-history-list">
                    <div v-if="summarizedMedicineRows(section.logs).length" class="medicine-check-grid">
                      <div v-for="row in summarizedMedicineRows(section.logs)" :key="`${row.time}-${row.name}`" class="medicine-check-row">
                        <span class="medicine-check-emoji">{{ row.checked ? '✅' : '⬜' }}</span>
                        <span class="medicine-check-name">
                          {{ row.name }}
                          <span class="medicine-edit-times">
                            <span v-for="editTime in row.editTimes" :key="editTime">({{ editTime }})</span>
                          </span>
                        </span>
                        <time>{{ row.time }}</time>
                      </div>
                    </div>
                    <p v-else class="empty-note">No medicine checklist synced.</p>
                  </div>

                  <div v-else-if="section.key === 'nutrition'" class="saved-meal-grid">
                    <article v-for="meal in section.meals" :key="meal.id || meal.savedAt" class="saved-meal-card">
                      <div class="saved-meal-body">
                        <div>
                          <strong>{{ formatLogTime(meal.savedAt) }}</strong>
                          <span>AI meal estimate</span>
                        </div>
                        <p class="saved-meal-metrics">{{ savedMealMetricText(meal) }}</p>
                        <p v-if="meal.estimate?.summary">{{ meal.estimate.summary }}</p>
                        <div v-if="savedMealList(meal.estimate?.recommendations).length" class="saved-meal-list">
                          <span>Recommendations</span>
                          <ul>
                            <li v-for="item in savedMealList(meal.estimate.recommendations)" :key="item">{{ item }}</li>
                          </ul>
                        </div>
                        <div v-if="savedMealList(meal.estimate?.notes).length" class="saved-meal-list">
                          <span>Notes</span>
                          <ul>
                            <li v-for="item in savedMealList(meal.estimate.notes)" :key="item">{{ item }}</li>
                          </ul>
                        </div>
                      </div>
                    </article>
                  </div>

                  <div v-else class="compact-history-list">
                    <div v-for="log in section.logs" :key="log.id" class="compact-history-item">
                      <div>
                        <strong>{{ formatLogTime(log.timestamp) }}</strong>
                        <span>{{ logTypeLabel(log) }}</span>
                      </div>
                      <span v-if="logHasIntensityBar(log)" class="severity-pill">{{ log.severity }}/5</span>
                      <p v-if="log.value">{{ log.value }}</p>
                      <p v-if="log.comments">{{ log.comments }}</p>
                    </div>
                  </div>
                </article>
              </div>
              <p v-else-if="hasParentHistoryForDate || hasAnyParentHistory" class="empty-note">
                No {{ activeParentHistoryPageTitle.toLowerCase() }} history for {{ formatDateInputLabel(parentHistoryDateFilter) }}.
              </p>
              <p v-else class="empty-note">No history synced yet.</p>
            </section>
          </div>
        </section>
      </div>

      <div v-if="isParentExportOpen" class="modal-backdrop" @click.self="closeParentExportPanel">
        <section class="modal-panel export-panel" role="dialog" aria-modal="true" aria-labelledby="export-parent-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">PDF Export</p>
              <h2 id="export-parent-title">Export Parent History</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close export options" @click="closeParentExportPanel">
              X
            </button>
          </div>

          <div class="export-form">
            <div class="export-date-grid">
              <label>
                Start Date
                <input v-model="parentExportFilters.startDate" type="date" />
              </label>
              <label>
                End Date
                <input v-model="parentExportFilters.endDate" type="date" />
              </label>
            </div>

            <section class="export-option-group">
              <h3>Pages to Include</h3>
              <div class="export-checkbox-grid">
                <label>
                  <input v-model="parentExportFilters.includeHealth" type="checkbox" />
                  <span>Health</span>
                </label>
                <label>
                  <input v-model="parentExportFilters.includeTherapy" type="checkbox" />
                  <span>Therapy</span>
                </label>
                <label>
                  <input v-model="parentExportFilters.includeNutrient" type="checkbox" />
                  <span>Nutrient</span>
                </label>
              </div>
            </section>

            <section v-if="parentExportFilters.includeHealth" class="export-option-group">
              <div class="export-group-heading">
                <h3>Health History</h3>
                <div>
                  <button type="button" @click="selectAllParentExportHealthSections">Select all</button>
                  <button type="button" @click="clearParentExportHealthSections">Clear filters</button>
                </div>
              </div>
              <p class="export-help">
                Leave all categories unselected to include every health category in the date range.
              </p>
              <div v-if="availableParentExportHealthSections.length" class="export-checkbox-grid">
                <label v-for="section in availableParentExportHealthSections" :key="section.key">
                  <input v-model="parentExportFilters.healthSections" type="checkbox" :value="section.key" />
                  <span>{{ section.icon }} {{ section.title }}</span>
                </label>
              </div>
              <p v-else class="empty-note">No health categories found for this date range.</p>
            </section>

            <section class="export-summary-card">
              <strong>{{ parentExportItemCount }}</strong>
              <span>selected records</span>
              <small>{{ parentExportDateRangeLabel }}</small>
            </section>
          </div>

          <p v-if="parentExportMessage" class="message error">{{ parentExportMessage }}</p>

          <div class="confirm-actions">
            <button class="secondary-button compact" type="button" @click="closeParentExportPanel">Cancel</button>
            <button class="primary-button compact" type="button" @click="openParentExportPreview">
              Next: Preview
            </button>
          </div>
        </section>
      </div>

      <div v-if="isParentExportPreviewOpen" class="pdf-preview-backdrop">
        <div class="pdf-preview-toolbar">
          <div>
            <p class="eyebrow">Preview</p>
            <h2>PDF Export Preview</h2>
            <span>{{ parentExportDateRangeLabel }} · {{ parentExportItemCount }} records</span>
          </div>
          <div class="pdf-preview-actions">
            <button class="secondary-button compact" type="button" @click="backToParentExportOptions">Back</button>
            <button class="primary-button compact" type="button" @click="printParentReport">Export / Save PDF</button>
            <button class="icon-button" type="button" aria-label="Close PDF preview" @click="closeParentExportPreview">
              X
            </button>
          </div>
        </div>
      </div>

      <div v-if="isParentAIReportOpen" class="modal-backdrop" @click.self="closeParentAIReportPanel">
        <section class="modal-panel export-panel" role="dialog" aria-modal="true" aria-labelledby="ai-report-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">AI Analysis</p>
              <h2 id="ai-report-title">Create Admin Report</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close AI report options" @click="closeParentAIReportPanel">
              X
            </button>
          </div>

          <div class="export-form">
            <div class="export-date-grid">
              <label>
                Start Date
                <input v-model="parentAIReportFilters.startDate" type="date" />
              </label>
              <label>
                End Date
                <input v-model="parentAIReportFilters.endDate" type="date" />
              </label>
            </div>

            <section class="export-option-group">
              <h3>Report Language</h3>
              <div class="report-language-control" role="group" aria-label="AI report language">
                <button
                  type="button"
                  :class="{ active: parentAIReportFilters.language === 'english' }"
                  @click="parentAIReportFilters.language = 'english'"
                >
                  English PDF
                </button>
                <button
                  type="button"
                  :class="{ active: parentAIReportFilters.language === 'chinese' }"
                  @click="parentAIReportFilters.language = 'chinese'"
                >
                  中文 PDF
                </button>
              </div>
            </section>

            <section class="export-option-group">
              <h3>Pages to Analyze</h3>
              <div class="export-checkbox-grid">
                <label>
                  <input v-model="parentAIReportFilters.includeHealth" type="checkbox" />
                  <span>Health</span>
                </label>
                <label>
                  <input v-model="parentAIReportFilters.includeTherapy" type="checkbox" />
                  <span>Therapy</span>
                </label>
                <label>
                  <input v-model="parentAIReportFilters.includeNutrient" type="checkbox" />
                  <span>Nutrient</span>
                </label>
              </div>
            </section>

            <section v-if="parentAIReportFilters.includeHealth" class="export-option-group">
              <div class="export-group-heading">
                <h3>Health History</h3>
                <div>
                  <button type="button" @click="selectAllParentAIReportHealthSections">Select all</button>
                  <button type="button" @click="clearParentAIReportHealthSections">Clear filters</button>
                </div>
              </div>
              <p class="export-help">
                Leave all categories unselected to analyze every health category in the date range.
              </p>
              <div v-if="availableParentAIReportHealthSections.length" class="export-checkbox-grid">
                <label v-for="section in availableParentAIReportHealthSections" :key="section.key">
                  <input v-model="parentAIReportFilters.healthSections" type="checkbox" :value="section.key" />
                  <span>{{ section.icon }} {{ section.title }}</span>
                </label>
              </div>
              <p v-else class="empty-note">No health categories found for this date range.</p>
            </section>

            <section class="export-summary-card">
              <strong>{{ parentAIReportItemCount }}</strong>
              <span>records for AI analysis</span>
              <small>{{ parentAIReportDateRangeLabel }}</small>
            </section>
          </div>

          <p v-if="parentAIReportMessage" class="message error">{{ parentAIReportMessage }}</p>

          <div class="confirm-actions">
            <button class="secondary-button compact" type="button" @click="closeParentAIReportPanel">Cancel</button>
            <button class="primary-button compact" type="button" :disabled="isGeneratingParentAIReport" @click="generateParentAIReport">
              {{ isGeneratingParentAIReport ? 'Creating report...' : 'Next: Preview' }}
            </button>
          </div>
        </section>
      </div>

      <div v-if="isParentAIReportPreviewOpen" class="pdf-preview-backdrop">
        <div class="pdf-preview-toolbar">
          <div>
            <p class="eyebrow">Preview</p>
            <h2>AI Report Preview</h2>
            <span>{{ parentAIReport?.dateRange || parentAIReportDateRangeLabel }} · {{ parentAIReportMeta?.recordCount || 0 }} records</span>
          </div>
          <div class="pdf-preview-actions">
            <button class="secondary-button compact" type="button" @click="backToParentAIReportOptions">Back</button>
            <button class="primary-button compact" type="button" @click="printParentAIReport">Export / Save PDF</button>
            <button class="icon-button" type="button" aria-label="Close AI report preview" @click="closeParentAIReportPreview">
              X
            </button>
          </div>
        </div>
      </div>

      <section v-if="parentDetail" class="pdf-export-document" aria-label="Parent history PDF report">
        <header class="pdf-report-header">
          <p class="eyebrow">Care Portal Report</p>
          <h1>{{ parentDetail.user.nickname }}</h1>
          <p>{{ parentExportDateRangeLabel }}</p>
        </header>

        <div class="pdf-report-grid">
          <section class="pdf-report-card">
            <h2>Parent Account</h2>
            <dl>
              <div>
                <dt>Username</dt>
                <dd>{{ parentDetail.user.nickname }}</dd>
              </div>
              <div>
                <dt>Email</dt>
                <dd>{{ parentDetail.user.email }}</dd>
              </div>
              <div>
                <dt>Created</dt>
                <dd>{{ parentDetail.user.createdAt }}</dd>
              </div>
              <div>
                <dt>Last App Sync</dt>
                <dd>{{ parentDetail.appDataUpdatedAt || 'Not synced yet' }}</dd>
              </div>
            </dl>
          </section>

          <section class="pdf-report-card">
            <h2>Child Information</h2>
            <dl v-if="hasChildInfo(parentDetail.childProfile)">
              <div v-for="row in childInfoRows(parentDetail.childProfile)" :key="row.label">
                <dt>{{ row.label }}</dt>
                <dd>{{ row.value || '' }}</dd>
              </div>
            </dl>
            <p v-else>No child information synced yet.</p>
          </section>
        </div>

        <section class="pdf-report-history">
          <h2>History</h2>
          <p>{{ parentExportItemCount }} selected records</p>

          <article v-for="section in parentExportHistorySections" :key="`pdf-${section.key}`" class="pdf-history-section">
            <h3>{{ section.icon }} {{ section.title }} <span>{{ historySectionCount(section) }}</span></h3>

            <div v-if="section.key === 'medicine'" class="medicine-check-grid">
              <div v-for="row in summarizedMedicineRows(section.logs)" :key="`pdf-${row.time}-${row.name}`" class="medicine-check-row">
                <span class="medicine-check-emoji">{{ row.checked ? '✅' : '⬜' }}</span>
                <span class="medicine-check-name">
                  {{ row.name }}
                  <span class="medicine-edit-times">
                    <span v-for="editTime in row.editTimes" :key="`pdf-${row.name}-${editTime}`">({{ editTime }})</span>
                  </span>
                </span>
                <time>{{ row.time }}</time>
              </div>
            </div>

            <div v-else-if="section.key === 'nutrition'" class="saved-meal-grid">
              <article v-for="meal in section.meals" :key="`pdf-${meal.id || meal.savedAt}`" class="saved-meal-card">
                <div class="saved-meal-body">
                  <div>
                    <strong>{{ formatLogTimestamp(meal.savedAt) }}</strong>
                    <span>AI meal estimate</span>
                  </div>
                  <p class="saved-meal-metrics">{{ savedMealMetricText(meal) }}</p>
                  <p v-if="meal.estimate?.summary">{{ meal.estimate.summary }}</p>
                  <div v-if="savedMealList(meal.estimate?.recommendations).length" class="saved-meal-list">
                    <span>Recommendations</span>
                    <ul>
                      <li v-for="item in savedMealList(meal.estimate.recommendations)" :key="`pdf-rec-${item}`">{{ item }}</li>
                    </ul>
                  </div>
                  <div v-if="savedMealList(meal.estimate?.notes).length" class="saved-meal-list">
                    <span>Notes</span>
                    <ul>
                      <li v-for="item in savedMealList(meal.estimate.notes)" :key="`pdf-note-${item}`">{{ item }}</li>
                    </ul>
                  </div>
                </div>
              </article>
            </div>

            <div v-else class="compact-history-list">
              <div v-for="log in section.logs" :key="`pdf-${log.id}`" class="compact-history-item">
                <div>
                  <strong>{{ formatLogTimestamp(log.timestamp) }}</strong>
                  <span>{{ logTypeLabel(log) }}</span>
                </div>
                <span v-if="logHasIntensityBar(log)" class="severity-pill">{{ log.severity }}/5</span>
                <p v-if="log.value">{{ log.value }}</p>
                <p v-if="log.comments">{{ log.comments }}</p>
              </div>
            </div>
          </article>
        </section>
      </section>

      <section v-if="parentDetail && parentAIReport" class="ai-report-document" aria-label="Admin AI report">
        <header class="pdf-report-header">
          <p class="eyebrow">{{ parentAIReportLabels.reportEyebrow }}</p>
          <h1>{{ parentAIReport.title }}</h1>
          <p>{{ parentAIReport.dateRange }}</p>
        </header>

        <div class="pdf-report-grid">
          <section class="pdf-report-card">
            <h2>{{ parentAIReportLabels.parentAccount }}</h2>
            <dl>
              <div>
                <dt>{{ parentAIReportLabels.username }}</dt>
                <dd>{{ parentDetail.user.nickname }}</dd>
              </div>
              <div>
                <dt>{{ parentAIReportLabels.email }}</dt>
                <dd>{{ parentDetail.user.email }}</dd>
              </div>
              <div>
                <dt>{{ parentAIReportLabels.lastAppSync }}</dt>
                <dd>{{ parentDetail.appDataUpdatedAt || 'Not synced yet' }}</dd>
              </div>
            </dl>
          </section>

          <section class="pdf-report-card">
            <h2>{{ parentAIReportLabels.reportDetails }}</h2>
            <dl>
              <div>
                <dt>{{ parentAIReportLabels.recordsAnalyzed }}</dt>
                <dd>{{ parentAIReportMeta?.recordCount || 0 }}</dd>
              </div>
              <div>
                <dt>{{ parentAIReportLabels.generated }}</dt>
                <dd>{{ formatLogTimestamp(parentAIReportMeta?.generatedAt) }}</dd>
              </div>
            </dl>
          </section>
        </div>

        <section class="ai-report-card">
          <h2>{{ parentAIReportLabels.summary }}</h2>
          <p>{{ parentAIReport.summary }}</p>
        </section>

        <section class="ai-report-grid">
          <article class="ai-report-card">
            <h2>{{ parentAIReportLabels.highlights }}</h2>
            <ul v-if="parentAIReport.highlights?.length">
              <li v-for="item in parentAIReport.highlights" :key="`highlight-${item}`">{{ item }}</li>
            </ul>
            <p v-else>{{ parentAIReportLabels.noHighlights }}</p>
          </article>

          <article class="ai-report-card">
            <h2>{{ parentAIReportLabels.patterns }}</h2>
            <ul v-if="parentAIReport.patterns?.length">
              <li v-for="item in parentAIReport.patterns" :key="`pattern-${item}`">{{ item }}</li>
            </ul>
            <p v-else>{{ parentAIReportLabels.noPatterns }}</p>
          </article>

          <article class="ai-report-card">
            <h2>{{ parentAIReportLabels.concerns }}</h2>
            <ul v-if="parentAIReport.concerns?.length">
              <li v-for="item in parentAIReport.concerns" :key="`concern-${item}`">{{ item }}</li>
            </ul>
            <p v-else>{{ parentAIReportLabels.noConcerns }}</p>
          </article>

          <article class="ai-report-card">
            <h2>{{ parentAIReportLabels.recommendations }}</h2>
            <ul v-if="parentAIReport.recommendations?.length">
              <li v-for="item in parentAIReport.recommendations" :key="`recommendation-${item}`">{{ item }}</li>
            </ul>
            <p v-else>{{ parentAIReportLabels.noRecommendations }}</p>
          </article>

          <article class="ai-report-card">
            <h2>{{ parentAIReportLabels.dataQualityNotes }}</h2>
            <ul v-if="parentAIReport.dataQualityNotes?.length">
              <li v-for="item in parentAIReport.dataQualityNotes" :key="`data-quality-${item}`">{{ item }}</li>
            </ul>
            <p v-else>{{ parentAIReportLabels.noDataQualityNotes }}</p>
          </article>

          <article class="ai-report-card">
            <h2>{{ parentAIReportLabels.followUpQuestions }}</h2>
            <ul v-if="parentAIReport.followUpQuestions?.length">
              <li v-for="item in parentAIReport.followUpQuestions" :key="`question-${item}`">{{ item }}</li>
            </ul>
            <p v-else>{{ parentAIReportLabels.noFollowUpQuestions }}</p>
          </article>
        </section>

        <p class="ai-report-disclaimer">
          {{ parentAIReportLabels.disclaimer }}
        </p>
      </section>

      <div v-if="isCreateUserOpen" class="modal-backdrop" @click.self="closeCreateUserModal">
        <section class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="create-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">User</p>
              <h2 id="create-user-title">Create User</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close create user form" @click="closeCreateUserModal">
              X
            </button>
          </div>

          <form @submit.prevent="submitCreateUser">
            <div class="grid">
              <label>
                Make Nickname
                <input v-model="createUserForm.nickname" autocomplete="nickname" required />
              </label>
              <label>
                Email
                <input v-model="createUserForm.email" type="email" autocomplete="email" required />
              </label>
              <label>
                Password
                <input
                  v-model="createUserForm.password"
                  type="password"
                  autocomplete="new-password"
                  minlength="6"
                  pattern="(?=.*[0-9]).{6,}"
                  required
                />
              </label>
              <label>
                Verify Password
                <input
                  v-model="createUserForm.verifyPassword"
                  type="password"
                  autocomplete="new-password"
                  required
                />
              </label>
            </div>

            <button class="primary-button full" type="submit" :disabled="isCreatingUser">
              {{ isCreatingUser ? 'Creating user...' : 'Create User' }}
            </button>
          </form>

          <p v-if="createUserMessage" class="message" :class="{ error: createUserStatus === 'error' }">
            {{ createUserMessage }}
          </p>
        </section>
      </div>

      <div v-if="isEditUserOpen" class="modal-backdrop" @click.self="closeEditUserModal">
        <section class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="edit-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">User</p>
              <h2 id="edit-user-title">Edit User</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close edit user form" @click="closeEditUserModal">
              X
            </button>
          </div>

          <form @submit.prevent="submitEditUser">
            <div class="grid">
              <label>
                Nickname
                <input v-model="editUserForm.nickname" autocomplete="nickname" required />
              </label>
              <label>
                Email
                <input v-model="editUserForm.email" type="email" autocomplete="email" required />
              </label>
              <label class="full-field">
                New Password
                <input
                  v-model="editUserForm.password"
                  type="password"
                  autocomplete="new-password"
                  minlength="6"
                  pattern="(?=.*[0-9]).{6,}"
                  placeholder="Leave blank to keep current password"
                />
              </label>
            </div>

            <button class="primary-button full" type="submit" :disabled="isSavingUser">
              {{ isSavingUser ? 'Saving...' : 'Save Changes' }}
            </button>
          </form>

          <p v-if="editUserMessage" class="message" :class="{ error: editUserStatus === 'error' }">
            {{ editUserMessage }}
          </p>
        </section>
      </div>

      <div v-if="isDeleteUserOpen" class="modal-backdrop" @click.self="closeDeleteUserModal">
        <section class="modal-panel confirm-panel" role="dialog" aria-modal="true" aria-labelledby="delete-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">Delete</p>
              <h2 id="delete-user-title">Are you sure?</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close delete confirmation" @click="closeDeleteUserModal">
              X
            </button>
          </div>

          <p class="confirm-copy">
            This will permanently delete
            <strong>{{ userToDelete?.nickname }}</strong>
            from the database.
          </p>

          <div class="confirm-actions">
            <button class="secondary-button compact" type="button" @click="closeDeleteUserModal">Cancel</button>
            <button class="danger-button compact" type="button" :disabled="isDeletingUser" @click="confirmDeleteUser">
              {{ isDeletingUser ? 'Deleting...' : 'Delete User' }}
            </button>
          </div>

          <p v-if="deleteUserMessage" class="message error">{{ deleteUserMessage }}</p>
        </section>
      </div>

      <div v-if="isBlockUserOpen" class="modal-backdrop" @click.self="closeBlockUserModal">
        <section class="modal-panel confirm-panel" role="dialog" aria-modal="true" aria-labelledby="block-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">{{ userToBlock?.isBlocked ? 'Unblock' : 'Block' }}</p>
              <h2 id="block-user-title">{{ userToBlock?.nickname }}</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close block popup" @click="closeBlockUserModal">
              X
            </button>
          </div>

          <template v-if="userToBlock?.isBlocked">
            <p class="confirm-copy">
              This parent will be able to log into the simulator app again.
            </p>
          </template>

          <template v-else>
            <p class="confirm-copy">
              This keeps the account, but prevents the parent from logging into the simulator app.
            </p>

            <div class="block-options">
              <button
                class="choice-row"
                :class="{ selected: blockMode === 'indefinite' }"
                type="button"
                @click="blockMode = 'indefinite'"
              >
                <span>Until unblocked</span>
                <strong>Admin must unblock</strong>
              </button>

              <button
                class="choice-row"
                :class="{ selected: blockMode === 'duration' }"
                type="button"
                @click="blockMode = 'duration'"
              >
                <span>Until date</span>
                <strong>{{ blockUntilDateLabel }}</strong>
              </button>

              <div v-if="blockMode === 'duration'" class="duration-controls">
                <label class="date-field">
                  <span>Unblock date</span>
                  <input v-model="blockUntilDate" type="date" />
                </label>
                <p class="duration-note">{{ blockLengthText }}</p>
              </div>
            </div>
          </template>

          <div class="confirm-actions">
            <button class="secondary-button compact" type="button" @click="closeBlockUserModal">Cancel</button>
            <button
              class="primary-button compact"
              :class="{ dangerish: !userToBlock?.isBlocked }"
              type="button"
              :disabled="isSavingBlockUser"
              @click="confirmBlockUser"
            >
              {{
                isSavingBlockUser
                  ? 'Saving...'
                  : userToBlock?.isBlocked
                    ? 'Unblock User'
                    : 'Block User'
              }}
            </button>
          </div>

          <p v-if="blockUserMessage" class="message error">{{ blockUserMessage }}</p>
        </section>
      </div>
    </section>

    <section v-else-if="page === 'login'" class="form-panel">
      <button class="back-button" type="button" @click="goTo('/')">Back</button>
      <h1>Admin Log In</h1>
      <form @submit.prevent="submitLogin">
        <label>
          Admin Username
          <input v-model="loginForm.username" autocomplete="username" required />
        </label>
        <label>
          Password
          <input v-model="loginForm.password" type="password" autocomplete="current-password" required />
        </label>
        <button class="primary-button full" type="submit" :disabled="isBusy">
          {{ isBusy ? 'Logging in...' : 'Log In' }}
        </button>
      </form>
      <p v-if="loginMessage" class="message" :class="{ error: loginStatus === 'error' }">
        {{ loginMessage }}
      </p>
    </section>

    <section v-else class="form-panel wide">
      <button class="back-button" type="button" @click="goTo('/')">Back</button>
      <h1>Sign Up</h1>
      <form @submit.prevent="submitSignup">
        <div class="grid">
          <label>
            Make Nickname
            <input v-model="signupForm.nickname" autocomplete="nickname" required />
          </label>
          <label>
            Email
            <input v-model="signupForm.email" type="email" autocomplete="email" required />
          </label>
          <label>
            Password
            <input
              v-model="signupForm.password"
              type="password"
              autocomplete="new-password"
              minlength="6"
              pattern="(?=.*[0-9]).{6,}"
              required
            />
          </label>
          <label>
            Verify Password
            <input v-model="signupForm.verifyPassword" type="password" autocomplete="new-password" required />
          </label>
        </div>

        <button class="primary-button full" type="submit" :disabled="isBusy">
          {{ isBusy ? 'Creating account...' : 'Create Account' }}
        </button>
      </form>
      <p v-if="signupMessage" class="message" :class="{ error: signupStatus === 'error' }">
        {{ signupMessage }}
      </p>
    </section>
  </main>
</template>
