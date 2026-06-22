import { ref } from 'vue';

export const themeOptions = [
  { value: 'green', label: 'Green', color: '#27695d' },
  { value: 'blue', label: 'Blue', color: '#2f6df6' },
  { value: 'rose', label: 'Rose', color: '#be3455' },
  { value: 'gold', label: 'Gold', color: '#b7791f' },
  { value: 'sakura', label: 'Sakura', color: '#d95f8d', icon: 'flower' }
];

export function useTheme() {
  const savedTheme = localStorage.getItem('carePortalTheme');
  const currentTheme = ref(savedTheme || 'green');
  const isThemeMenuOpen = ref(false);

  function setTheme(theme) {
    currentTheme.value = theme;
    localStorage.setItem('carePortalTheme', theme);
    isThemeMenuOpen.value = false;
  }

  return {
    currentTheme,
    isThemeMenuOpen,
    setTheme,
    themeOptions
  };
}
