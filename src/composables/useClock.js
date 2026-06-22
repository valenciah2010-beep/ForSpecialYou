import { onMounted, onUnmounted, ref } from 'vue';

function currentClockTime() {
  const now = new Date();
  const hours24 = now.getHours();
  const hours12 = hours24 % 12 || 12;

  return {
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

export function useClock() {
  const clockTime = ref(currentClockTime());
  let clockTimer;

  function updateClock() {
    clockTime.value = currentClockTime();
  }

  onMounted(() => {
    updateClock();
    clockTimer = window.setInterval(updateClock, 1000);
  });

  onUnmounted(() => {
    window.clearInterval(clockTimer);
  });

  return {
    clockTime,
    updateClock
  };
}
