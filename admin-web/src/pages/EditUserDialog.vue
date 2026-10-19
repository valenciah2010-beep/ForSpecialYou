<script setup>
import { usePortalContext } from "../utils/portalContext.js";

const {
  closeEditUserModal,
  editUserForm,
  editUserMessage,
  editUserStatus,
  isEditUserOpen,
  isSavingUser,
  submitEditUser,
} = usePortalContext();
</script>

<template>
  <div
    v-if="isEditUserOpen"
    class="modal-backdrop"
    @click.self="closeEditUserModal"
  >
    <section
      class="modal-panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="edit-user-title"
    >
      <div class="modal-header">
        <div>
          <p class="eyebrow">User</p>
          <h2 id="edit-user-title">Edit User</h2>
        </div>
        <button
          class="icon-button"
          type="button"
          aria-label="Close edit user form"
          @click="closeEditUserModal"
        >
          X
        </button>
      </div>

      <form @submit.prevent="submitEditUser">
        <div class="grid">
          <label>
            Nickname
            <input
              v-model="editUserForm.nickname"
              autocomplete="nickname"
              required
            />
          </label>
          <label>
            Email
            <input
              v-model="editUserForm.email"
              type="email"
              autocomplete="email"
              required
            />
          </label>
          <label class="full-field">
            New Password
            <input
              v-model="editUserForm.password"
              type="password"
              autocomplete="new-password"
              minlength="6"
              pattern="(?=.*[0-9]).{6,}"
              placeholder="Leave blank to keep current password"
            />
          </label>
        </div>

        <button
          class="primary-button full"
          type="submit"
          :disabled="isSavingUser"
        >
          {{ isSavingUser ? "Saving..." : "Save Changes" }}
        </button>
      </form>

      <p
        v-if="editUserMessage"
        class="message"
        :class="{ error: editUserStatus === 'error' }"
      >
        {{ editUserMessage }}
      </p>
    </section>
  </div>
</template>
