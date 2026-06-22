<script setup>
import { Ban, Flower, Palette, Pencil, Plus, ShieldCheck, Trash2 } from '@lucide/vue';
import HomePanel from './components/HomePanel.vue';
import ParentHistoryPanel from './components/ParentHistoryPanel.vue';
import ParentReportDocuments from './components/parent/ParentReportDocuments.vue';
import ParentReportModals from './components/parent/ParentReportModals.vue';
import PortalLayout from './components/layout/PortalLayout.vue';
import LoginPanel from './components/auth/LoginPanel.vue';
import SignupPanel from './components/auth/SignupPanel.vue';
import { useAdminPortal } from './composables/useAdminPortal.js';

const {
  activeParentHistoryItemCount,
  activeParentHistoryPageTitle,
  activeParentHistorySections,
  applyProfileImageCrop,
  availableParentAIReportHealthSections,
  availableParentExportHealthSections,
  backToParentAIReportOptions,
  backToParentExportOptions,
  blockLengthText,
  blockMode,
  blockUntilDate,
  blockUntilDateLabel,
  blockUserMessage,
  canManageUsers,
  clearParentAIReportHealthSections,
  clearParentExportHealthSections,
  closeBlockUserModal,
  closeCreateUserModal,
  closeDeleteUserModal,
  closeEditUserModal,
  closeParentAIReportPanel,
  closeParentAIReportPreview,
  closeParentDetail,
  closeParentExportPanel,
  closeParentExportPreview,
  closeProfileImageCropper,
  createUserForm,
  createUserMessage,
  createUserStatus,
  cropPreview,
  deleteUserMessage,
  editUserForm,
  editUserMessage,
  editUserStatus,
  goTo,
  handleProfileImageChange,
  hasAnyParentHistory,
  hasParentHistoryForDate,
  isBlockUserOpen,
  isBusy,
  isCreateUserOpen,
  isCreatingUser,
  isCropDragging,
  isCropperOpen,
  isDeleteUserOpen,
  isDeletingUser,
  isEditUserOpen,
  isGeneratingParentAIReport,
  isLoadingParentDetail,
  isLoadingUsers,
  isParentAIReportOpen,
  isParentAIReportPreviewOpen,
  isParentDetailOpen,
  isParentExportOpen,
  isParentExportPreviewOpen,
  isPrintingParentAIReport,
  isPrintingParentReport,
  isSavingBlockUser,
  isSavingNutrientLimit,
  isSavingProfile,
  isSavingUser,
  loggedInUser,
  loginForm,
  loginMessage,
  loginStatus,
  moveCropImage,
  nutrientDailyLimit,
  nutrientLimitDraft,
  nutrientLimitMessage,
  nutrientUsageSummary,
  openBlockUserModal,
  openCreateUserModal,
  openDeleteUserModal,
  openEditUserModal,
  openParentAIReportPanel,
  openParentExportPanel,
  openParentExportPreview,
  page,
  parentAIReport,
  parentAIReportDateRangeLabel,
  parentAIReportFilters,
  parentAIReportItemCount,
  parentAIReportLabels,
  parentAIReportMessage,
  parentAIReportMeta,
  parentDetail,
  parentDetailMessage,
  parentExportDateRangeLabel,
  parentExportFilters,
  parentExportHistorySections,
  parentExportItemCount,
  parentExportMessage,
  parentHistoryDateFilter,
  parentHistoryPageFilter,
  parentHistoryPages,
  parentHistorySectionFilter,
  profileForm,
  profileMessage,
  profileStatus,
  removeProfileImage,
  selectAllParentAIReportHealthSections,
  selectAllParentExportHealthSections,
  selectedParentUser,
  setParentHistoryPage,
  shiftParentHistoryDate,
  signupForm,
  signupMessage,
  signupStatus,
  startCropDrag,
  stopCropDrag,
  themeOptions,
  userInitials,
  users,
  usersMessage,
  userToBlock,
  userToDelete,
  visibleParentHistorySections,
  zoomCropImage
} = useAdminPortal();
</script>

<template>
  <main
    class="shell"
    :class="{
      'printing-parent-report': isPrintingParentReport,
      'previewing-parent-report': isParentExportPreviewOpen,
      'printing-ai-report': isPrintingParentAIReport,
      'previewing-ai-report': isParentAIReportPreviewOpen
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
      <div v-if="isThemeMenuOpen" class="theme-menu" aria-label="Theme selector">
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
            <Flower v-if="theme.icon === 'flower'" :size="16" aria-hidden="true" />
          </span>
          <span>{{ theme.label }}</span>
        </button>
      </div>
    </div>

    <HomePanel v-if="page === 'home'" @navigate="goTo" />

    <PortalLayout
      v-else-if="page === 'welcome'"
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
            <h2>Welcome{{ loggedInUser ? `, ${loggedInUser.nickname}` : '' }}</h2>
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
            <button class="primary-button" type="button" @click="goTo('/users')">View Parent Users</button>
            <button class="secondary-button" type="button" @click="goTo('/profile')">Edit Profile</button>
          </div>
        </section>
    </PortalLayout>

    <PortalLayout
      v-else-if="page === 'profile'"
      active-page="profile"
      :can-manage-users="canManageUsers"
      :clock-time="clockTime"
      :logged-in-user="loggedInUser"
      title="Profile"
      :user-initials="userInitials"
      @logout="logOut"
      @navigate="goTo"
    >
        <section class="table-panel profile-panel">
          <div class="profile-layout">
            <div class="profile-photo-card">
              <div class="avatar large">
                <img v-if="profileForm.profileImage" :src="profileForm.profileImage" alt="Profile preview" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </div>
              <label class="secondary-button compact upload-button">
                Change Image
                <input type="file" accept="image/*" @change="handleProfileImageChange" />
              </label>
              <button class="text-action danger" type="button" @click="removeProfileImage">Remove Image</button>
            </div>

            <form class="profile-form" @submit.prevent="submitProfile">
              <div class="grid">
                <label>
                  Nickname
                  <input v-model="profileForm.nickname" autocomplete="nickname" required />
                </label>
                <label>
                  Email
                  <input v-model="profileForm.email" type="email" autocomplete="email" required />
                </label>
                <label>
                  New Password
                  <input
                    v-model="profileForm.password"
                    type="password"
                    autocomplete="new-password"
                    minlength="6"
                    pattern="(?=.*[0-9]).{6,}"
                    placeholder="Leave blank to keep current password"
                  />
                </label>
              </div>

              <button class="primary-button full" type="submit" :disabled="isSavingProfile">
                {{ isSavingProfile ? 'Saving...' : 'Save Profile' }}
              </button>
            </form>
          </div>

          <p v-if="profileMessage" class="message" :class="{ error: profileStatus === 'error' }">
            {{ profileMessage }}
          </p>
        </section>

      <div v-if="isCropperOpen" class="modal-backdrop" @click.self="closeProfileImageCropper">
        <section class="modal-panel crop-panel" role="dialog" aria-modal="true" aria-labelledby="crop-image-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">Profile Image</p>
              <h2 id="crop-image-title">Crop Image</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close image cropper" @click="closeProfileImageCropper">
              X
            </button>
          </div>

          <div class="crop-layout">
            <div
              class="crop-preview-frame"
              :class="{ dragging: isCropDragging }"
              @pointerdown="startCropDrag"
              @pointermove="moveCropImage"
              @pointerup="stopCropDrag"
              @pointercancel="stopCropDrag"
              @lostpointercapture="stopCropDrag"
              @wheel.prevent="zoomCropImage"
            >
              <img v-if="cropPreview" :src="cropPreview" alt="Cropped profile preview" />
              <span v-else>{{ userInitials(loggedInUser) }}</span>
            </div>
          </div>

          <div class="confirm-actions">
            <button class="secondary-button compact" type="button" @click="closeProfileImageCropper">Cancel</button>
            <button class="primary-button compact" type="button" @click="applyProfileImageCrop">
              Use Cropped Image
            </button>
          </div>
        </section>
      </div>

    </PortalLayout>

    <PortalLayout
      v-else-if="page === 'users'"
      active-page="users"
      :can-manage-users="canManageUsers"
      :clock-time="clockTime"
      :logged-in-user="loggedInUser"
      title="Simulator Users"
      :user-initials="userInitials"
      @logout="logOut"
      @navigate="goTo"
    >
        <section class="table-panel">
          <div class="table-heading">
            <div>
              <p class="eyebrow">Admin</p>
              <h2>Current Parent Users</h2>
            </div>
            <div class="table-actions">
              <button class="secondary-button compact" type="button" @click="openCreateUserModal">
                <Plus :size="18" aria-hidden="true" />
                <span>Create User</span>
              </button>
              <button class="primary-button compact" type="button" @click="loadUsers" :disabled="isLoadingUsers">
                {{ isLoadingUsers ? 'Loading...' : 'Refresh' }}
              </button>
            </div>
          </div>

          <p v-if="usersMessage" class="message error">{{ usersMessage }}</p>

          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Nickname</th>
                  <th>Email</th>
                  <th>Created Time</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="!isLoadingUsers && users.length === 0">
                  <td colspan="4" class="empty-cell">No users found.</td>
                </tr>
                <tr v-for="user in users" :key="user.id">
                  <td>
                    <div class="user-cell">
                      <span class="avatar tiny">
                        <img v-if="user.profileImage" :src="user.profileImage" alt="" />
                        <span v-else>{{ userInitials(user) }}</span>
                      </span>
                      <button class="text-action parent-name-button" type="button" @click="openParentDetail(user)">
                        {{ user.nickname }}
                      </button>
                      <span v-if="user.isBlocked" class="status-pill blocked">Blocked</span>
                    </div>
                  </td>
                  <td>{{ user.email }}</td>
                  <td>{{ user.createdAt }}</td>
                  <td>
                    <div class="row-actions">
                      <button class="text-action" type="button" @click="openEditUserModal(user)">
                        <Pencil :size="16" aria-hidden="true" />
                        <span>Edit</span>
                      </button>
                      <button class="text-action danger" type="button" @click="openDeleteUserModal(user)">
                        <Trash2 :size="16" aria-hidden="true" />
                        <span>Delete</span>
                      </button>
                      <button
                        class="text-action"
                        :class="{ success: user.isBlocked }"
                        type="button"
                        @click="openBlockUserModal(user)"
                      >
                        <ShieldCheck v-if="user.isBlocked" :size="16" aria-hidden="true" />
                        <Ban v-else :size="16" aria-hidden="true" />
                        <span>{{ user.isBlocked ? 'Unblock' : 'Block' }}</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="table-footer">
            Total {{ users.length }}
          </div>
        </section>

      <div v-if="isParentDetailOpen" class="modal-backdrop parent-detail-backdrop" @click.self="closeParentDetail">
        <section class="modal-panel parent-detail-panel" role="dialog" aria-modal="true" aria-labelledby="parent-detail-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">Parent User</p>
              <h2 id="parent-detail-title">{{ selectedParentUser?.nickname }}</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close parent details" @click="closeParentDetail">
              X
            </button>
          </div>

          <ParentHistoryPanel
            v-model:nutrient-limit-draft="nutrientLimitDraft"
            v-model:parent-history-date-filter="parentHistoryDateFilter"
            v-model:parent-history-section-filter="parentHistorySectionFilter"
            :active-parent-history-item-count="activeParentHistoryItemCount"
            :active-parent-history-page-title="activeParentHistoryPageTitle"
            :active-parent-history-sections="activeParentHistorySections"
            :has-any-parent-history="hasAnyParentHistory"
            :has-parent-history-for-date="hasParentHistoryForDate"
            :is-loading-parent-detail="isLoadingParentDetail"
            :is-saving-nutrient-limit="isSavingNutrientLimit"
            :nutrient-daily-limit="nutrientDailyLimit"
            :nutrient-limit-message="nutrientLimitMessage"
            :nutrient-usage-summary="nutrientUsageSummary"
            :parent-detail="parentDetail"
            :parent-detail-message="parentDetailMessage"
            :parent-history-page-filter="parentHistoryPageFilter"
            :parent-history-pages="parentHistoryPages"
            :visible-parent-history-sections="visibleParentHistorySections"
            @open-ai-report="openParentAIReportPanel"
            @open-export="openParentExportPanel"
            @refresh="refreshParentDetail"
            @save-nutrient-limit="saveParentNutrientLimit"
            @set-history-page="setParentHistoryPage"
            @shift-date="shiftParentHistoryDate"
          />
        </section>
      </div>

      <ParentReportModals
        v-model:parent-ai-report-filters="parentAIReportFilters"
        v-model:parent-export-filters="parentExportFilters"
        :available-parent-ai-report-health-sections="availableParentAIReportHealthSections"
        :available-parent-export-health-sections="availableParentExportHealthSections"
        :is-generating-parent-ai-report="isGeneratingParentAIReport"
        :is-parent-ai-report-open="isParentAIReportOpen"
        :is-parent-ai-report-preview-open="isParentAIReportPreviewOpen"
        :is-parent-export-open="isParentExportOpen"
        :is-parent-export-preview-open="isParentExportPreviewOpen"
        :parent-ai-report="parentAIReport"
        :parent-ai-report-date-range-label="parentAIReportDateRangeLabel"
        :parent-ai-report-item-count="parentAIReportItemCount"
        :parent-ai-report-message="parentAIReportMessage"
        :parent-ai-report-meta="parentAIReportMeta"
        :parent-export-date-range-label="parentExportDateRangeLabel"
        :parent-export-item-count="parentExportItemCount"
        :parent-export-message="parentExportMessage"
        @back-to-ai-report-options="backToParentAIReportOptions"
        @back-to-export-options="backToParentExportOptions"
        @clear-ai-report-health-sections="clearParentAIReportHealthSections"
        @clear-export-health-sections="clearParentExportHealthSections"
        @close-ai-report-panel="closeParentAIReportPanel"
        @close-ai-report-preview="closeParentAIReportPreview"
        @close-export-panel="closeParentExportPanel"
        @close-export-preview="closeParentExportPreview"
        @generate-parent-ai-report="generateParentAIReport"
        @open-export-preview="openParentExportPreview"
        @print-parent-ai-report="printParentAIReport"
        @print-parent-report="printParentReport"
        @select-all-ai-report-health-sections="selectAllParentAIReportHealthSections"
        @select-all-export-health-sections="selectAllParentExportHealthSections"
      />

      <ParentReportDocuments
        :parent-ai-report="parentAIReport"
        :parent-ai-report-labels="parentAIReportLabels"
        :parent-ai-report-meta="parentAIReportMeta"
        :parent-detail="parentDetail"
        :parent-export-date-range-label="parentExportDateRangeLabel"
        :parent-export-history-sections="parentExportHistorySections"
        :parent-export-item-count="parentExportItemCount"
      />

      <div v-if="isCreateUserOpen" class="modal-backdrop" @click.self="closeCreateUserModal">
        <section class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="create-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">User</p>
              <h2 id="create-user-title">Create User</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close create user form" @click="closeCreateUserModal">
              X
            </button>
          </div>

          <form @submit.prevent="submitCreateUser">
            <div class="grid">
              <label>
                Make Nickname
                <input v-model="createUserForm.nickname" autocomplete="nickname" required />
              </label>
              <label>
                Email
                <input v-model="createUserForm.email" type="email" autocomplete="email" required />
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

            <button class="primary-button full" type="submit" :disabled="isCreatingUser">
              {{ isCreatingUser ? 'Creating user...' : 'Create User' }}
            </button>
          </form>

          <p v-if="createUserMessage" class="message" :class="{ error: createUserStatus === 'error' }">
            {{ createUserMessage }}
          </p>
        </section>
      </div>

      <div v-if="isEditUserOpen" class="modal-backdrop" @click.self="closeEditUserModal">
        <section class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="edit-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">User</p>
              <h2 id="edit-user-title">Edit User</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close edit user form" @click="closeEditUserModal">
              X
            </button>
          </div>

          <form @submit.prevent="submitEditUser">
            <div class="grid">
              <label>
                Nickname
                <input v-model="editUserForm.nickname" autocomplete="nickname" required />
              </label>
              <label>
                Email
                <input v-model="editUserForm.email" type="email" autocomplete="email" required />
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

            <button class="primary-button full" type="submit" :disabled="isSavingUser">
              {{ isSavingUser ? 'Saving...' : 'Save Changes' }}
            </button>
          </form>

          <p v-if="editUserMessage" class="message" :class="{ error: editUserStatus === 'error' }">
            {{ editUserMessage }}
          </p>
        </section>
      </div>

      <div v-if="isDeleteUserOpen" class="modal-backdrop" @click.self="closeDeleteUserModal">
        <section class="modal-panel confirm-panel" role="dialog" aria-modal="true" aria-labelledby="delete-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">Delete</p>
              <h2 id="delete-user-title">Are you sure?</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close delete confirmation" @click="closeDeleteUserModal">
              X
            </button>
          </div>

          <p class="confirm-copy">
            This will permanently delete
            <strong>{{ userToDelete?.nickname }}</strong>
            from the database.
          </p>

          <div class="confirm-actions">
            <button class="secondary-button compact" type="button" @click="closeDeleteUserModal">Cancel</button>
            <button class="danger-button compact" type="button" :disabled="isDeletingUser" @click="confirmDeleteUser">
              {{ isDeletingUser ? 'Deleting...' : 'Delete User' }}
            </button>
          </div>

          <p v-if="deleteUserMessage" class="message error">{{ deleteUserMessage }}</p>
        </section>
      </div>

      <div v-if="isBlockUserOpen" class="modal-backdrop" @click.self="closeBlockUserModal">
        <section class="modal-panel confirm-panel" role="dialog" aria-modal="true" aria-labelledby="block-user-title">
          <div class="modal-header">
            <div>
              <p class="eyebrow">{{ userToBlock?.isBlocked ? 'Unblock' : 'Block' }}</p>
              <h2 id="block-user-title">{{ userToBlock?.nickname }}</h2>
            </div>
            <button class="icon-button" type="button" aria-label="Close block popup" @click="closeBlockUserModal">
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
              This keeps the account, but prevents the parent from logging into the simulator app.
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
            <button class="secondary-button compact" type="button" @click="closeBlockUserModal">Cancel</button>
            <button
              class="primary-button compact"
              :class="{ dangerish: !userToBlock?.isBlocked }"
              type="button"
              :disabled="isSavingBlockUser"
              @click="confirmBlockUser"
            >
              {{
                isSavingBlockUser
                  ? 'Saving...'
                  : userToBlock?.isBlocked
                    ? 'Unblock User'
                    : 'Block User'
              }}
            </button>
          </div>

          <p v-if="blockUserMessage" class="message error">{{ blockUserMessage }}</p>
        </section>
      </div>

    </PortalLayout>

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
