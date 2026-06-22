<script setup>
import { ChevronLeft, ChevronRight } from '@lucide/vue';
import { formatDateInputLabel, formatLogTime } from '../utils/date.js';
import {
  childInfoRows,
  hasChildInfo,
  historySectionCount,
  logHasIntensityBar,
  logTypeLabel,
  savedMealList,
  savedMealMetricText,
  summarizedMedicineRows
} from '../utils/history.js';

defineProps({
  activeParentHistoryItemCount: { type: Number, required: true },
  activeParentHistoryPageTitle: { type: String, required: true },
  activeParentHistorySections: { type: Array, required: true },
  hasAnyParentHistory: { type: Boolean, required: true },
  hasParentHistoryForDate: { type: Boolean, required: true },
  isLoadingParentDetail: { type: Boolean, required: true },
  isSavingNutrientLimit: { type: Boolean, required: true },
  nutrientDailyLimit: { type: Number, required: true },
  nutrientLimitMessage: { type: String, required: true },
  nutrientUsageSummary: { type: Object, required: true },
  parentDetail: { type: Object, default: null },
  parentDetailMessage: { type: String, default: '' },
  parentHistoryDateFilter: { type: String, required: true },
  parentHistoryPageFilter: { type: String, required: true },
  parentHistoryPages: { type: Array, required: true },
  parentHistorySectionFilter: { type: String, required: true },
  visibleParentHistorySections: { type: Array, required: true }
});

const nutrientLimitDraft = defineModel('nutrientLimitDraft');
const dateFilter = defineModel('parentHistoryDateFilter');
const sectionFilter = defineModel('parentHistorySectionFilter');

defineEmits([
  'open-ai-report',
  'open-export',
  'refresh',
  'save-nutrient-limit',
  'set-history-page',
  'shift-date'
]);
</script>

<template>
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
          <button class="refresh-detail-button export-detail-button" type="button" @click="$emit('open-export')">
            Export PDF
          </button>

          <button class="refresh-detail-button export-detail-button" type="button" @click="$emit('open-ai-report')">
            AI Report
          </button>

          <button class="refresh-detail-button" type="button" :disabled="isLoadingParentDetail" @click="$emit('refresh')">
            Refresh
          </button>

          <label class="date-filter-control">
            <span>Date</span>
            <div class="date-stepper">
              <button type="button" aria-label="Show previous day" @click="$emit('shift-date', -1)">
                <ChevronLeft :size="18" />
              </button>
              <input v-model="dateFilter" type="date" />
              <button type="button" aria-label="Show next day" @click="$emit('shift-date', 1)">
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
          @click="$emit('set-history-page', historyPage.key)"
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
            @keyup.enter="$emit('save-nutrient-limit')"
          />
          <span>per day</span>
          <button
            type="button"
            :disabled="isSavingNutrientLimit || String(nutrientLimitDraft) === String(nutrientDailyLimit)"
            @click="$emit('save-nutrient-limit')"
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
          @click="sectionFilter = 'all'"
        >
          All
          <span>{{ activeParentHistoryItemCount }}</span>
        </button>
        <button
          v-for="section in activeParentHistorySections"
          :key="section.key"
          type="button"
          :class="{ active: parentHistorySectionFilter === section.key }"
          @click="sectionFilter = section.key"
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
</template>
