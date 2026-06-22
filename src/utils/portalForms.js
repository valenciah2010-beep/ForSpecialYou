export function blankLoginForm() {
  return { username: '', password: '' };
}

export function blankSignupForm() {
  return {
    nickname: '',
    email: '',
    password: '',
    verifyPassword: ''
  };
}

export function blankEditUserForm() {
  return {
    id: null,
    nickname: '',
    email: '',
    password: ''
  };
}

export function blankProfileForm() {
  return {
    nickname: '',
    email: '',
    password: '',
    profileImage: ''
  };
}
