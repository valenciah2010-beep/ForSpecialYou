<script setup>
import { provide } from "vue";
import { Flower, Palette } from "@lucide/vue";
import { portalKey } from "./utils/portalContext.js";
import { useAdminPortal } from "./composables/useAdminPortal.js";
import HomePanel from "./components/HomePanel.vue";
import LoginPanel from "./components/auth/LoginPanel.vue";
import SignupPanel from "./components/auth/SignupPanel.vue";
import WelcomePage from "./pages/WelcomePage.vue";
import ProfilePage from "./pages/ProfilePage.vue";
import UsersPage from "./pages/UsersPage.vue";
import StorageSettingsPage from "./pages/StorageSettingsPage.vue";
const portal = useAdminPortal();
provide(portalKey, portal);
const {
  currentTheme,
  goTo,
  isBusy,
  isThemeMenuOpen,
  isParentAiReportPreviewOpen,
  isParentExportPreviewOpen,
  isPrintingParentAiReport,
  isPrintingParentReport,
  loginForm,
  loginMessage,
  loginStatus,
  page,
  setTheme,
  signupForm,
  signupMessage,
  signupStatus,
  submitLogin,
  submitSignup,
  themeOptions,
  users,
} = portal;
</script>

<template>
  <main
    class="shell"
    :class="{
      'printing-parent-report': isPrintingParentReport,
      'previewing-parent-report': isParentExportPreviewOpen,
      'printing-ai-report': isPrintingParentAiReport,
      'previewing-ai-report': isParentAiReportPreviewOpen,
    }"
    :data-theme="currentTheme"
  >
    <div class="theme-switcher">
      <button
        class="theme-toggle"
        type="button"
        aria-label="Open theme menu"
        :aria-expanded="isThemeMenuOpen"
        @click="isThemeMenuOpen = !isThemeMenuOpen"
      >
        <Palette :size="20" aria-hidden="true" />
      </button>
      <div
        v-if="isThemeMenuOpen"
        class="theme-menu"
        aria-label="Theme selector"
      >
        <button
          v-for="theme in themeOptions"
          :key="theme.value"
          class="theme-menu-item"
          :class="{ active: currentTheme === theme.value }"
          type="button"
          :style="{ '--theme-color': theme.color }"
          @click="setTheme(theme.value)"
        >
          <span class="theme-swatch">
            <Flower
              v-if="theme.icon === 'flower'"
              :size="16"
              aria-hidden="true"
            />
          </span>
          <span>{{ theme.label }}</span>
        </button>
      </div>
    </div>

    <HomePanel v-if="page === 'home'" @navigate="goTo" />

    <WelcomePage v-else-if="page === 'welcome'" />

    <ProfilePage v-else-if="page === 'profile'" />

    <UsersPage v-else-if="page === 'users'" />

    <StorageSettingsPage v-else-if="page === 'storage'" />

    <LoginPanel
      v-else-if="page === 'login'"
      v-model:login-form="loginForm"
      :is-busy="isBusy"
      :login-message="loginMessage"
      :login-status="loginStatus"
      @submit="submitLogin"
    />

    <SignupPanel
      v-else
      v-model:signup-form="signupForm"
      :is-busy="isBusy"
      :signup-message="signupMessage"
      :signup-status="signupStatus"
      @submit="submitSignup"
    />
  </main>
</template>
