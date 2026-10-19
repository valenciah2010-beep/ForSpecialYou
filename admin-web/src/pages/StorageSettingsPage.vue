<script setup>
import { nextTick, ref, watch } from "vue";
import { Archive, Clock3 } from "@lucide/vue";
import { usePortalContext } from "../utils/portalContext.js";
import { useStorageSettings } from "../composables/useStorageSettings.js";
import PortalLayout from "../components/layout/PortalLayout.vue";
import RetentionPeriodCard from "../components/storage/RetentionPeriodCard.vue";
import "../styles/storage-settings.css";
const { canManageUsers, clockTime, goTo, loggedInUser, logOut, userInitials } =
  usePortalContext();
const {
  incompleteHours,
  completedDays,
  usage,
  applyToExisting,
  loading,
  saving,
  error,
  message,
  confirmationOpen,
  changed,
  valid,
  policy,
  load,
  submit,
  save,
} = useStorageSettings();
const dialogPanel = ref(null);
const saveButton = ref(null);
watch(confirmationOpen, async (open) => {
  await nextTick();
  if (open) dialogPanel.value?.querySelector("button")?.focus();
  else saveButton.value?.focus();
});
function trapDialogFocus(event) {
  const buttons = [
    ...dialogPanel.value.querySelectorAll("button:not(:disabled)"),
  ];
  if (!buttons.length) {
    event.preventDefault();
    return;
  }
  const first = buttons[0],
    last = buttons.at(-1);
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}
</script>

<template>
  <PortalLayout
    active-page="storage"
    title="Storage"
    :can-manage-users="canManageUsers"
    :clock-time="clockTime"
    :logged-in-user="loggedInUser"
    :user-initials="userInitials"
    @logout="logOut"
    @navigate="goTo"
  >
    <section
      class="table-panel storage-settings-panel"
      :aria-busy="loading || saving"
    >
      <div class="storage-settings-heading">
        <div>
          <p class="eyebrow">Files</p>
          <h2>Retention</h2>
        </div>
        <button
          type="button"
          class="secondary-button compact"
          :disabled="loading || saving"
          @click="load"
        >
          Reload
        </button>
      </div>
      <p v-if="loading" role="status">Loading settings…</p>
      <form v-else-if="policy" @submit.prevent="submit">
        <div class="retention-grid">
          <RetentionPeriodCard
            v-model="incompleteHours"
            label="Unfinished uploads"
            unit="hours"
            :max="720"
            :count="usage.incomplete"
            :disabled="saving"
            ><Clock3 :size="22"
          /></RetentionPeriodCard>
          <RetentionPeriodCard
            v-model="completedDays"
            label="Completed files"
            unit="days"
            :max="36500"
            :count="usage.completed"
            :disabled="saving"
            allow-permanent
            ><Archive :size="22"
          /></RetentionPeriodCard>
        </div>
        <div class="retention-scope">
          <label class="retention-checkbox"
            ><input
              v-model="applyToExisting"
              type="checkbox"
              :disabled="saving"
            />
            <span>Apply to existing active uploads and files</span></label
          >
          <p>
            {{
              applyToExisting
                ? "Recalculates from the original upload or completion time. Expired files are excluded."
                : "New uploads and future completions only. Existing deadlines stay unchanged."
            }}
          </p>
        </div>
        <div class="retention-footer">
          <p>
            Expired files are cleared hourly. Deleted files cannot be restored
            here.
          </p>
          <button
            ref="saveButton"
            class="primary-button"
            type="submit"
            :disabled="saving || !changed || !valid"
          >
            {{ saving ? "Saving…" : "Save changes" }}
          </button>
        </div>
      </form>
      <p v-if="error" class="message error" role="alert">{{ error }}</p>
      <p v-if="message" class="message" role="status">{{ message }}</p>
    </section>
    <div
      v-if="confirmationOpen"
      class="modal-backdrop"
      @click.self="!saving && (confirmationOpen = false)"
    >
      <section
        ref="dialogPanel"
        class="modal-panel retention-confirm"
        role="dialog"
        aria-modal="true"
        aria-labelledby="retention-confirm-title"
        @keydown.esc="!saving && (confirmationOpen = false)"
        @keydown.tab="trapDialogFocus"
      >
        <h2 id="retention-confirm-title">Update existing files?</h2>
        <p>
          Deadlines will be recalculated from their original upload or
          completion time. Shorter durations can make files expire immediately
          and be deleted during cleanup.
        </p>
        <div class="confirm-actions">
          <button
            type="button"
            class="secondary-button compact"
            :disabled="saving"
            @click="confirmationOpen = false"
          >
            Cancel
          </button>
          <button
            type="button"
            class="primary-button compact"
            :disabled="saving"
            @click="save"
          >
            {{ saving ? "Saving…" : "Apply changes" }}
          </button>
        </div>
      </section>
    </div>
  </PortalLayout>
</template>
