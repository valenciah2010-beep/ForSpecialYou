import { createUserManagement } from "./createUserManagement.js";
import { computed, onMounted, onUnmounted, ref } from "vue";
import { apiFetch } from "../api/client.js";
import { useClock } from "./useClock.js";
import { themeOptions, useTheme } from "./useTheme.js";
import { useProfileCropper } from "./useProfileCropper.js";
import { useParentReports } from "./useParentReports.js";
import {
  defaultBlockUntilDate,
  formatLogTime,
  formatLogTimestamp,
  inputDateToLocalDate,
  startOfDay,
} from "../utils/date.js";
import {
  childInfoRows,
  hasChildInfo,
  historySectionCount,
  logHasIntensityBar,
  logTypeLabel,
  savedMealList,
  savedMealMetricText,
  summarizedMedicineRows,
} from "../utils/history.js";
import {
  blankEditUserForm,
  blankLoginForm,
  blankProfileForm,
  blankSignupForm,
} from "../utils/portalForms.js";
import { clamp, isValidEmail, isValidPassword } from "../utils/validation.js";

export function useAdminPortal() {
  const currentPath = ref(window.location.pathname);
  const loginForm = ref(blankLoginForm());
  const signupForm = ref(blankSignupForm());
  const createUserForm = ref(blankSignupForm());
  const editUserForm = ref(blankEditUserForm());
  const profileForm = ref(blankProfileForm());
  const loginMessage = ref("");
  const loginStatus = ref("");
  const signupMessage = ref("");
  const signupStatus = ref("");
  const createUserMessage = ref("");
  const createUserStatus = ref("");
  const editUserMessage = ref("");
  const editUserStatus = ref("");
  const profileMessage = ref("");
  const profileStatus = ref("");
  const deleteUserMessage = ref("");
  const blockUserMessage = ref("");
  const { currentTheme, isThemeMenuOpen, setTheme } = useTheme();
  const { clockTime } = useClock();
  const loggedInUser = ref(null);
  const users = ref([]);
  const usersMessage = ref("");
  const isLoadingUsers = ref(false);
  const isCreateUserOpen = ref(false);
  const isEditUserOpen = ref(false);
  const isDeleteUserOpen = ref(false);
  const isBlockUserOpen = ref(false);
  const isCreatingUser = ref(false);
  const isSavingUser = ref(false);
  const isSavingProfile = ref(false);
  const isDeletingUser = ref(false);
  const isSavingBlockUser = ref(false);
  const userToDelete = ref(null);
  const userToBlock = ref(null);
  const blockMode = ref("indefinite");
  const blockUntilDate = ref(defaultBlockUntilDate());
  const isBusy = ref(false);
  const maxProfileImageSize = 5 * 1024 * 1024;
  const parentReports = useParentReports();
  const {
    finishParentAiReportPrint,
    finishParentReportPrint,
    refreshParentDetail,
    selectedParentUser,
  } = parentReports;
  const {
    applyProfileImageCrop,
    closeProfileImageCropper,
    cropPosition,
    cropPreview,
    cropZoom,
    isCropDragging,
    isCropperOpen,
    moveCropImage,
    openProfileImageCropper,
    startCropDrag,
    stopCropDrag,
    zoomCropImage,
  } = useProfileCropper({
    onApply(image) {
      profileForm.value.profileImage = image;
      profileMessage.value = "";
      profileStatus.value = "";
    },
    onError(message) {
      profileStatus.value = "error";
      profileMessage.value = message;
    },
    onLoaded() {
      profileMessage.value = "";
      profileStatus.value = "";
    },
  });
  const canManageUsers = computed(() => loggedInUser.value?.role === "admin");
  const blockUntilDateLabel = computed(() => {
    const date = inputDateToLocalDate(blockUntilDate.value);

    if (!date) return "Choose a date";

    return date.toLocaleDateString(undefined, {
      month: "long",
      day: "numeric",
      year: "numeric",
    });
  });
  const blockLengthText = computed(() => {
    const date = inputDateToLocalDate(blockUntilDate.value);
    if (!date) return "Choose a valid date.";

    const today = startOfDay(new Date());
    const endDate = startOfDay(date);
    const dayCount = Math.ceil(
      (endDate.getTime() - today.getTime()) / (24 * 60 * 60 * 1000),
    );

    if (dayCount < 1) {
      return "Choose a future date.";
    }

    if (dayCount >= 14) {
      const weekCount = Math.floor(dayCount / 7);
      const remainingDays = dayCount % 7;
      return `Blocked for ${weekCount} week${weekCount === 1 ? "" : "s"}${remainingDays ? ` and ${remainingDays} day${remainingDays === 1 ? "" : "s"}` : ""}.`;
    }

    return `Blocked for ${dayCount} day${dayCount === 1 ? "" : "s"}.`;
  });
  const page = computed(() => {
    if (currentPath.value === "/storage") {
      if (!loggedInUser.value) return "login";
      return canManageUsers.value ? "storage" : "welcome";
    }
    if (currentPath.value === "/users") {
      if (!loggedInUser.value) return "login";
      return canManageUsers.value ? "users" : "welcome";
    }
    if (currentPath.value === "/profile") {
      return loggedInUser.value ? "profile" : "login";
    }
    if (currentPath.value === "/welcome" || currentPath.value === "/home") {
      return loggedInUser.value ? "welcome" : "login";
    }
    if (currentPath.value === "/login") return "login";
    if (currentPath.value === "/signup") return "login";
    return loggedInUser.value ? "welcome" : "home";
  });

  function userInitials(user) {
    const name = user?.nickname || "User";
    return name
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase())
      .join("");
  }

  function syncProfileForm() {
    if (!loggedInUser.value) return;

    profileForm.value = {
      nickname: loggedInUser.value.nickname || "",
      email: loggedInUser.value.email || "",
      password: "",
      profileImage: loggedInUser.value.profileImage || "",
    };
  }

  function saveLoggedInUser(user) {
    loggedInUser.value = user;
  }

  function goTo(path) {
    window.history.pushState({}, "", path);
    currentPath.value = path;
    loginMessage.value = "";
    loginStatus.value = "";
    signupMessage.value = "";
    signupStatus.value = "";
    createUserMessage.value = "";
    createUserStatus.value = "";
    editUserMessage.value = "";
    editUserStatus.value = "";
    profileMessage.value = "";
    profileStatus.value = "";
    deleteUserMessage.value = "";

    if ((path === "/welcome" || path === "/users") && canManageUsers.value) {
      loadUsers();
    }

    if (path === "/profile") {
      syncProfileForm();
      loadCurrentUser();
    }
  }

  const {
    submitCreateUser,
    confirmBlockUser,
    confirmDeleteUser,
    submitEditUser,
    closeBlockUserModal,
    openBlockUserModal,
    closeDeleteUserModal,
    openDeleteUserModal,
    closeEditUserModal,
    openEditUserModal,
    closeCreateUserModal,
    openCreateUserModal,
    loadUsers,
    resetEditUserForm,
    resetCreateUserForm,
    sortUsersByImportance,
  } = createUserManagement({
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
  });

  const handlePopState = () => {
    currentPath.value = window.location.pathname;

    if (currentPath.value === "/users" && canManageUsers.value) {
      loadUsers();
    }

    if (currentPath.value === "/profile") {
      syncProfileForm();
      loadCurrentUser();
    }
  };

  onMounted(() => {
    window.addEventListener("admin-session-expired", handleSessionExpired);
    window.addEventListener("popstate", handlePopState);
    window.addEventListener("afterprint", finishParentReportPrint);
    window.addEventListener("afterprint", finishParentAiReportPrint);
    loadAdminSession();
  });

  onUnmounted(() => {
    window.removeEventListener("admin-session-expired", handleSessionExpired);
    window.removeEventListener("popstate", handlePopState);
    window.removeEventListener("afterprint", finishParentReportPrint);
    window.removeEventListener("afterprint", finishParentAiReportPrint);
  });

  async function submitLogin() {
    loginMessage.value = "";
    loginStatus.value = "";
    isBusy.value = true;

    try {
      const response = await apiFetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(loginForm.value),
      });
      const data = await response.json();

      if (response.ok) {
        saveLoggedInUser(data.user);
        loginForm.value = { username: "", password: "" };
        goTo("/welcome");
        return;
      }

      loginStatus.value = "error";
      loginMessage.value = data.message;
    } catch {
      loginStatus.value = "error";
      loginMessage.value = "Unable to reach the server.";
    } finally {
      isBusy.value = false;
    }
  }

  async function loadAdminSession() {
    try {
      const response = await apiFetch("/api/admin/session");
      const data = await response.json();

      if (!response.ok) {
        loggedInUser.value = null;
        users.value = [];
        return;
      }

      saveLoggedInUser(data.user);
      syncProfileForm();

      if (
        currentPath.value === "/" ||
        currentPath.value === "/login" ||
        currentPath.value === "/signup"
      ) {
        goTo("/welcome");
      } else if (currentPath.value === "/users" && canManageUsers.value) {
        loadUsers();
      }
    } catch {
      loggedInUser.value = null;
      users.value = [];
    }
  }

  function clearSession() {
    loggedInUser.value = null;
    users.value = [];
    usersMessage.value = "";
    profileForm.value = blankProfileForm();
    parentReports.closeParentDetail();
    finishParentReportPrint();
    finishParentAiReportPrint();
    isCreateUserOpen.value = false;
    isEditUserOpen.value = false;
    isDeleteUserOpen.value = false;
    isBlockUserOpen.value = false;
    closeProfileImageCropper();
    goTo("/login");
  }

  function handleSessionExpired() {
    if (!loggedInUser.value) return;
    clearSession();
    loginStatus.value = "error";
    loginMessage.value = "Your session expired. Please log in again.";
  }

  async function logOut() {
    try {
      await apiFetch("/api/admin/logout", {
        method: "POST",
      });
    } catch {
      // Local cleanup still signs the admin out of this browser view.
    }

    clearSession();
  }

  async function loadCurrentUser() {
    if (!loggedInUser.value?.id) return;

    try {
      const response = await apiFetch("/api/admin/session");
      const data = await response.json();

      if (!response.ok) {
        profileStatus.value = "error";
        profileMessage.value = data.message;
        return;
      }

      saveLoggedInUser(data.user);
      syncProfileForm();
    } catch {
      profileStatus.value = "error";
      profileMessage.value = "Unable to load your profile.";
    }
  }

  function handleProfileImageChange(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    event.target.value = "";

    if (!file.type.startsWith("image/")) {
      profileStatus.value = "error";
      profileMessage.value = "Please choose an image file.";
      return;
    }

    if (file.size > maxProfileImageSize) {
      profileStatus.value = "error";
      profileMessage.value = "Please choose an image smaller than 5MB.";
      return;
    }

    const reader = new FileReader();
    reader.addEventListener("load", () => {
      openProfileImageCropper(String(reader.result || ""));
      profileMessage.value = "";
      profileStatus.value = "";
    });
    reader.addEventListener("error", () => {
      profileStatus.value = "error";
      profileMessage.value = "Unable to load that image.";
    });
    reader.readAsDataURL(file);
  }

  function removeProfileImage() {
    profileForm.value.profileImage = "";
    closeProfileImageCropper();
  }

  async function submitProfile() {
    profileMessage.value = "";
    profileStatus.value = "";

    if (!profileForm.value.nickname || !profileForm.value.email) {
      profileStatus.value = "error";
      profileMessage.value = "Please fill out nickname and email.";
      return;
    }

    if (!isValidEmail(profileForm.value.email)) {
      profileStatus.value = "error";
      profileMessage.value = "Please enter a valid email address.";
      return;
    }

    if (
      profileForm.value.password &&
      !isValidPassword(profileForm.value.password)
    ) {
      profileStatus.value = "error";
      profileMessage.value =
        "Password must be at least 6 characters and include one number.";
      return;
    }

    isSavingProfile.value = true;

    try {
      const response = await apiFetch(`/api/users/${loggedInUser.value.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          nickname: profileForm.value.nickname,
          username: profileForm.value.nickname,
          email: profileForm.value.email,
          password: profileForm.value.password,
          profileImage: profileForm.value.profileImage,
        }),
      });
      const data = await response.json();

      if (!response.ok) {
        profileStatus.value = "error";
        profileMessage.value = data.message;
        return;
      }

      if (profileForm.value.password) {
        clearSession();
        loginStatus.value = "success";
        loginMessage.value = "Password updated. Please log in again.";
        return;
      }
      saveLoggedInUser({
        ...loggedInUser.value,
        nickname: profileForm.value.nickname,
        email: profileForm.value.email,
        profileImage: profileForm.value.profileImage,
      });
      profileForm.value.password = "";
      profileStatus.value = "success";
      profileMessage.value = data.message;

      if (canManageUsers.value) {
        await loadUsers();
      }
    } catch {
      profileStatus.value = "error";
      profileMessage.value = "Unable to reach the server.";
    } finally {
      isSavingProfile.value = false;
    }
  }

  async function submitSignup() {
    signupMessage.value = "";
    signupStatus.value = "";

    if (!isValidEmail(signupForm.value.email)) {
      signupStatus.value = "error";
      signupMessage.value = "Please enter a valid email address.";
      return;
    }

    if (!isValidPassword(signupForm.value.password)) {
      signupStatus.value = "error";
      signupMessage.value =
        "Password must be at least 6 characters and include one number.";
      return;
    }

    if (signupForm.value.password !== signupForm.value.verifyPassword) {
      signupStatus.value = "error";
      signupMessage.value = "Passwords do not match.";
      return;
    }

    isBusy.value = true;

    try {
      const signupPayload = {
        ...signupForm.value,
        username: signupForm.value.nickname,
      };

      const response = await apiFetch("/api/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(signupPayload),
      });
      const data = await response.json();
      signupStatus.value = response.ok ? "success" : "error";
      signupMessage.value = data.message;

      if (response.ok) {
        const createdNickname = signupForm.value.nickname;
        signupForm.value = blankSignupForm();
        loginForm.value = {
          username: createdNickname,
          password: "",
        };
        goTo("/login");
      }
    } catch {
      signupStatus.value = "error";
      signupMessage.value = "Unable to reach the server.";
    } finally {
      isBusy.value = false;
    }
  }

  return {
    ...parentReports,
    loadUsers,
    confirmDeleteUser,
    applyProfileImageCrop,
    blockLengthText,
    blockMode,
    blockUntilDate,
    blockUntilDateLabel,
    blockUserMessage,
    canManageUsers,
    childInfoRows,
    closeBlockUserModal,
    closeCreateUserModal,
    closeDeleteUserModal,
    closeEditUserModal,
    closeProfileImageCropper,
    confirmBlockUser,
    createUserForm,
    createUserMessage,
    createUserStatus,
    clockTime,
    cropPreview,
    currentTheme,
    deleteUserMessage,
    editUserForm,
    editUserMessage,
    editUserStatus,
    formatLogTime,
    formatLogTimestamp,
    goTo,
    handleProfileImageChange,
    hasChildInfo,
    historySectionCount,
    isBlockUserOpen,
    isBusy,
    isCreateUserOpen,
    isCreatingUser,
    isCropDragging,
    isCropperOpen,
    isDeleteUserOpen,
    isDeletingUser,
    isEditUserOpen,
    isThemeMenuOpen,
    isLoadingUsers,
    isSavingBlockUser,
    isSavingProfile,
    isSavingUser,
    loggedInUser,
    logOut,
    logHasIntensityBar,
    loginForm,
    loginMessage,
    loginStatus,
    logTypeLabel,
    moveCropImage,
    openBlockUserModal,
    openCreateUserModal,
    openDeleteUserModal,
    openEditUserModal,
    page,
    profileForm,
    profileMessage,
    profileStatus,
    removeProfileImage,
    savedMealList,
    savedMealMetricText,
    signupForm,
    signupMessage,
    signupStatus,
    startCropDrag,
    stopCropDrag,
    summarizedMedicineRows,
    setTheme,
    submitCreateUser,
    submitEditUser,
    submitLogin,
    submitProfile,
    submitSignup,
    themeOptions,
    userInitials,
    users,
    usersMessage,
    userToBlock,
    userToDelete,
    zoomCropImage,
  };
}
