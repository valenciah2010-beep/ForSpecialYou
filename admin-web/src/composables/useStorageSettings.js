import { computed, onMounted, ref } from "vue";
import { apiFetch } from "../api/client.js";

export function useStorageSettings() {
  const policy = ref(null);
  const incompleteHours = ref(24);
  const completedDays = ref(30);
  const usage = ref({ incomplete: 0, completed: 0, permanent: 0 });
  const applyToExisting = ref(false);
  const loading = ref(false);
  const saving = ref(false);
  const error = ref("");
  const message = ref("");
  const confirmationOpen = ref(false);
  const changed = computed(
    () =>
      policy.value &&
      (incompleteHours.value !== policy.value.incompleteHours ||
        completedDays.value !== policy.value.completedDays ||
        applyToExisting.value),
  );
  const valid = computed(
    () =>
      Number.isInteger(incompleteHours.value) &&
      incompleteHours.value >= 1 &&
      incompleteHours.value <= 720 &&
      (completedDays.value === null ||
        (Number.isInteger(completedDays.value) &&
          completedDays.value >= 1 &&
          completedDays.value <= 36500)),
  );

  async function load() {
    loading.value = true;
    error.value = "";
    message.value = "";
    try {
      const response = await apiFetch("/api/admin/settings/storage");
      const data = await response.json();
      if (!response.ok)
        throw new Error(data.message || "Could not load storage settings.");
      policy.value = data.policy;
      incompleteHours.value = data.policy.incompleteHours;
      completedDays.value = data.policy.completedDays;
      usage.value = data.usage;
      applyToExisting.value = false;
    } catch (e) {
      error.value = e.message || "Could not reach the server.";
    } finally {
      loading.value = false;
    }
  }
  function submit() {
    error.value = "";
    message.value = "";
    if (!valid.value) {
      error.value = "Enter whole hours (1–720) and days (1–36500).";
      return;
    }
    if (!changed.value || saving.value) return;
    if (applyToExisting.value) confirmationOpen.value = true;
    else save();
  }
  async function save() {
    if (!valid.value || !policy.value || saving.value) return;
    saving.value = true;
    error.value = "";
    try {
      const response = await apiFetch("/api/admin/settings/storage", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          incompleteHours: incompleteHours.value,
          completedDays: completedDays.value,
          revision: policy.value.revision,
          applyToExisting: applyToExisting.value,
        }),
      });
      const data = await response.json();
      if (!response.ok)
        throw new Error(data.message || "Could not save storage settings.");
      policy.value = data.policy;
      applyToExisting.value = false;
      confirmationOpen.value = false;
      message.value = "Changes saved.";
      // Refresh counts without overwriting fields or losing a successful-save state.
      try {
        const refreshed = await apiFetch("/api/admin/settings/storage");
        if (refreshed.ok) usage.value = (await refreshed.json()).usage;
      } catch {
        /* The save is committed; a count refresh must not report it as failed. */
      }
    } catch (e) {
      error.value = e.message || "Could not reach the server.";
      confirmationOpen.value = false;
    } finally {
      saving.value = false;
    }
  }
  onMounted(load);
  return {
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
  };
}
