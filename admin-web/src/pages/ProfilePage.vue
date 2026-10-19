<script setup>
import { usePortalContext } from "../utils/portalContext.js";
import PortalLayout from "../components/layout/PortalLayout.vue";
const {
  applyProfileImageCrop,
  canManageUsers,
  closeProfileImageCropper,
  clockTime,
  cropPreview,
  goTo,
  handleProfileImageChange,
  isCropDragging,
  isCropperOpen,
  isSavingProfile,
  loggedInUser,
  logOut,
  moveCropImage,
  page,
  profileForm,
  profileMessage,
  profileStatus,
  removeProfileImage,
  startCropDrag,
  stopCropDrag,
  submitProfile,
  userInitials,
  users,
  zoomCropImage,
} = usePortalContext();
</script>

<template>
  <PortalLayout
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
            <img
              v-if="profileForm.profileImage"
              :src="profileForm.profileImage"
              alt="Profile preview"
            />
            <span v-else>{{ userInitials(loggedInUser) }}</span>
          </div>
          <label class="secondary-button compact upload-button">
            Change Image
            <input
              type="file"
              accept="image/*"
              @change="handleProfileImageChange"
            />
          </label>
          <button
            class="text-action danger"
            type="button"
            @click="removeProfileImage"
          >
            Remove Image
          </button>
        </div>

        <form class="profile-form" @submit.prevent="submitProfile">
          <div class="grid">
            <label>
              Nickname
              <input
                v-model="profileForm.nickname"
                autocomplete="nickname"
                required
              />
            </label>
            <label>
              Email
              <input
                v-model="profileForm.email"
                type="email"
                autocomplete="email"
                required
              />
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

          <button
            class="primary-button full"
            type="submit"
            :disabled="isSavingProfile"
          >
            {{ isSavingProfile ? "Saving..." : "Save Profile" }}
          </button>
        </form>
      </div>

      <p
        v-if="profileMessage"
        class="message"
        :class="{ error: profileStatus === 'error' }"
      >
        {{ profileMessage }}
      </p>
    </section>

    <div
      v-if="isCropperOpen"
      class="modal-backdrop"
      @click.self="closeProfileImageCropper"
    >
      <section
        class="modal-panel crop-panel"
        role="dialog"
        aria-modal="true"
        aria-labelledby="crop-image-title"
      >
        <div class="modal-header">
          <div>
            <p class="eyebrow">Profile Image</p>
            <h2 id="crop-image-title">Crop Image</h2>
          </div>
          <button
            class="icon-button"
            type="button"
            aria-label="Close image cropper"
            @click="closeProfileImageCropper"
          >
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
            <img
              v-if="cropPreview"
              :src="cropPreview"
              alt="Cropped profile preview"
            />
            <span v-else>{{ userInitials(loggedInUser) }}</span>
          </div>
        </div>

        <div class="confirm-actions">
          <button
            class="secondary-button compact"
            type="button"
            @click="closeProfileImageCropper"
          >
            Cancel
          </button>
          <button
            class="primary-button compact"
            type="button"
            @click="applyProfileImageCrop"
          >
            Use Cropped Image
          </button>
        </div>
      </section>
    </div>
  </PortalLayout>
</template>
