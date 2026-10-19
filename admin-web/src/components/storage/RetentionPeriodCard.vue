<script setup>
import { ref, watch } from "vue";
const props = defineProps({
  modelValue: { type: Number, default: null },
  label: { type: String, required: true },
  unit: { type: String, required: true },
  max: { type: Number, required: true },
  count: { type: Number, default: 0 },
  allowPermanent: Boolean,
  disabled: Boolean,
});
const emit = defineEmits(["update:modelValue"]);
const lastValue = ref(props.modelValue ?? 30);
watch(
  () => props.modelValue,
  (value) => {
    if (Number.isFinite(value)) lastValue.value = value;
  },
);
</script>

<template>
  <section class="retention-card">
    <div class="retention-card-heading">
      <span class="retention-icon" aria-hidden="true"><slot /></span>
      <span class="retention-count">{{ count }} active</span>
    </div>
    <h3>{{ label }}</h3>
    <label v-if="allowPermanent" class="retention-mode">
      <span>Retention mode</span>
      <select
        :value="modelValue === null ? 'permanent' : 'limited'"
        :disabled="disabled"
        @change="
          emit(
            'update:modelValue',
            $event.target.value === 'permanent' ? null : lastValue,
          )
        "
      >
        <option value="limited">Set duration</option>
        <option value="permanent">Keep permanently</option>
      </select>
    </label>
    <label v-if="modelValue !== null" class="retention-duration">
      <span>Keep for</span>
      <span class="retention-input-row">
        <input
          :value="modelValue"
          type="number"
          min="1"
          :max="max"
          step="1"
          required
          :aria-label="`${label}: ${unit}`"
          :disabled="disabled"
          @input="
            emit(
              'update:modelValue',
              $event.target.value === '' ? NaN : Number($event.target.value),
            )
          "
        />
        <span>{{ unit }}</span>
      </span>
    </label>
    <p v-else class="retention-permanent">
      Until deleted by the user or administrator.
    </p>
    <p class="retention-caption">
      {{
        allowPermanent ? "From upload completion." : "From the start of upload."
      }}
    </p>
  </section>
</template>
