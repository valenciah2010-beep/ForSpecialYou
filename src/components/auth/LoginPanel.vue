<script setup>
defineProps({
  isBusy: { type: Boolean, required: true },
  loginMessage: { type: String, default: '' },
  loginStatus: { type: String, default: '' }
});

const loginForm = defineModel('loginForm', { required: true });
defineEmits(['submit']);
</script>

<template>
  <section class="form-panel">
    <p class="eyebrow">Care Portal</p>
    <h1>Admin login</h1>
    <form @submit.prevent="$emit('submit')">
      <label>
        Admin Username
        <input v-model.trim="loginForm.username" type="text" autocomplete="username" />
      </label>
      <label>
        Password
        <input v-model="loginForm.password" type="password" autocomplete="current-password" />
      </label>
      <button type="submit" :disabled="isBusy">
        {{ isBusy ? 'Logging in...' : 'Log In' }}
      </button>
    </form>
    <p v-if="loginMessage" class="message" :class="{ error: loginStatus === 'error' }">
      {{ loginMessage }}
    </p>
  </section>
</template>
