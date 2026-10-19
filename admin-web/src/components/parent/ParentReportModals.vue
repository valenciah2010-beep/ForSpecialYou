<script setup>
defineProps({
  availableParentAiReportHealthSections: { type: Array, required: true },
  availableParentExportHealthSections: { type: Array, required: true },
  isGeneratingParentAiReport: { type: Boolean, required: true },
  isParentAiReportOpen: { type: Boolean, required: true },
  isParentAiReportPreviewOpen: { type: Boolean, required: true },
  isParentExportOpen: { type: Boolean, required: true },
  isParentExportPreviewOpen: { type: Boolean, required: true },
  parentAiReport: { type: Object, default: null },
  parentAiReportDateRangeLabel: { type: String, required: true },
  parentAiReportItemCount: { type: Number, required: true },
  parentAiReportMessage: { type: String, default: "" },
  parentAiReportMeta: { type: Object, default: null },
  parentExportDateRangeLabel: { type: String, required: true },
  parentExportItemCount: { type: Number, required: true },
  parentExportMessage: { type: String, default: "" },
});

const parentExportFilters = defineModel("parentExportFilters", {
  required: true,
});
const parentAiReportFilters = defineModel("parentAiReportFilters", {
  required: true,
});

defineEmits([
  "back-to-ai-report-options",
  "back-to-export-options",
  "clear-ai-report-health-sections",
  "clear-export-health-sections",
  "close-ai-report-panel",
  "close-ai-report-preview",
  "close-export-panel",
  "close-export-preview",
  "generate-parent-ai-report",
  "open-export-preview",
  "print-parent-ai-report",
  "print-parent-report",
  "select-all-ai-report-health-sections",
  "select-all-export-health-sections",
]);
</script>

<template>
  <div
    v-if="isParentExportOpen"
    class="modal-backdrop"
    @click.self="$emit('close-export-panel')"
  >
    <section
      class="modal-panel export-panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="export-parent-title"
    >
      <div class="modal-header">
        <div>
          <p class="eyebrow">PDF Export</p>
          <h2 id="export-parent-title">Export Parent History</h2>
        </div>
        <button
          class="icon-button"
          type="button"
          aria-label="Close export options"
          @click="$emit('close-export-panel')"
        >
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
              <input
                v-model="parentExportFilters.includeHealth"
                type="checkbox"
              />
              <span>Health</span>
            </label>
            <label>
              <input
                v-model="parentExportFilters.includeTherapy"
                type="checkbox"
              />
              <span>Therapy</span>
            </label>
            <label>
              <input
                v-model="parentExportFilters.includeNutrient"
                type="checkbox"
              />
              <span>Nutrient</span>
            </label>
          </div>
        </section>

        <section
          v-if="parentExportFilters.includeHealth"
          class="export-option-group"
        >
          <div class="export-group-heading">
            <h3>Health History</h3>
            <div>
              <button
                type="button"
                @click="$emit('select-all-export-health-sections')"
              >
                Select all
              </button>
              <button
                type="button"
                @click="$emit('clear-export-health-sections')"
              >
                Clear filters
              </button>
            </div>
          </div>
          <p class="export-help">
            Leave all categories unselected to include every health category in
            the date range.
          </p>
          <div
            v-if="availableParentExportHealthSections.length"
            class="export-checkbox-grid"
          >
            <label
              v-for="section in availableParentExportHealthSections"
              :key="section.key"
            >
              <input
                v-model="parentExportFilters.healthSections"
                type="checkbox"
                :value="section.key"
              />
              <span>{{ section.icon }} {{ section.title }}</span>
            </label>
          </div>
          <p v-else class="empty-note">
            No health categories found for this date range.
          </p>
        </section>

        <section class="export-summary-card">
          <strong>{{ parentExportItemCount }}</strong>
          <span>selected records</span>
          <small>{{ parentExportDateRangeLabel }}</small>
        </section>
      </div>

      <p v-if="parentExportMessage" class="message error">
        {{ parentExportMessage }}
      </p>

      <div class="confirm-actions">
        <button
          class="secondary-button compact"
          type="button"
          @click="$emit('close-export-panel')"
        >
          Cancel
        </button>
        <button
          class="primary-button compact"
          type="button"
          @click="$emit('open-export-preview')"
        >
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
        <span
          >{{ parentExportDateRangeLabel }} ·
          {{ parentExportItemCount }} records</span
        >
      </div>
      <div class="pdf-preview-actions">
        <button
          class="secondary-button compact"
          type="button"
          @click="$emit('back-to-export-options')"
        >
          Back
        </button>
        <button
          class="primary-button compact"
          type="button"
          @click="$emit('print-parent-report')"
        >
          Export / Save PDF
        </button>
        <button
          class="icon-button"
          type="button"
          aria-label="Close PDF preview"
          @click="$emit('close-export-preview')"
        >
          X
        </button>
      </div>
    </div>
  </div>

  <div
    v-if="isParentAiReportOpen"
    class="modal-backdrop"
    @click.self="$emit('close-ai-report-panel')"
  >
    <section
      class="modal-panel export-panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="ai-report-title"
    >
      <div class="modal-header">
        <div>
          <p class="eyebrow">AI Analysis</p>
          <h2 id="ai-report-title">Create Admin Report</h2>
        </div>
        <button
          class="icon-button"
          type="button"
          aria-label="Close AI report options"
          @click="$emit('close-ai-report-panel')"
        >
          X
        </button>
      </div>

      <div class="export-form">
        <div class="export-date-grid">
          <label>
            Start Date
            <input v-model="parentAiReportFilters.startDate" type="date" />
          </label>
          <label>
            End Date
            <input v-model="parentAiReportFilters.endDate" type="date" />
          </label>
        </div>

        <section class="export-option-group">
          <h3>Report Language</h3>
          <div
            class="report-language-control"
            role="group"
            aria-label="AI report language"
          >
            <button
              type="button"
              :class="{ active: parentAiReportFilters.language === 'english' }"
              @click="parentAiReportFilters.language = 'english'"
            >
              English PDF
            </button>
            <button
              type="button"
              :class="{ active: parentAiReportFilters.language === 'chinese' }"
              @click="parentAiReportFilters.language = 'chinese'"
            >
              中文 PDF
            </button>
          </div>
        </section>

        <section class="export-option-group">
          <h3>Pages to Analyze</h3>
          <div class="export-checkbox-grid">
            <label>
              <input
                v-model="parentAiReportFilters.includeHealth"
                type="checkbox"
              />
              <span>Health</span>
            </label>
            <label>
              <input
                v-model="parentAiReportFilters.includeTherapy"
                type="checkbox"
              />
              <span>Therapy</span>
            </label>
            <label>
              <input
                v-model="parentAiReportFilters.includeNutrient"
                type="checkbox"
              />
              <span>Nutrient</span>
            </label>
          </div>
        </section>

        <section
          v-if="parentAiReportFilters.includeHealth"
          class="export-option-group"
        >
          <div class="export-group-heading">
            <h3>Health History</h3>
            <div>
              <button
                type="button"
                @click="$emit('select-all-ai-report-health-sections')"
              >
                Select all
              </button>
              <button
                type="button"
                @click="$emit('clear-ai-report-health-sections')"
              >
                Clear filters
              </button>
            </div>
          </div>
          <p class="export-help">
            Leave all categories unselected to analyze every health category in
            the date range.
          </p>
          <div
            v-if="availableParentAiReportHealthSections.length"
            class="export-checkbox-grid"
          >
            <label
              v-for="section in availableParentAiReportHealthSections"
              :key="section.key"
            >
              <input
                v-model="parentAiReportFilters.healthSections"
                type="checkbox"
                :value="section.key"
              />
              <span>{{ section.icon }} {{ section.title }}</span>
            </label>
          </div>
          <p v-else class="empty-note">
            No health categories found for this date range.
          </p>
        </section>

        <section class="export-summary-card">
          <strong>{{ parentAiReportItemCount }}</strong>
          <span>records for AI analysis</span>
          <small>{{ parentAiReportDateRangeLabel }}</small>
        </section>
      </div>

      <p v-if="parentAiReportMessage" class="message error">
        {{ parentAiReportMessage }}
      </p>

      <div class="confirm-actions">
        <button
          class="secondary-button compact"
          type="button"
          @click="$emit('close-ai-report-panel')"
        >
          Cancel
        </button>
        <button
          class="primary-button compact"
          type="button"
          :disabled="isGeneratingParentAiReport"
          @click="$emit('generate-parent-ai-report')"
        >
          {{
            isGeneratingParentAiReport ? "Creating report..." : "Next: Preview"
          }}
        </button>
      </div>
    </section>
  </div>

  <div v-if="isParentAiReportPreviewOpen" class="pdf-preview-backdrop">
    <div class="pdf-preview-toolbar">
      <div>
        <p class="eyebrow">Preview</p>
        <h2>AI Report Preview</h2>
        <span
          >{{ parentAiReport?.dateRange || parentAiReportDateRangeLabel }} ·
          {{ parentAiReportMeta?.recordCount || 0 }} records</span
        >
      </div>
      <div class="pdf-preview-actions">
        <button
          class="secondary-button compact"
          type="button"
          @click="$emit('back-to-ai-report-options')"
        >
          Back
        </button>
        <button
          class="primary-button compact"
          type="button"
          @click="$emit('print-parent-ai-report')"
        >
          Export / Save PDF
        </button>
        <button
          class="icon-button"
          type="button"
          aria-label="Close AI report preview"
          @click="$emit('close-ai-report-preview')"
        >
          X
        </button>
      </div>
    </div>
  </div>
</template>
