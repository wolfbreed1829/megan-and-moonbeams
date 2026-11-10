// A quiet, original surf soundscape, generated locally from filtered noise.
// No audio context is created until the visitor explicitly turns sound on.
let context;
let master;
let enabled = false;
let narrating = false;
let suspension;
let revision = 0;
let reportFailure = () => {};

function createSurf() {
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) throw new Error('Audio unavailable');
  context = new AudioContext();
  master = context.createGain();
  master.gain.value = 0;
  master.connect(context.destination);

  const buffer = context.createBuffer(2, context.sampleRate * 16, context.sampleRate);
  for (let channel = 0; channel < 2; channel++) {
    const samples = buffer.getChannelData(channel);
    let brown = 0;
    for (let i = 0; i < samples.length; i++) {
      const white = Math.random() * 2 - 1;
      brown = (brown + 0.025 * white) / 1.025;
      samples[i] = brown * 2.8 + white * 0.16;
    }
  }

  for (let layer = 0; layer < 2; layer++) {
    const noise = context.createBufferSource();
    noise.buffer = buffer;
    noise.loop = true;
    const lowpass = context.createBiquadFilter();
    lowpass.type = 'lowpass';
    lowpass.frequency.value = layer ? 1400 : 650;
    lowpass.Q.value = 0.45;
    const highpass = context.createBiquadFilter();
    highpass.type = 'highpass';
    highpass.frequency.value = layer ? 210 : 75;
    const swell = context.createGain();
    swell.gain.value = layer ? 0.3 : 0.55;
    const tide = context.createOscillator();
    tide.type = 'sine';
    tide.frequency.value = layer ? 0.091 : 0.066;
    const depth = context.createGain();
    depth.gain.value = layer ? 0.16 : 0.26;
    tide.connect(depth).connect(swell.gain);
    noise.connect(lowpass).connect(highpass).connect(swell).connect(master);
    noise.start(0, layer * 5.3);
    tide.start();
  }
}

function adjustVolume() {
  if (!context || !master) return;
  clearTimeout(suspension);
  const audible = enabled && !document.hidden;
  const volume = audible ? (narrating ? 0.1 : 0.32) : 0;
  master.gain.cancelScheduledValues(context.currentTime);
  master.gain.setTargetAtTime(volume, context.currentTime, audible ? 0.8 : 0.09);
  if (!audible) suspension = setTimeout(() => {
    if (!enabled || document.hidden) context.suspend().catch(() => {});
  }, 500);
}

export function setNarrationActive(value) {
  narrating = value;
  adjustVolume();
}

export function setOceanSound(value, complete, failed) {
  const request = ++revision;
  enabled = value;
  reportFailure = failed;
  try {
    if (value && !context) createSurf();
    if (!value) { adjustVolume(); complete(false); return; }
    clearTimeout(suspension);
    context.resume().then(() => {
      if (request !== revision) return;
      adjustVolume();
      complete(true);
    }).catch(() => {
      if (request !== revision) return;
      enabled = false;
      adjustVolume();
      failed();
    });
  } catch {
    enabled = false;
    adjustVolume();
    failed();
  }
}

document.addEventListener('visibilitychange', () => {
  if (enabled && !document.hidden && context) {
    context.resume().then(adjustVolume).catch(() => {
      enabled = false;
      adjustVolume();
      reportFailure();
    });
  } else adjustVolume();
});
window.addEventListener('pagehide', () => {
  clearTimeout(suspension);
  context?.suspend().catch(() => {});
});
window.addEventListener('pageshow', () => {
  if (enabled && !document.hidden && context) context.resume().then(adjustVolume).catch(() => {});
});
