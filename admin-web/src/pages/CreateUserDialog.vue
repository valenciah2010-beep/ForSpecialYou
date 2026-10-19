<script setup>
import { usePortalContext } from "../utils/portalContext.js";

const {
  closeCreateUserModal,
  createUserForm,
  createUserMessage,
  createUserStatus,
  isCreateUserOpen,
  isCreatingUser,
  submitCreateUser,
} = usePortalContext();
</script>

<template>
  <div
    v-if="isCreateUserOpen"
    class="modal-backdrop"
    @click.self="closeCreateUserModal"
  >
    <section
      class="modal-panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="create-user-title"
    >
      <div class="modal-header">
        <div>
          <p class="eyebrow">User</p>
          <h2 id="create-user-title">Create User</h2>
        </div>
        <button
          class="icon-button"
          type="button"
          aria-label="Close create user form"
          @click="closeCreateUserModal"
        >
          X
        </button>
      </div>

      <form @submit.prevent="submitCreateUser">
        <div class="grid">
          <label>
            Make Nickname
            <input
              v-model="createUserForm.nickname"
              autocomplete="nickname"
              required
            />
          </label>
          <label>
            Email
            <input
              v-model="createUserForm.email"
              type="email"
              autocomplete="email"
              required
            />
          </label>
          <label>
            Password
            <input
              v-model="createUserForm.password"
              type="password"
              autocomplete="new-password"
              minlength="6"
              pattern="(?=.*[0-9]).{6,}"
              required
            />
          </label>
          <label>
            Verify Password
            <input
              v-model="createUserForm.verifyPassword"
              type="password"
              autocomplete="new-password"
              required
            />
          </label>
        </div>

        <button
          class="primary-button full"
          type="submit"
          :disabled="isCreatingUser"
        >
          {{ isCreatingUser ? "Creating user..." : "Create User" }}
        </button>
      </form>

      <p
        v-if="createUserMessage"
        class="message"
        :class="{ error: createUserStatus === 'error' }"
      >
        {{ createUserMessage }}
      </p>
    </section>
  </div>
</template>
