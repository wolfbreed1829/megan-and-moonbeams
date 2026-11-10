let narration;
let generation = 0;

export function stopNarration() {
  generation++;
  if ('speechSynthesis' in window) window.speechSynthesis.cancel();
  narration = null;
}

export function narrate(content, ended, failed) {
  stopNarration();
  if (!('speechSynthesis' in window)) { failed(); return; }
  const current = generation;
  narration = new SpeechSynthesisUtterance(content);
  narration.lang = 'en-US';
  narration.rate = 0.87;
  narration.pitch = 1;
  narration.onend = () => { if (current === generation) ended(); };
  narration.onerror = () => { if (current === generation) failed(); };
  window.speechSynthesis.speak(narration);
}

window.addEventListener('pagehide', stopNarration);
