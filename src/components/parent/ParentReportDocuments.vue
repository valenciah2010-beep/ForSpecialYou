<script setup>
import { formatLogTimestamp } from '../../utils/date.js';
import {
  childInfoRows,
  hasChildInfo,
  historySectionCount,
  logHasIntensityBar,
  logTypeLabel,
  savedMealList,
  savedMealMetricText,
  summarizedMedicineRows
} from '../../utils/history.js';

defineProps({
  parentAIReport: { type: Object, default: null },
  parentAIReportLabels: { type: Object, required: true },
  parentAIReportMeta: { type: Object, default: null },
  parentDetail: { type: Object, default: null },
  parentExportDateRangeLabel: { type: String, required: true },
  parentExportHistorySections: { type: Array, required: true },
  parentExportItemCount: { type: Number, required: true }
});
</script>

<template>
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
</template>
