<script setup>
import { usePortalContext } from "../utils/portalContext.js";

const {
  blockLengthText,
  blockMode,
  blockUntilDate,
  blockUntilDateLabel,
  blockUserMessage,
  closeBlockUserModal,
  confirmBlockUser,
  isBlockUserOpen,
  isSavingBlockUser,
  userToBlock,
} = usePortalContext();
</script>

<template>
  <div
    v-if="isBlockUserOpen"
    class="modal-backdrop"
    @click.self="closeBlockUserModal"
  >
    <section
      class="modal-panel confirm-panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="block-user-title"
    >
      <div class="modal-header">
        <div>
          <p class="eyebrow">
            {{ userToBlock?.isBlocked ? "Unblock" : "Block" }}
          </p>
          <h2 id="block-user-title">{{ userToBlock?.nickname }}</h2>
        </div>
        <button
          class="icon-button"
          type="button"
          aria-label="Close block popup"
          @click="closeBlockUserModal"
        >
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
          This keeps the account, but prevents the parent from logging into the
          simulator app.
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
        <button
          class="secondary-button compact"
          type="button"
          @click="closeBlockUserModal"
        >
          Cancel
        </button>
        <button
          class="primary-button compact"
          :class="{ dangerish: !userToBlock?.isBlocked }"
          type="button"
          :disabled="isSavingBlockUser"
          @click="confirmBlockUser"
        >
          {{
            isSavingBlockUser
              ? "Saving..."
              : userToBlock?.isBlocked
                ? "Unblock User"
                : "Block User"
          }}
        </button>
      </div>

      <p v-if="blockUserMessage" class="message error">
        {{ blockUserMessage }}
      </p>
    </section>
  </div>
</template>
