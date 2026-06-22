<script setup>
defineEmits(['navigate']);
</script>

<template>
  <section class="home-panel">
    <p class="eyebrow">Care Portal</p>
    <h1>Admin access</h1>
    <p class="intro">
      Sign in with an admin account to view simulator app users.
    </p>
    <div class="actions">
      <button class="primary-button" type="button" @click="$emit('navigate', '/login')">Admin Log In</button>
    </div>
  </section>
</template>
