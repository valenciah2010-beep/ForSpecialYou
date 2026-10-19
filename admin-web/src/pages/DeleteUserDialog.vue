<script setup>
import { usePortalContext } from "../utils/portalContext.js";

const {
  closeDeleteUserModal,
  deleteUserMessage,
  isDeleteUserOpen,
  isDeletingUser,
  userToDelete,
  confirmDeleteUser,
} = usePortalContext();
</script>

<template>
  <div
    v-if="isDeleteUserOpen"
    class="modal-backdrop"
    @click.self="closeDeleteUserModal"
  >
    <section
      class="modal-panel confirm-panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="delete-user-title"
    >
      <div class="modal-header">
        <div>
          <p class="eyebrow">Delete</p>
          <h2 id="delete-user-title">Are you sure?</h2>
        </div>
        <button
          class="icon-button"
          type="button"
          aria-label="Close delete confirmation"
          @click="closeDeleteUserModal"
        >
          X
        </button>
      </div>

      <p class="confirm-copy">
        This will permanently delete
        <strong>{{ userToDelete?.nickname }}</strong>
        from the database.
      </p>

      <div class="confirm-actions">
        <button
          class="secondary-button compact"
          type="button"
          @click="closeDeleteUserModal"
        >
          Cancel
        </button>
        <button
          class="danger-button compact"
          type="button"
          :disabled="isDeletingUser"
          @click="confirmDeleteUser"
        >
          {{ isDeletingUser ? "Deleting..." : "Delete User" }}
        </button>
      </div>

      <p v-if="deleteUserMessage" class="message error">
        {{ deleteUserMessage }}
      </p>
    </section>
  </div>
</template>
