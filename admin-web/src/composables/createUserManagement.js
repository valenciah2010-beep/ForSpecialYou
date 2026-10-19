import { apiFetch } from "../api/client.js";
import {
  defaultBlockUntilDate,
  inputDateToLocalDate,
  startOfDay,
} from "../utils/date.js";
import { blankEditUserForm, blankSignupForm } from "../utils/portalForms.js";
import { isValidEmail, isValidPassword } from "../utils/validation.js";

export function createUserManagement(state) {
  const {
    createUserForm,
    editUserForm,
    createUserMessage,
    createUserStatus,
    editUserMessage,
    editUserStatus,
    deleteUserMessage,
    blockUserMessage,
    loggedInUser,
    users,
    usersMessage,
    isLoadingUsers,
    isCreateUserOpen,
    isEditUserOpen,
    isDeleteUserOpen,
    isBlockUserOpen,
    isCreatingUser,
    isSavingUser,
    isDeletingUser,
    isSavingBlockUser,
    userToDelete,
    userToBlock,
    blockMode,
    blockUntilDate,
    refreshParentDetail,
    selectedParentUser,
    saveLoggedInUser,
    logOut,
  } = state;

  function sortUsersByImportance(userList) {
    return [...userList].sort((firstUser, secondUser) => {
      return String(firstUser.nickname || "").localeCompare(
        String(secondUser.nickname || ""),
      );
    });
  }

  function resetCreateUserForm() {
    createUserForm.value = blankSignupForm();
  }

  function resetEditUserForm() {
    editUserForm.value = blankEditUserForm();
  }

  async function loadUsers() {
    isLoadingUsers.value = true;
    usersMessage.value = "";

    try {
      const response = await apiFetch("/api/admin/app-users");
      const data = await response.json();

      if (!response.ok) {
        usersMessage.value = data.message;
        users.value = [];
        return;
      }

      users.value = sortUsersByImportance(data.users);
    } catch {
      usersMessage.value = "Unable to load users from the server.";
      users.value = [];
    } finally {
      isLoadingUsers.value = false;
    }
  }

  function openCreateUserModal() {
    resetCreateUserForm();
    createUserMessage.value = "";
    createUserStatus.value = "";
    isCreateUserOpen.value = true;
  }

  function closeCreateUserModal() {
    isCreateUserOpen.value = false;
    createUserMessage.value = "";
    createUserStatus.value = "";
  }

  function openEditUserModal(user) {
    editUserForm.value = {
      id: user.id,
      nickname: user.nickname,
      email: user.email,
      password: "",
    };
    editUserMessage.value = "";
    editUserStatus.value = "";
    isEditUserOpen.value = true;
  }

  function closeEditUserModal() {
    isEditUserOpen.value = false;
    editUserMessage.value = "";
    editUserStatus.value = "";
    resetEditUserForm();
  }

  function openDeleteUserModal(user) {
    userToDelete.value = user;
    deleteUserMessage.value = "";
    isDeleteUserOpen.value = true;
  }

  function closeDeleteUserModal() {
    isDeleteUserOpen.value = false;
    deleteUserMessage.value = "";
    userToDelete.value = null;
  }

  function openBlockUserModal(user) {
    userToBlock.value = user;
    blockUserMessage.value = "";
    blockMode.value = "indefinite";
    blockUntilDate.value = defaultBlockUntilDate();
    isBlockUserOpen.value = true;
  }

  function closeBlockUserModal() {
    isBlockUserOpen.value = false;
    blockUserMessage.value = "";
    userToBlock.value = null;
    blockMode.value = "indefinite";
    blockUntilDate.value = defaultBlockUntilDate();
  }

  async function submitEditUser() {
    editUserMessage.value = "";
    editUserStatus.value = "";

    if (!editUserForm.value.nickname || !editUserForm.value.email) {
      editUserStatus.value = "error";
      editUserMessage.value = "Please fill out nickname and email.";
      return;
    }

    if (!isValidEmail(editUserForm.value.email)) {
      editUserStatus.value = "error";
      editUserMessage.value = "Please enter a valid email address.";
      return;
    }

    if (
      editUserForm.value.password &&
      !isValidPassword(editUserForm.value.password)
    ) {
      editUserStatus.value = "error";
      editUserMessage.value =
        "Password must be at least 6 characters and include one number.";
      return;
    }

    isSavingUser.value = true;

    try {
      const response = await apiFetch(`/api/users/${editUserForm.value.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          nickname: editUserForm.value.nickname,
          username: editUserForm.value.nickname,
          email: editUserForm.value.email,
          password: editUserForm.value.password,
        }),
      });
      const data = await response.json();

      if (!response.ok) {
        editUserStatus.value = "error";
        editUserMessage.value = data.message;
        return;
      }

      if (loggedInUser.value?.id === editUserForm.value.id) {
        saveLoggedInUser({
          ...loggedInUser.value,
          nickname: editUserForm.value.nickname,
          email: editUserForm.value.email,
        });
      }

      closeEditUserModal();
      await loadUsers();
    } catch {
      editUserStatus.value = "error";
      editUserMessage.value = "Unable to reach the server.";
    } finally {
      isSavingUser.value = false;
    }
  }

  async function confirmDeleteUser() {
    if (!userToDelete.value) return;

    isDeletingUser.value = true;
    deleteUserMessage.value = "";

    try {
      const deletedUserId = userToDelete.value.id;
      const response = await apiFetch(`/api/users/${deletedUserId}`, {
        method: "DELETE",
      });
      const data = await response.json();

      if (!response.ok) {
        deleteUserMessage.value = data.message;
        return;
      }

      closeDeleteUserModal();

      if (loggedInUser.value?.id === deletedUserId) {
        logOut();
        return;
      }

      await loadUsers();
    } catch {
      deleteUserMessage.value = "Unable to reach the server.";
    } finally {
      isDeletingUser.value = false;
    }
  }

  async function confirmBlockUser() {
    if (!userToBlock.value) return;

    isSavingBlockUser.value = true;
    blockUserMessage.value = "";

    if (!userToBlock.value.isBlocked && blockMode.value === "duration") {
      const untilDate = inputDateToLocalDate(blockUntilDate.value);

      if (!untilDate || startOfDay(untilDate) <= startOfDay(new Date())) {
        blockUserMessage.value = "Please choose a future unblock date.";
        isSavingBlockUser.value = false;
        return;
      }
    }

    try {
      const userId = userToBlock.value.id;
      const response = await apiFetch(`/api/admin/app-users/${userId}/block`, {
        method: userToBlock.value.isBlocked ? "DELETE" : "PATCH",
        headers: userToBlock.value.isBlocked
          ? undefined
          : { "Content-Type": "application/json" },
        body: userToBlock.value.isBlocked
          ? undefined
          : JSON.stringify({
              mode: blockMode.value,
              untilDate: blockUntilDate.value,
            }),
      });
      const data = await response.json();

      if (!response.ok) {
        blockUserMessage.value = data.message;
        return;
      }

      closeBlockUserModal();
      await loadUsers();

      if (selectedParentUser.value?.id === userId) {
        await refreshParentDetail();
      }
    } catch {
      blockUserMessage.value = "Unable to reach the server.";
    } finally {
      isSavingBlockUser.value = false;
    }
  }

  async function submitCreateUser() {
    createUserMessage.value = "";
    createUserStatus.value = "";

    if (!isValidEmail(createUserForm.value.email)) {
      createUserStatus.value = "error";
      createUserMessage.value = "Please enter a valid email address.";
      return;
    }

    if (!isValidPassword(createUserForm.value.password)) {
      createUserStatus.value = "error";
      createUserMessage.value =
        "Password must be at least 6 characters and include one number.";
      return;
    }

    if (createUserForm.value.password !== createUserForm.value.verifyPassword) {
      createUserStatus.value = "error";
      createUserMessage.value = "Passwords do not match.";
      return;
    }

    isCreatingUser.value = true;

    try {
      const createUserPayload = {
        ...createUserForm.value,
        username: createUserForm.value.nickname,
      };

      const response = await apiFetch("/api/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(createUserPayload),
      });
      const data = await response.json();

      if (!response.ok) {
        createUserStatus.value = "error";
        createUserMessage.value = data.message;
        return;
      }

      closeCreateUserModal();
      await loadUsers();
    } catch {
      createUserStatus.value = "error";
      createUserMessage.value = "Unable to reach the server.";
    } finally {
      isCreatingUser.value = false;
    }
  }

  return {
    sortUsersByImportance,
    resetCreateUserForm,
    resetEditUserForm,
    loadUsers,
    openCreateUserModal,
    closeCreateUserModal,
    openEditUserModal,
    closeEditUserModal,
    openDeleteUserModal,
    closeDeleteUserModal,
    openBlockUserModal,
    closeBlockUserModal,
    submitEditUser,
    confirmDeleteUser,
    confirmBlockUser,
    submitCreateUser,
  };
}
