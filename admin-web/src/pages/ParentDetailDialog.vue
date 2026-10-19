<script setup>
import { usePortalContext } from "../utils/portalContext.js";
import ParentHistoryPanel from "../components/ParentHistoryPanel.vue";
const {
  activeParentHistoryItemCount,
  activeParentHistoryPageTitle,
  activeParentHistorySections,
  closeParentDetail,
  hasAnyParentHistory,
  hasParentHistoryForDate,
  isLoadingParentDetail,
  isParentDetailOpen,
  isSavingNutrientLimit,
  nutrientDailyLimit,
  nutrientLimitDraft,
  nutrientLimitMessage,
  nutrientUsageSummary,
  openParentAiReportPanel,
  openParentExportPanel,
  page,
  parentDetail,
  parentDetailMessage,
  parentHistoryDateFilter,
  parentHistoryPageFilter,
  parentHistoryPages,
  parentHistorySectionFilter,
  selectedParentUser,
  saveParentNutrientLimit,
  setParentHistoryPage,
  shiftParentHistoryDate,
  visibleParentHistorySections,
  refreshParentDetail,
} = usePortalContext();
</script>

<template>
  <div
    v-if="isParentDetailOpen"
    class="modal-backdrop parent-detail-backdrop"
    @click.self="closeParentDetail"
  >
    <section
      class="modal-panel parent-detail-panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="parent-detail-title"
    >
      <div class="modal-header">
        <div>
          <p class="eyebrow">Parent User</p>
          <h2 id="parent-detail-title">{{ selectedParentUser?.nickname }}</h2>
        </div>
        <button
          class="icon-button"
          type="button"
          aria-label="Close parent details"
          @click="closeParentDetail"
        >
          X
        </button>
      </div>

      <ParentHistoryPanel
        v-model:nutrient-limit-draft="nutrientLimitDraft"
        v-model:parent-history-date-filter="parentHistoryDateFilter"
        v-model:parent-history-section-filter="parentHistorySectionFilter"
        :active-parent-history-item-count="activeParentHistoryItemCount"
        :active-parent-history-page-title="activeParentHistoryPageTitle"
        :active-parent-history-sections="activeParentHistorySections"
        :has-any-parent-history="hasAnyParentHistory"
        :has-parent-history-for-date="hasParentHistoryForDate"
        :is-loading-parent-detail="isLoadingParentDetail"
        :is-saving-nutrient-limit="isSavingNutrientLimit"
        :nutrient-daily-limit="nutrientDailyLimit"
        :nutrient-limit-message="nutrientLimitMessage"
        :nutrient-usage-summary="nutrientUsageSummary"
        :parent-detail="parentDetail"
        :parent-detail-message="parentDetailMessage"
        :parent-history-page-filter="parentHistoryPageFilter"
        :parent-history-pages="parentHistoryPages"
        :visible-parent-history-sections="visibleParentHistorySections"
        @open-ai-report="openParentAiReportPanel"
        @open-export="openParentExportPanel"
        @refresh="refreshParentDetail"
        @save-nutrient-limit="saveParentNutrientLimit"
        @set-history-page="setParentHistoryPage"
        @shift-date="shiftParentHistoryDate"
      />
    </section>
  </div>
</template>
