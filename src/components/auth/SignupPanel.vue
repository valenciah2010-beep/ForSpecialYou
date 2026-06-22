<script setup>
defineProps({
  isBusy: { type: Boolean, required: true },
  signupMessage: { type: String, default: '' },
  signupStatus: { type: String, default: '' }
});

const signupForm = defineModel('signupForm', { required: true });
defineEmits(['submit']);
</script>

<template>
  <section class="form-panel wide">
    <p class="eyebrow">Care Portal</p>
    <h1>Create account</h1>
    <form @submit.prevent="$emit('submit')">
      <div class="grid">
        <label>
          Nickname
          <input v-model.trim="signupForm.nickname" type="text" autocomplete="username" />
        </label>
        <label>
          Email
          <input v-model.trim="signupForm.email" type="email" autocomplete="email" />
        </label>
        <label>
          Password
          <input v-model="signupForm.password" type="password" autocomplete="new-password" />
        </label>
        <label>
          Verify Password
          <input v-model="signupForm.verifyPassword" type="password" autocomplete="new-password" />
        </label>
      </div>
      <button class="primary-button form-submit-button" type="submit" :disabled="isBusy">
        {{ isBusy ? 'Creating...' : 'Create Account' }}
      </button>
    </form>
    <p v-if="signupMessage" class="message" :class="{ error: signupStatus === 'error' }">
      {{ signupMessage }}
    </p>
  </section>
</template>
