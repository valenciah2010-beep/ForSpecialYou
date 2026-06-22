<script setup>
defineProps({
  activePage: { type: String, required: true },
  canManageUsers: { type: Boolean, required: true },
  clockTime: { type: Object, required: true },
  loggedInUser: { type: Object, default: null },
  title: { type: String, required: true },
  userInitials: { type: Function, required: true }
});

defineEmits(['logout', 'navigate']);
</script>

<template>
  <section class="users-page">
    <aside class="sidebar">
      <div class="brand">
        <div class="brand-mark">CP</div>
        <div>
          <strong>Care Portal</strong>
          <span>{{ title }}</span>
        </div>
      </div>
      <button class="nav-button" :class="{ active: activePage === 'welcome' }" type="button" @click="$emit('navigate', '/welcome')">
        Welcome
      </button>
      <button class="nav-button" :class="{ active: activePage === 'profile' }" type="button" @click="$emit('navigate', '/profile')">
        Profile
      </button>
      <button v-if="canManageUsers" class="nav-button" :class="{ active: activePage === 'users' }" type="button" @click="$emit('navigate', '/users')">
        Users
      </button>
    </aside>

    <section class="workspace">
      <header class="workspace-header">
        <h1>{{ title }}</h1>
        <div class="header-actions">
          <section class="live-clock" aria-label="Live clock">
            <div class="live-clock-main">
              <strong>{{ clockTime.hours }}</strong>
              <span>:</span>
              <strong>{{ clockTime.minutes }}</strong>
              <em>{{ clockTime.period }}</em>
            </div>
            <div class="live-clock-meta">
              <span>{{ clockTime.seconds }} sec</span>
              <span>{{ clockTime.date }}</span>
            </div>
          </section>
          <button v-if="loggedInUser" class="profile-trigger" type="button" @click="$emit('navigate', '/profile')">
            <span class="avatar small">
              <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
              <span v-else>{{ userInitials(loggedInUser) }}</span>
            </span>
            <span>{{ loggedInUser.nickname }}</span>
          </button>
          <button class="link-button" type="button" @click="$emit('logout')">Log Out</button>
        </div>
      </header>

      <slot />
    </section>
  </section>
</template>
