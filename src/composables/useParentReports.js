import { computed, nextTick, ref } from 'vue';
import { apiFetch } from '../api/client.js';
import { dateInputValue, formatDateInputLabel, logDateInputValue, logTimestampMs, timestampInDateRange } from '../utils/date.js';
import { buildParentHistorySections, historyPageKey, historySectionCount, historySectionIcon, historySectionKey, historySectionTitle } from '../utils/history.js';
import { clamp } from '../utils/validation.js';

function defaultReportFilters(defaultDate, extraFields = {}) {
  return {
    startDate: defaultDate,
    endDate: defaultDate,
    includeHealth: true,
    includeTherapy: true,
    includeNutrient: true,
    healthSections: [],
    ...extraFields
  };
}

export function useParentReports() {
  const isParentDetailOpen = ref(false);
  const isParentExportOpen = ref(false);
  const isParentExportPreviewOpen = ref(false);
  const isPrintingParentReport = ref(false);
  const isParentAIReportOpen = ref(false);
  const isParentAIReportPreviewOpen = ref(false);
  const isGeneratingParentAIReport = ref(false);
  const isPrintingParentAIReport = ref(false);
  const selectedParentUser = ref(null);
  const parentDetail = ref(null);
  const parentDetailMessage = ref('');
  const isLoadingParentDetail = ref(false);
  const parentHistoryDateFilter = ref('');
  const parentHistoryPageFilter = ref('health');
  const parentHistorySectionFilter = ref('all');
  const parentExportMessage = ref('');
  const parentExportFilters = ref(defaultReportFilters(''));
  const parentAIReportMessage = ref('');
  const parentAIReport = ref(null);
  const parentAIReportMeta = ref(null);
  const parentAIReportFilters = ref(defaultReportFilters('', { language: 'english' }));
  const isSavingNutrientLimit = ref(false);
  const nutrientLimitDraft = ref('3');
  const nutrientLimitMessage = ref('');

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
  const availableParentExportHealthSections = computed(() => healthSectionsForRange(parentExportFilters.value));
  const availableParentAIReportHealthSections = computed(() => healthSectionsForRange(parentAIReportFilters.value));
  const parentExportHistorySections = computed(() => selectedHistorySections(parentExportFilters.value));
  const parentExportItemCount = computed(() => (
    parentExportHistorySections.value.reduce((total, section) => total + historySectionCount(section), 0)
  ));
  const parentExportDateRangeLabel = computed(() => dateRangeLabel(parentExportFilters.value));
  const parentAIReportHistorySections = computed(() => selectedHistorySections(parentAIReportFilters.value));
  const parentAIReportItemCount = computed(() => (
    parentAIReportHistorySections.value.reduce((total, section) => total + historySectionCount(section), 0)
  ));
  const parentAIReportDateRangeLabel = computed(() => dateRangeLabel(parentAIReportFilters.value));
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

  function healthSectionsForRange(filters) {
    const sectionMap = new Map();
    const logs = parentDetail.value?.healthLogs || [];

    logs
      .filter((log) => historyPageKey(log) === 'health')
      .filter((log) => timestampInDateRange(log.timestamp, filters.startDate, filters.endDate))
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
  }

  function selectedHistorySections(filters) {
    if (!parentDetail.value) return [];

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
  }

  function dateRangeLabel(filters) {
    const start = filters.startDate;
    const end = filters.endDate;

    if (start && end && start !== end) {
      return `${formatDateInputLabel(start)} - ${formatDateInputLabel(end)}`;
    }

    return formatDateInputLabel(start || end || dateInputValue(new Date()));
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
    parentExportFilters.value = defaultReportFilters(defaultDate);
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
    parentAIReportFilters.value = defaultReportFilters(defaultDate, { language: 'english' });
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

  return {
    activeParentHistoryItemCount,
    activeParentHistoryPageTitle,
    activeParentHistorySections,
    availableParentAIReportHealthSections,
    availableParentExportHealthSections,
    backToParentAIReportOptions,
    backToParentExportOptions,
    clearParentAIReportHealthSections,
    clearParentExportHealthSections,
    closeParentAIReportPanel,
    closeParentAIReportPreview,
    closeParentDetail,
    closeParentExportPanel,
    closeParentExportPreview,
    filteredParentHealthLogs,
    filteredParentHistoryLogs,
    filteredParentSavedMeals,
    filteredParentTherapyLogs,
    finishParentAIReportPrint,
    finishParentReportPrint,
    generateParentAIReport,
    hasAnyParentHistory,
    hasParentHistoryForDate,
    hasValidParentExportRange,
    isGeneratingParentAIReport,
    isLoadingParentDetail,
    isParentAIReportOpen,
    isParentAIReportPreviewOpen,
    isParentDetailOpen,
    isParentExportOpen,
    isParentExportPreviewOpen,
    isPrintingParentAIReport,
    isPrintingParentReport,
    isSavingNutrientLimit,
    nutrientDailyLimit,
    nutrientLimitDraft,
    nutrientLimitMessage,
    nutrientUsageSummary,
    openParentAIReportPanel,
    openParentDetail,
    openParentExportPanel,
    openParentExportPreview,
    parentAIReport,
    parentAIReportDateRangeLabel,
    parentAIReportFilters,
    parentAIReportHistorySections,
    parentAIReportItemCount,
    parentAIReportLabels,
    parentAIReportMessage,
    parentAIReportMeta,
    parentDetail,
    parentDetailMessage,
    parentExportDateRangeLabel,
    parentExportFilters,
    parentExportHistorySections,
    parentExportItemCount,
    parentExportMessage,
    parentHistoryDateFilter,
    parentHistoryPageFilter,
    parentHistoryPages,
    parentHistorySectionFilter,
    printParentAIReport,
    printParentReport,
    refreshParentDetail,
    resetParentAIReportFilters,
    resetParentExportFilters,
    saveParentNutrientLimit,
    selectAllParentAIReportHealthSections,
    selectAllParentExportHealthSections,
    selectedParentUser,
    setParentHistoryPage,
    shiftParentHistoryDate,
    validateParentAIReportSelection,
    validateParentExportSelection,
    visibleParentHistorySections
  };
}
