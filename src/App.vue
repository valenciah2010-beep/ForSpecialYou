<script setup>
import { Flower, Palette, Pencil, Plus, Trash2 } from '@lucide/vue';
import { computed, onMounted, onUnmounted, ref } from 'vue';

const currentPath = ref(window.location.pathname);
const loginForm = ref({ username: '', password: '' });
const signupForm = ref({
  nickname: '',
  email: '',
  password: '',
  verifyPassword: '',
  role: 'parent'
});
const createUserForm = ref({
  nickname: '',
  email: '',
  password: '',
  verifyPassword: '',
  role: 'patient'
});
const editUserForm = ref({
  id: null,
  nickname: '',
  email: '',
  password: ''
});
const profileForm = ref({
  nickname: '',
  email: '',
  password: '',
  profileImage: ''
});
const loginMessage = ref('');
const loginStatus = ref('');
const signupMessage = ref('');
const signupStatus = ref('');
const createUserMessage = ref('');
const createUserStatus = ref('');
const editUserMessage = ref('');
const editUserStatus = ref('');
const profileMessage = ref('');
const profileStatus = ref('');
const deleteUserMessage = ref('');
const rolesMessage = ref('');
const rolesStatus = ref('');
const savedTheme = localStorage.getItem('carePortalTheme');
const currentTheme = ref(savedTheme || 'green');
const isThemeMenuOpen = ref(false);
const loggedInUser = ref(null);
const users = ref([]);
const usersMessage = ref('');
const isLoadingUsers = ref(false);
const isCreateUserOpen = ref(false);
const isEditUserOpen = ref(false);
const isDeleteUserOpen = ref(false);
const isParentDetailOpen = ref(false);
const isCropperOpen = ref(false);
const isCropDragging = ref(false);
const isCreatingUser = ref(false);
const isSavingUser = ref(false);
const isSavingProfile = ref(false);
const isDeletingUser = ref(false);
const savingRoleUserId = ref(null);
const userToDelete = ref(null);
const selectedParentUser = ref(null);
const parentDetail = ref(null);
const parentDetailMessage = ref('');
const isLoadingParentDetail = ref(false);
const isBusy = ref(false);
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '';
const maxProfileImageSize = 5 * 1024 * 1024;
const cropPosition = ref({
  x: 0,
  y: 0
});
const cropZoom = ref(1);
const cropPreview = ref('');
const clockTime = ref({
  hours: '00',
  minutes: '00',
  seconds: '00',
  period: 'AM',
  date: ''
});
const canManageUsers = computed(() => loggedInUser.value?.role === 'admin');
let cropImageElement;
let cropDragStart = {
  pointerX: 0,
  pointerY: 0,
  x: 0,
  y: 0
};

const page = computed(() => {
  if (currentPath.value === '/users') {
    if (!loggedInUser.value) return 'login';
    return canManageUsers.value ? 'users' : 'welcome';
  }
  if (currentPath.value === '/roles') {
    if (!loggedInUser.value) return 'login';
    return canManageUsers.value ? 'roles' : 'welcome';
  }
  if (currentPath.value === '/profile') {
    return loggedInUser.value ? 'profile' : 'login';
  }
  if (currentPath.value === '/welcome' || currentPath.value === '/home') {
    return loggedInUser.value ? 'users' : 'login';
  }
  if (currentPath.value === '/login') return 'login';
  if (currentPath.value === '/signup') return 'login';
  return loggedInUser.value ? 'users' : 'home';
});

const roleOptions = [
  { value: 'patient', label: 'Patient' },
  { value: 'parent', label: 'Parent' },
  { value: 'caregiver', label: 'Caregiver' },
  { value: 'doctor', label: 'Doctor' },
  { value: 'admin', label: 'Admin' }
];

const roleImportance = {
  admin: 1,
  doctor: 2,
  caregiver: 3,
  parent: 4,
  patient: 5
};

const themeOptions = [
  { value: 'green', label: 'Green', color: '#27695d' },
  { value: 'blue', label: 'Blue', color: '#2f6df6' },
  { value: 'rose', label: 'Rose', color: '#be3455' },
  { value: 'gold', label: 'Gold', color: '#b7791f' },
  { value: 'sakura', label: 'Sakura', color: '#d95f8d', icon: 'flower' }
];

async function apiFetch(path, options) {
  return fetch(`${apiBaseUrl}${path}`, {
    credentials: 'include',
    ...(options || {})
  });
}

function setTheme(theme) {
  currentTheme.value = theme;
  localStorage.setItem('carePortalTheme', theme);
  isThemeMenuOpen.value = false;
}

function updateClock() {
  const now = new Date();
  const hours24 = now.getHours();
  const hours12 = hours24 % 12 || 12;

  clockTime.value = {
    hours: String(hours12).padStart(2, '0'),
    minutes: String(now.getMinutes()).padStart(2, '0'),
    seconds: String(now.getSeconds()).padStart(2, '0'),
    period: hours24 >= 12 ? 'PM' : 'AM',
    date: now.toLocaleDateString(undefined, {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    })
  };
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidPassword(password) {
  return password.length >= 6 && /\d/.test(password);
}

function sortUsersByImportance(userList) {
  return [...userList].sort((firstUser, secondUser) => {
    const firstRank = roleImportance[firstUser.role] || 99;
    const secondRank = roleImportance[secondUser.role] || 99;

    if (firstRank !== secondRank) {
      return firstRank - secondRank;
    }

    return String(firstUser.nickname || '').localeCompare(String(secondUser.nickname || ''));
  });
}

function roleClass(role) {
  return `role-${roleImportance[role] ? role : 'default'}`;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function resetCreateUserForm() {
  createUserForm.value = {
    nickname: '',
    email: '',
    password: '',
    verifyPassword: '',
    role: 'patient'
  };
}

function resetEditUserForm() {
  editUserForm.value = {
    id: null,
    nickname: '',
    email: '',
    password: ''
  };
}

function userInitials(user) {
  const name = user?.nickname || 'User';
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('');
}

function childInfoRows(childProfile = {}) {
  return [
    { label: 'Child Name', value: childProfile.fullName },
    { label: 'Date of Birth', value: childProfile.birthDate },
    { label: 'Support Needs', value: childProfile.supportNeeds },
    { label: 'Home / School Notes', value: childProfile.homeSchoolNotes },
    { label: 'Emergency Contact', value: childProfile.emergencyContact },
    { label: 'Care Notes', value: childProfile.careNotes }
  ];
}

function hasChildInfo(childProfile = {}) {
  return childInfoRows(childProfile).some((row) => String(row.value || '').trim());
}

function formatLogTimestamp(timestamp) {
  if (!timestamp) return '';
  const normalizedTimestamp = typeof timestamp === 'number' && timestamp < 100000000000
    ? timestamp * 1000
    : timestamp;
  const date = new Date(normalizedTimestamp);
  return Number.isNaN(date.getTime()) ? timestamp : date.toLocaleString();
}

function logTypeLabel(log) {
  return log?.type === 'snapshot' ? 'Daily Snapshot' : 'Quick Log';
}

function syncProfileForm() {
  if (!loggedInUser.value) return;

  profileForm.value = {
    nickname: loggedInUser.value.nickname || '',
    email: loggedInUser.value.email || '',
    password: '',
    profileImage: loggedInUser.value.profileImage || ''
  };
}

function saveLoggedInUser(user) {
  loggedInUser.value = user;
}

function goTo(path) {
  window.history.pushState({}, '', path);
  currentPath.value = path;
  loginMessage.value = '';
  loginStatus.value = '';
  signupMessage.value = '';
  signupStatus.value = '';
  createUserMessage.value = '';
  createUserStatus.value = '';
  editUserMessage.value = '';
  editUserStatus.value = '';
  profileMessage.value = '';
  profileStatus.value = '';
  deleteUserMessage.value = '';
  rolesMessage.value = '';
  rolesStatus.value = '';

  if ((path === '/users' || path === '/roles') && canManageUsers.value) {
    loadUsers();
  }

  if (path === '/profile') {
    syncProfileForm();
    loadCurrentUser();
  }
}

window.addEventListener('popstate', () => {
  currentPath.value = window.location.pathname;

  if ((currentPath.value === '/users' || currentPath.value === '/roles') && canManageUsers.value) {
    loadUsers();
  }

  if (currentPath.value === '/profile') {
    syncProfileForm();
    loadCurrentUser();
  }
});

let clockTimer;
onMounted(() => {
  updateClock();
  clockTimer = window.setInterval(updateClock, 1000);
  loadAdminSession();
});

onUnmounted(() => {
  window.clearInterval(clockTimer);
});

async function submitLogin() {
  loginMessage.value = '';
  loginStatus.value = '';
  isBusy.value = true;

  try {
    const response = await apiFetch('/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(loginForm.value)
    });
    const data = await response.json();

    if (response.ok) {
      saveLoggedInUser(data.user);
      loginForm.value = { username: '', password: '' };
      goTo('/users');
      return;
    }

    loginStatus.value = 'error';
    loginMessage.value = data.message;
  } catch {
    loginStatus.value = 'error';
    loginMessage.value = 'Unable to reach the server.';
  } finally {
    isBusy.value = false;
  }
}

async function loadAdminSession() {
  try {
    const response = await apiFetch('/api/admin/session');
    const data = await response.json();

    if (!response.ok) {
      loggedInUser.value = null;
      users.value = [];
      return;
    }

    saveLoggedInUser(data.user);
    syncProfileForm();

    if (currentPath.value === '/' || currentPath.value === '/login' || currentPath.value === '/signup') {
      goTo('/users');
    } else if ((currentPath.value === '/users' || currentPath.value === '/roles') && canManageUsers.value) {
      loadUsers();
    }
  } catch {
    loggedInUser.value = null;
    users.value = [];
  }
}

async function logOut() {
  try {
    await apiFetch('/api/admin/logout', {
      method: 'POST'
    });
  } catch {
    // Local cleanup still signs the admin out of this browser view.
  }

  loggedInUser.value = null;
  users.value = [];
  usersMessage.value = '';
  goTo('/');
}

async function loadCurrentUser() {
  if (!loggedInUser.value?.id) return;

  try {
    const response = await apiFetch('/api/admin/session');
    const data = await response.json();

    if (!response.ok) {
      profileStatus.value = 'error';
      profileMessage.value = data.message;
      return;
    }

    saveLoggedInUser(data.user);
    syncProfileForm();
  } catch {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to load your profile.';
  }
}

async function loadUsers() {
  isLoadingUsers.value = true;
  usersMessage.value = '';
  rolesMessage.value = '';

  try {
    const response = await apiFetch('/api/admin/app-users');
    const data = await response.json();

    if (!response.ok) {
      usersMessage.value = data.message;
      rolesStatus.value = 'error';
      rolesMessage.value = data.message;
      users.value = [];
      return;
    }

    users.value = sortUsersByImportance(data.users).map((user) => ({
      ...user,
      pendingRole: user.role
    }));
  } catch {
    usersMessage.value = 'Unable to load users from the server.';
    rolesStatus.value = 'error';
    rolesMessage.value = 'Unable to load users from the server.';
    users.value = [];
  } finally {
    isLoadingUsers.value = false;
  }
}

async function saveUserRole(user) {
  rolesMessage.value = '';
  rolesStatus.value = '';
  savingRoleUserId.value = user.id;

  try {
    const response = await apiFetch(`/api/users/${user.id}/role`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role: user.pendingRole })
    });
    const data = await response.json();

    if (!response.ok) {
      rolesStatus.value = 'error';
      rolesMessage.value = data.message;
      return;
    }

    if (loggedInUser.value?.id === user.id) {
      saveLoggedInUser({
        ...loggedInUser.value,
        role: user.pendingRole
      });
    }

    user.role = user.pendingRole;
    users.value = sortUsersByImportance(users.value);
    rolesStatus.value = 'success';
    rolesMessage.value = data.message;
  } catch {
    rolesStatus.value = 'error';
    rolesMessage.value = 'Unable to reach the server.';
  } finally {
    savingRoleUserId.value = null;
  }
}

function openCreateUserModal() {
  resetCreateUserForm();
  createUserMessage.value = '';
  createUserStatus.value = '';
  isCreateUserOpen.value = true;
}

function closeCreateUserModal() {
  isCreateUserOpen.value = false;
  createUserMessage.value = '';
  createUserStatus.value = '';
}

function openEditUserModal(user) {
  editUserForm.value = {
    id: user.id,
    nickname: user.nickname,
    email: user.email,
    password: ''
  };
  editUserMessage.value = '';
  editUserStatus.value = '';
  isEditUserOpen.value = true;
}

function closeEditUserModal() {
  isEditUserOpen.value = false;
  editUserMessage.value = '';
  editUserStatus.value = '';
  resetEditUserForm();
}

function openDeleteUserModal(user) {
  userToDelete.value = user;
  deleteUserMessage.value = '';
  isDeleteUserOpen.value = true;
}

function closeDeleteUserModal() {
  isDeleteUserOpen.value = false;
  deleteUserMessage.value = '';
  userToDelete.value = null;
}

async function openParentDetail(user) {
  selectedParentUser.value = user;
  parentDetail.value = null;
  parentDetailMessage.value = '';
  isParentDetailOpen.value = true;
  isLoadingParentDetail.value = true;

  try {
    const response = await apiFetch(`/api/admin/app-users/${user.id}/details`);
    const data = await response.json();

    if (!response.ok) {
      parentDetailMessage.value = data.message;
      return;
    }

    parentDetail.value = data;
  } catch {
    parentDetailMessage.value = 'Unable to load parent details.';
  } finally {
    isLoadingParentDetail.value = false;
  }
}

function closeParentDetail() {
  isParentDetailOpen.value = false;
  selectedParentUser.value = null;
  parentDetail.value = null;
  parentDetailMessage.value = '';
}

async function submitEditUser() {
  editUserMessage.value = '';
  editUserStatus.value = '';

  if (!editUserForm.value.nickname || !editUserForm.value.email) {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Please fill out nickname and email.';
    return;
  }

  if (!isValidEmail(editUserForm.value.email)) {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (editUserForm.value.password && !isValidPassword(editUserForm.value.password)) {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  isSavingUser.value = true;

  try {
    const response = await apiFetch(`/api/users/${editUserForm.value.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nickname: editUserForm.value.nickname,
        username: editUserForm.value.nickname,
        email: editUserForm.value.email,
        password: editUserForm.value.password
      })
    });
    const data = await response.json();

    if (!response.ok) {
      editUserStatus.value = 'error';
      editUserMessage.value = data.message;
      return;
    }

    if (loggedInUser.value?.id === editUserForm.value.id) {
      saveLoggedInUser({
        ...loggedInUser.value,
        nickname: editUserForm.value.nickname,
        email: editUserForm.value.email
      });
    }

    closeEditUserModal();
    await loadUsers();
  } catch {
    editUserStatus.value = 'error';
    editUserMessage.value = 'Unable to reach the server.';
  } finally {
    isSavingUser.value = false;
  }
}

function handleProfileImageChange(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  event.target.value = '';

  if (!file.type.startsWith('image/')) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please choose an image file.';
    return;
  }

  if (file.size > maxProfileImageSize) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please choose an image smaller than 5MB.';
    return;
  }

  const reader = new FileReader();
  reader.addEventListener('load', () => {
    openProfileImageCropper(String(reader.result || ''));
    profileMessage.value = '';
    profileStatus.value = '';
  });
  reader.addEventListener('error', () => {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to load that image.';
  });
  reader.readAsDataURL(file);
}

function openProfileImageCropper(imageSource) {
  cropPosition.value = {
    x: 0,
    y: 0
  };
  cropZoom.value = 1;
  isCropDragging.value = false;
  cropPreview.value = '';
  cropImageElement = new Image();
  cropImageElement.addEventListener('load', () => {
    isCropperOpen.value = true;
    renderCropPreview();
  });
  cropImageElement.addEventListener('error', () => {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to load that image.';
  });
  cropImageElement.src = imageSource;
}

function renderCropPreview() {
  if (!cropImageElement?.naturalWidth || !cropImageElement?.naturalHeight) return;

  const outputSize = 360;
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  if (!context) return;

  const cropSize = Math.min(cropImageElement.naturalWidth, cropImageElement.naturalHeight) / cropZoom.value;
  const maxLeft = Math.max(0, cropImageElement.naturalWidth - cropSize);
  const maxTop = Math.max(0, cropImageElement.naturalHeight - cropSize);
  const sourceX = maxLeft * ((Number(cropPosition.value.x) + 100) / 200);
  const sourceY = maxTop * ((Number(cropPosition.value.y) + 100) / 200);

  canvas.width = outputSize;
  canvas.height = outputSize;
  context.drawImage(
    cropImageElement,
    sourceX,
    sourceY,
    cropSize,
    cropSize,
    0,
    0,
    outputSize,
    outputSize
  );
  cropPreview.value = canvas.toDataURL('image/jpeg', 0.9);
}

function startCropDrag(event) {
  if (!cropPreview.value) return;

  isCropDragging.value = true;
  cropDragStart = {
    pointerX: event.clientX,
    pointerY: event.clientY,
    x: cropPosition.value.x,
    y: cropPosition.value.y
  };
  event.currentTarget.setPointerCapture?.(event.pointerId);
}

function moveCropImage(event) {
  if (!isCropDragging.value) return;

  const frameSize = event.currentTarget.getBoundingClientRect().width || 220;
  const deltaX = event.clientX - cropDragStart.pointerX;
  const deltaY = event.clientY - cropDragStart.pointerY;

  cropPosition.value = {
    x: clamp(cropDragStart.x - (deltaX / frameSize) * 200, -100, 100),
    y: clamp(cropDragStart.y - (deltaY / frameSize) * 200, -100, 100)
  };
  renderCropPreview();
}

function zoomCropImage(event) {
  const nextZoom = cropZoom.value + (event.deltaY < 0 ? 0.16 : -0.16);
  cropZoom.value = clamp(nextZoom, 1, 4);
  renderCropPreview();
}

function stopCropDrag(event) {
  if (!isCropDragging.value) return;

  isCropDragging.value = false;
  try {
    event.currentTarget.releasePointerCapture?.(event.pointerId);
  } catch {
    // The pointer may already be released when the browser fires lostpointercapture.
  }
}

function closeProfileImageCropper() {
  isCropperOpen.value = false;
  isCropDragging.value = false;
  cropPreview.value = '';
  cropImageElement = undefined;
}

function applyProfileImageCrop() {
  if (!cropPreview.value) return;

  profileForm.value.profileImage = cropPreview.value;
  profileMessage.value = '';
  profileStatus.value = '';
  closeProfileImageCropper();
}

function removeProfileImage() {
  profileForm.value.profileImage = '';
  closeProfileImageCropper();
}

async function submitProfile() {
  profileMessage.value = '';
  profileStatus.value = '';

  if (!profileForm.value.nickname || !profileForm.value.email) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please fill out nickname and email.';
    return;
  }

  if (!isValidEmail(profileForm.value.email)) {
    profileStatus.value = 'error';
    profileMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (profileForm.value.password && !isValidPassword(profileForm.value.password)) {
    profileStatus.value = 'error';
    profileMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  isSavingProfile.value = true;

  try {
    const response = await apiFetch(`/api/users/${loggedInUser.value.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nickname: profileForm.value.nickname,
        username: profileForm.value.nickname,
        email: profileForm.value.email,
        password: profileForm.value.password,
        profileImage: profileForm.value.profileImage
      })
    });
    const data = await response.json();

    if (!response.ok) {
      profileStatus.value = 'error';
      profileMessage.value = data.message;
      return;
    }

    saveLoggedInUser({
      ...loggedInUser.value,
      nickname: profileForm.value.nickname,
      email: profileForm.value.email,
      profileImage: profileForm.value.profileImage
    });
    profileForm.value.password = '';
    profileStatus.value = 'success';
    profileMessage.value = data.message;

    if (canManageUsers.value) {
      await loadUsers();
    }
  } catch {
    profileStatus.value = 'error';
    profileMessage.value = 'Unable to reach the server.';
  } finally {
    isSavingProfile.value = false;
  }
}

async function confirmDeleteUser() {
  if (!userToDelete.value) return;

  isDeletingUser.value = true;
  deleteUserMessage.value = '';

  try {
    const deletedUserId = userToDelete.value.id;
    const response = await apiFetch(`/api/users/${deletedUserId}`, {
      method: 'DELETE'
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
    deleteUserMessage.value = 'Unable to reach the server.';
  } finally {
    isDeletingUser.value = false;
  }
}

async function submitCreateUser() {
  createUserMessage.value = '';
  createUserStatus.value = '';

  if (!isValidEmail(createUserForm.value.email)) {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (!isValidPassword(createUserForm.value.password)) {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  if (createUserForm.value.password !== createUserForm.value.verifyPassword) {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Passwords do not match.';
    return;
  }

  isCreatingUser.value = true;

  try {
    const createUserPayload = {
      ...createUserForm.value,
      username: createUserForm.value.nickname
    };

    const response = await apiFetch('/api/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(createUserPayload)
    });
    const data = await response.json();

    if (!response.ok) {
      createUserStatus.value = 'error';
      createUserMessage.value = data.message;
      return;
    }

    closeCreateUserModal();
    await loadUsers();
  } catch {
    createUserStatus.value = 'error';
    createUserMessage.value = 'Unable to reach the server.';
  } finally {
    isCreatingUser.value = false;
  }
}

async function submitSignup() {
  signupMessage.value = '';
  signupStatus.value = '';

  if (!isValidEmail(signupForm.value.email)) {
    signupStatus.value = 'error';
    signupMessage.value = 'Please enter a valid email address.';
    return;
  }

  if (!isValidPassword(signupForm.value.password)) {
    signupStatus.value = 'error';
    signupMessage.value = 'Password must be at least 6 characters and include one number.';
    return;
  }

  if (signupForm.value.password !== signupForm.value.verifyPassword) {
    signupStatus.value = 'error';
    signupMessage.value = 'Passwords do not match.';
    return;
  }

  isBusy.value = true;

  try {
    const signupPayload = {
      ...signupForm.value,
      username: signupForm.value.nickname
    };

    const response = await apiFetch('/api/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(signupPayload)
    });
    const data = await response.json();
    signupStatus.value = response.ok ? 'success' : 'error';
    signupMessage.value = data.message;

    if (response.ok) {
      const createdNickname = signupForm.value.nickname;
      signupForm.value = {
        nickname: '',
        email: '',
        password: '',
        verifyPassword: '',
        role: 'parent'
      };
      loginForm.value = {
        username: createdNickname,
        password: ''
      };
      goTo('/login');
    }
  } catch {
    signupStatus.value = 'error';
    signupMessage.value = 'Unable to reach the server.';
  } finally {
    isBusy.value = false;
  }
}
</script>

<template>
  <main class="shell" :data-theme="currentTheme">
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

    <section v-if="page === 'home'" class="home-panel">
      <p class="eyebrow">Care Portal</p>
      <h1>Admin access</h1>
      <p class="intro">
        Sign in with an admin account to view simulator app users.
      </p>
      <div class="actions">
        <button class="primary-button" type="button" @click="goTo('/login')">Admin Log In</button>
      </div>
    </section>

    <section v-else-if="page === 'welcome'" class="users-page">
      <aside class="sidebar">
        <div class="brand">
          <div class="brand-mark">CP</div>
          <div>
            <strong>Care Portal</strong>
            <span>Welcome</span>
          </div>
        </div>
        <button class="nav-button active" type="button" @click="goTo('/welcome')">Welcome</button>
        <button class="nav-button" type="button" @click="goTo('/profile')">Profile</button>
        <button v-if="canManageUsers" class="nav-button" type="button" @click="goTo('/users')">Users</button>
        <button v-if="canManageUsers" class="nav-button" type="button" @click="goTo('/roles')">Roles</button>
      </aside>

      <section class="workspace">
        <header class="workspace-header">
          <h1>Welcome</h1>
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
            <button v-if="loggedInUser" class="profile-trigger" type="button" @click="goTo('/profile')">
              <span class="avatar small">
                <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </span>
              <span>{{ loggedInUser.nickname }}</span>
            </button>
            <button class="link-button" type="button" @click="logOut">Log Out</button>
          </div>
        </header>

        <section class="table-panel welcome-panel">
          <p class="eyebrow">Care Portal</p>
          <h2>Welcome{{ loggedInUser ? `, ${loggedInUser.nickname}` : '' }}</h2>
          <p class="welcome-copy">
            You are signed in as a {{ loggedInUser?.role }}. Your account can use the portal welcome area.
          </p>
          <div class="welcome-summary">
            <span class="role-pill">{{ loggedInUser?.role }}</span>
            <span>Account ready</span>
          </div>
        </section>
      </section>
    </section>

    <section v-else-if="page === 'profile'" class="users-page">
      <aside class="sidebar">
        <div class="brand">
          <div class="brand-mark">CP</div>
          <div>
            <strong>Care Portal</strong>
            <span>Profile</span>
          </div>
        </div>
        <button class="nav-button" type="button" @click="goTo('/welcome')">Welcome</button>
        <button class="nav-button active" type="button" @click="goTo('/profile')">Profile</button>
        <button v-if="canManageUsers" class="nav-button" type="button" @click="goTo('/users')">Users</button>
        <button v-if="canManageUsers" class="nav-button" type="button" @click="goTo('/roles')">Roles</button>
      </aside>

      <section class="workspace">
        <header class="workspace-header">
          <h1>Profile</h1>
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
            <button v-if="loggedInUser" class="profile-trigger" type="button" @click="goTo('/profile')">
              <span class="avatar small">
                <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </span>
              <span>{{ loggedInUser.nickname }}</span>
            </button>
            <button class="link-button" type="button" @click="logOut">Log Out</button>
          </div>
        </header>

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
                  Account Type
                  <input :value="loggedInUser?.role" disabled />
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
    </section>

    <section v-else-if="page === 'users'" class="users-page">
      <aside class="sidebar">
        <div class="brand">
          <div class="brand-mark">CP</div>
          <div>
            <strong>Care Portal</strong>
            <span>Simulator Users</span>
          </div>
        </div>
        <button class="nav-button" type="button" @click="goTo('/welcome')">Welcome</button>
        <button class="nav-button" type="button" @click="goTo('/profile')">Profile</button>
        <button class="nav-button active" type="button" @click="goTo('/users')">Users</button>
        <button class="nav-button" type="button" @click="goTo('/roles')">Roles</button>
      </aside>

      <section class="workspace">
        <header class="workspace-header">
          <h1>Simulator App Users</h1>
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
            <button v-if="loggedInUser" class="profile-trigger" type="button" @click="goTo('/profile')">
              <span class="avatar small">
                <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </span>
              <span>{{ loggedInUser.nickname }}</span>
            </button>
            <button class="link-button" type="button" @click="logOut">Log Out</button>
          </div>
        </header>

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
                  <th>Role</th>
                  <th>Created Time</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="!isLoadingUsers && users.length === 0">
                  <td colspan="5" class="empty-cell">No users found.</td>
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
                    </div>
                  </td>
                  <td>{{ user.email }}</td>
                  <td><span class="role-pill" :class="roleClass(user.role)">{{ user.role }}</span></td>
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
      </section>

      <div v-if="isParentDetailOpen" class="modal-backdrop" @click.self="closeParentDetail">
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

          <p v-if="parentDetailMessage" class="message error">{{ parentDetailMessage }}</p>
          <p v-if="isLoadingParentDetail" class="message">Loading parent details...</p>

          <div v-if="parentDetail && !isLoadingParentDetail" class="parent-detail-grid">
            <section class="detail-section">
              <h3>Parent Account</h3>
              <dl class="detail-list">
                <div>
                  <dt>Username</dt>
                  <dd>{{ parentDetail.user.nickname }}</dd>
                </div>
                <div>
                  <dt>Email</dt>
                  <dd>{{ parentDetail.user.email }}</dd>
                </div>
                <div>
                  <dt>Created</dt>
                  <dd>{{ parentDetail.user.createdAt }}</dd>
                </div>
                <div>
                  <dt>Last App Sync</dt>
                  <dd>{{ parentDetail.appDataUpdatedAt || 'Not synced yet' }}</dd>
                </div>
              </dl>
            </section>

            <section class="detail-section">
              <h3>Child Information</h3>
              <div v-if="hasChildInfo(parentDetail.childProfile)" class="detail-list">
                <div v-for="row in childInfoRows(parentDetail.childProfile)" :key="row.label">
                  <dt>{{ row.label }}</dt>
                  <dd>{{ row.value || '' }}</dd>
                </div>
              </div>
              <p v-else class="empty-note">No child information synced yet.</p>
            </section>

            <section class="detail-section full-detail-section">
              <h3>History</h3>
              <div v-if="parentDetail.healthLogs?.length" class="history-list">
                <article v-for="log in parentDetail.healthLogs.slice().reverse()" :key="log.id" class="history-item">
                  <div>
                    <strong>{{ log.title }}</strong>
                    <span>{{ logTypeLabel(log) }} · {{ formatLogTimestamp(log.timestamp) }}</span>
                  </div>
                  <span class="severity-pill">{{ log.severity }}/5</span>
                  <p v-if="log.value">{{ log.value }}</p>
                  <p v-if="log.comments">{{ log.comments }}</p>
                </article>
              </div>
              <p v-else class="empty-note">No history synced yet.</p>
            </section>
          </div>
        </section>
      </div>

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

            <fieldset>
              <legend>Account Type</legend>
              <div class="role-options">
                <label v-for="role in roleOptions" :key="role.value" class="role-choice">
                  <input v-model="createUserForm.role" type="radio" name="create-user-role" :value="role.value" />
                  <span>{{ role.label }}</span>
                </label>
              </div>
            </fieldset>

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
    </section>

    <section v-else-if="page === 'roles'" class="users-page">
      <aside class="sidebar">
        <div class="brand">
          <div class="brand-mark">CP</div>
          <div>
            <strong>Care Portal</strong>
            <span>Role Access</span>
          </div>
        </div>
        <button class="nav-button" type="button" @click="goTo('/welcome')">Welcome</button>
        <button class="nav-button" type="button" @click="goTo('/profile')">Profile</button>
        <button class="nav-button" type="button" @click="goTo('/users')">Users</button>
        <button class="nav-button active" type="button" @click="goTo('/roles')">Roles</button>
      </aside>

      <section class="workspace">
        <header class="workspace-header">
          <h1>Role Management</h1>
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
            <button v-if="loggedInUser" class="profile-trigger" type="button" @click="goTo('/profile')">
              <span class="avatar small">
                <img v-if="loggedInUser.profileImage" :src="loggedInUser.profileImage" alt="" />
                <span v-else>{{ userInitials(loggedInUser) }}</span>
              </span>
              <span>{{ loggedInUser.nickname }}</span>
            </button>
            <button class="link-button" type="button" @click="logOut">Log Out</button>
          </div>
        </header>

        <section class="table-panel">
          <div class="table-heading">
            <div>
              <p class="eyebrow">System</p>
              <h2>Edit User Roles</h2>
            </div>
            <button class="primary-button compact" type="button" @click="loadUsers" :disabled="isLoadingUsers">
              {{ isLoadingUsers ? 'Loading...' : 'Refresh' }}
            </button>
          </div>

          <p v-if="rolesMessage" class="message" :class="{ error: rolesStatus === 'error' }">
            {{ rolesMessage }}
          </p>

          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Nickname</th>
                  <th>Email</th>
                  <th>Current Role</th>
                  <th>Change Role</th>
                  <th>Save</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="!isLoadingUsers && users.length === 0">
                  <td colspan="5" class="empty-cell">No users found.</td>
                </tr>
                <tr v-for="user in users" :key="user.id">
                  <td>
                    <div class="user-cell">
                      <span class="avatar tiny">
                        <img v-if="user.profileImage" :src="user.profileImage" alt="" />
                        <span v-else>{{ userInitials(user) }}</span>
                      </span>
                      <span>{{ user.nickname }}</span>
                    </div>
                  </td>
                  <td>{{ user.email }}</td>
                  <td><span class="role-pill" :class="roleClass(user.role)">{{ user.role }}</span></td>
                  <td>
                    <select v-model="user.pendingRole" class="role-select" :class="roleClass(user.pendingRole)">
                      <option v-for="role in roleOptions" :key="role.value" :value="role.value">
                        {{ role.label }}
                      </option>
                    </select>
                  </td>
                  <td>
                    <button
                      class="primary-button compact"
                      type="button"
                      :disabled="savingRoleUserId === user.id || user.pendingRole === user.role"
                      @click="saveUserRole(user)"
                    >
                      {{ savingRoleUserId === user.id ? 'Saving...' : 'Save Role' }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="table-footer">
            Total {{ users.length }}
          </div>
        </section>
      </section>
    </section>

    <section v-else-if="page === 'login'" class="form-panel">
      <button class="back-button" type="button" @click="goTo('/')">Back</button>
      <h1>Admin Log In</h1>
      <form @submit.prevent="submitLogin">
        <label>
          Admin Username
          <input v-model="loginForm.username" autocomplete="username" required />
        </label>
        <label>
          Password
          <input v-model="loginForm.password" type="password" autocomplete="current-password" required />
        </label>
        <button class="primary-button full" type="submit" :disabled="isBusy">
          {{ isBusy ? 'Logging in...' : 'Log In' }}
        </button>
      </form>
      <p v-if="loginMessage" class="message" :class="{ error: loginStatus === 'error' }">
        {{ loginMessage }}
      </p>
    </section>

    <section v-else class="form-panel wide">
      <button class="back-button" type="button" @click="goTo('/')">Back</button>
      <h1>Sign Up</h1>
      <form @submit.prevent="submitSignup">
        <div class="grid">
          <label>
            Make Nickname
            <input v-model="signupForm.nickname" autocomplete="nickname" required />
          </label>
          <label>
            Email
            <input v-model="signupForm.email" type="email" autocomplete="email" required />
          </label>
          <label>
            Password
            <input
              v-model="signupForm.password"
              type="password"
              autocomplete="new-password"
              minlength="6"
              pattern="(?=.*[0-9]).{6,}"
              required
            />
          </label>
          <label>
            Verify Password
            <input v-model="signupForm.verifyPassword" type="password" autocomplete="new-password" required />
          </label>
        </div>

        <fieldset>
          <legend>Account Type</legend>
          <div class="role-options">
            <label v-for="role in roleOptions" :key="role.value" class="role-choice">
              <input v-model="signupForm.role" type="radio" name="role" :value="role.value" />
              <span>{{ role.label }}</span>
            </label>
          </div>
        </fieldset>

        <button class="primary-button full" type="submit" :disabled="isBusy">
          {{ isBusy ? 'Creating account...' : 'Create Account' }}
        </button>
      </form>
      <p v-if="signupMessage" class="message" :class="{ error: signupStatus === 'error' }">
        {{ signupMessage }}
      </p>
    </section>
  </main>
</template>
