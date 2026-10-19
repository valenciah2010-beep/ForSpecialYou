<script setup>
import { usePortalContext } from "../utils/portalContext.js";
import PortalLayout from "../components/layout/PortalLayout.vue";
const {
  canManageUsers,
  clockTime,
  goTo,
  loggedInUser,
  logOut,
  page,
  userInitials,
  users,
} = usePortalContext();
</script>

<template>
  <PortalLayout
    active-page="welcome"
    :can-manage-users="canManageUsers"
    :clock-time="clockTime"
    :logged-in-user="loggedInUser"
    title="Welcome"
    :user-initials="userInitials"
    @logout="logOut"
    @navigate="goTo"
  >
    <section class="table-panel welcome-panel">
      <div class="welcome-hero">
        <p class="eyebrow">Care Portal Admin</p>
        <h2>Welcome{{ loggedInUser ? `, ${loggedInUser.nickname}` : "" }}</h2>
      </div>
      <div class="welcome-card-grid">
        <article class="welcome-card">
          <strong>{{ users.length }}</strong>
          <span>Synced parent accounts</span>
        </article>
        <article class="welcome-card">
          <strong>{{ clockTime.date }}</strong>
          <span>Current portal date</span>
        </article>
        <article class="welcome-card">
          <strong>Ready</strong>
          <span>Admin portal status</span>
        </article>
      </div>
      <div class="actions welcome-actions">
        <button class="primary-button" type="button" @click="goTo('/users')">
          View Parent Users
        </button>
        <button
          class="secondary-button"
          type="button"
          @click="goTo('/profile')"
        >
          Edit Profile
        </button>
      </div>
    </section>
  </PortalLayout>
</template>
