<script setup>
import CreateUserDialog from "./CreateUserDialog.vue";
import EditUserDialog from "./EditUserDialog.vue";
import DeleteUserDialog from "./DeleteUserDialog.vue";
import BlockUserDialog from "./BlockUserDialog.vue";
import ParentDetailDialog from "./ParentDetailDialog.vue";
import { usePortalContext } from "../utils/portalContext.js";
import { Ban, Pencil, Plus, ShieldCheck, Trash2 } from "@lucide/vue";
import ParentReportDocuments from "../components/parent/ParentReportDocuments.vue";
import ParentReportModals from "../components/parent/ParentReportModals.vue";
import PortalLayout from "../components/layout/PortalLayout.vue";
const {
  availableParentAiReportHealthSections,
  availableParentExportHealthSections,
  backToParentAiReportOptions,
  backToParentExportOptions,
  canManageUsers,
  clearParentAiReportHealthSections,
  clearParentExportHealthSections,
  closeParentAiReportPanel,
  closeParentAiReportPreview,
  closeParentExportPanel,
  closeParentExportPreview,
  clockTime,
  goTo,
  generateParentAiReport,
  isGeneratingParentAiReport,
  isLoadingUsers,
  isParentAiReportOpen,
  isParentAiReportPreviewOpen,
  isParentExportOpen,
  isParentExportPreviewOpen,
  loggedInUser,
  logOut,
  openBlockUserModal,
  openCreateUserModal,
  openDeleteUserModal,
  openEditUserModal,
  openParentDetail,
  openParentExportPreview,
  page,
  parentAiReport,
  parentAiReportDateRangeLabel,
  parentAiReportFilters,
  parentAiReportItemCount,
  parentAiReportLabels,
  parentAiReportMessage,
  parentAiReportMeta,
  parentDetail,
  parentExportDateRangeLabel,
  parentExportFilters,
  parentExportHistorySections,
  parentExportItemCount,
  parentExportMessage,
  selectAllParentAiReportHealthSections,
  selectAllParentExportHealthSections,
  printParentAiReport,
  printParentReport,
  userInitials,
  users,
  usersMessage,
  loadUsers,
} = usePortalContext();
</script>

<template>
  <PortalLayout
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
          <button
            class="secondary-button compact"
            type="button"
            @click="openCreateUserModal"
          >
            <Plus :size="18" aria-hidden="true" />
            <span>Create User</span>
          </button>
          <button
            class="primary-button compact"
            type="button"
            @click="loadUsers"
            :disabled="isLoadingUsers"
          >
            {{ isLoadingUsers ? "Loading..." : "Refresh" }}
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
                    <img
                      v-if="user.profileImage"
                      :src="user.profileImage"
                      alt=""
                    />
                    <span v-else>{{ userInitials(user) }}</span>
                  </span>
                  <button
                    class="text-action parent-name-button"
                    type="button"
                    @click="openParentDetail(user)"
                  >
                    {{ user.nickname }}
                  </button>
                  <span v-if="user.isBlocked" class="status-pill blocked"
                    >Blocked</span
                  >
                </div>
              </td>
              <td>{{ user.email }}</td>
              <td>{{ user.createdAt }}</td>
              <td>
                <div class="row-actions">
                  <button
                    class="text-action"
                    type="button"
                    @click="openEditUserModal(user)"
                  >
                    <Pencil :size="16" aria-hidden="true" />
                    <span>Edit</span>
                  </button>
                  <button
                    class="text-action danger"
                    type="button"
                    @click="openDeleteUserModal(user)"
                  >
                    <Trash2 :size="16" aria-hidden="true" />
                    <span>Delete</span>
                  </button>
                  <button
                    class="text-action"
                    :class="{ success: user.isBlocked }"
                    type="button"
                    @click="openBlockUserModal(user)"
                  >
                    <ShieldCheck
                      v-if="user.isBlocked"
                      :size="16"
                      aria-hidden="true"
                    />
                    <Ban v-else :size="16" aria-hidden="true" />
                    <span>{{ user.isBlocked ? "Unblock" : "Block" }}</span>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="table-footer">Total {{ users.length }}</div>
    </section>

    <ParentDetailDialog />

    <ParentReportModals
      v-model:parent-ai-report-filters="parentAiReportFilters"
      v-model:parent-export-filters="parentExportFilters"
      :available-parent-ai-report-health-sections="
        availableParentAiReportHealthSections
      "
      :available-parent-export-health-sections="
        availableParentExportHealthSections
      "
      :is-generating-parent-ai-report="isGeneratingParentAiReport"
      :is-parent-ai-report-open="isParentAiReportOpen"
      :is-parent-ai-report-preview-open="isParentAiReportPreviewOpen"
      :is-parent-export-open="isParentExportOpen"
      :is-parent-export-preview-open="isParentExportPreviewOpen"
      :parent-ai-report="parentAiReport"
      :parent-ai-report-date-range-label="parentAiReportDateRangeLabel"
      :parent-ai-report-item-count="parentAiReportItemCount"
      :parent-ai-report-message="parentAiReportMessage"
      :parent-ai-report-meta="parentAiReportMeta"
      :parent-export-date-range-label="parentExportDateRangeLabel"
      :parent-export-item-count="parentExportItemCount"
      :parent-export-message="parentExportMessage"
      @back-to-ai-report-options="backToParentAiReportOptions"
      @back-to-export-options="backToParentExportOptions"
      @clear-ai-report-health-sections="clearParentAiReportHealthSections"
      @clear-export-health-sections="clearParentExportHealthSections"
      @close-ai-report-panel="closeParentAiReportPanel"
      @close-ai-report-preview="closeParentAiReportPreview"
      @close-export-panel="closeParentExportPanel"
      @close-export-preview="closeParentExportPreview"
      @generate-parent-ai-report="generateParentAiReport"
      @open-export-preview="openParentExportPreview"
      @print-parent-ai-report="printParentAiReport"
      @print-parent-report="printParentReport"
      @select-all-ai-report-health-sections="
        selectAllParentAiReportHealthSections
      "
      @select-all-export-health-sections="selectAllParentExportHealthSections"
    />

    <ParentReportDocuments
      :parent-ai-report="parentAiReport"
      :parent-ai-report-labels="parentAiReportLabels"
      :parent-ai-report-meta="parentAiReportMeta"
      :parent-detail="parentDetail"
      :parent-export-date-range-label="parentExportDateRangeLabel"
      :parent-export-history-sections="parentExportHistorySections"
      :parent-export-item-count="parentExportItemCount"
    />

    <CreateUserDialog />

    <EditUserDialog />

    <DeleteUserDialog />

    <BlockUserDialog />
  </PortalLayout>
</template>
