// Browser-only choreography. Story state and navigation remain in Gleam.
import { setupOcean } from './ocean.js';

export function setupAtmosphere(root) {
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  const pointer = window.matchMedia('(hover: hover) and (pointer: fine)');
  const transitions = new Set();
  let frame = 0;
  let currentX = 0;
  let currentY = 0;
  let targetX = 0;
  let targetY = 0;
  let previousFeatured = '';
  let previousPanel = '';
  let introComplete = false;

  const motionAllowed = () => !reduced.matches
    && !root.classList.contains('motion-paused') && !document.hidden;
  const canLook = () => motionAllowed() && pointer.matches && !root.querySelector('dialog');
  const ocean = setupOcean(root.querySelector('.ocean-surface'), () => motionAllowed() && !root.querySelector('dialog'));

  function resetLook() {
    cancelAnimationFrame(frame);
    frame = 0;
    currentX = currentY = targetX = targetY = 0;
    root.style.setProperty('--look-x', '0px');
    root.style.setProperty('--look-y', '0px');
  }

  function move() {
    if (!canLook()) { resetLook(); return; }
    currentX += (targetX - currentX) * 0.045;
    currentY += (targetY - currentY) * 0.045;
    root.style.setProperty('--look-x', `${currentX.toFixed(2)}px`);
    root.style.setProperty('--look-y', `${currentY.toFixed(2)}px`);
    if (Math.abs(targetX - currentX) + Math.abs(targetY - currentY) > 0.03) {
      frame = requestAnimationFrame(move);
    } else frame = 0;
  }

  function onPointer(event) {
    if (!canLook() || event.pointerType !== 'mouse') return;
    targetX = (event.clientX / window.innerWidth - 0.5) * 30;
    targetY = (event.clientY / window.innerHeight - 0.5) * 20;
    if (!frame) frame = requestAnimationFrame(move);
  }

  function onLeave() {
    targetX = targetY = 0;
    if (!frame && canLook()) frame = requestAnimationFrame(move);
  }

  function reveal(node, delay = 0) {
    if (!node || !motionAllowed()) return;
    // Do not stack entrance effects when a visitor changes chapters quickly.
    for (const animation of transitions) {
      if (animation.effect?.target === node) animation.finish();
    }
    const animation = node.animate([
      { opacity: 0, transform: 'translateY(18px)', filter: 'blur(5px)' },
      { opacity: 1, transform: 'translateY(0)', filter: 'blur(0)' },
    ], { duration: 650, delay, easing: 'cubic-bezier(.16,1,.3,1)', fill: 'backwards' });
    transitions.add(animation);
    const cleanup = () => transitions.delete(animation);
    animation.onfinish = cleanup;
    animation.oncancel = cleanup;
  }

  function sync() {
    root.toggleAttribute('data-motion-dormant', document.hidden);
    if (reduced.matches || root.classList.contains('motion-paused')) introComplete = true;
    root.toggleAttribute('data-entered', introComplete);
    ocean.sync();
    if (!canLook()) resetLook();
    if (!motionAllowed()) {
      for (const animation of transitions) animation.finish();
    }

    const featured = root.querySelector('.featured-title');
    const featuredText = featured?.textContent || '';
    if (previousFeatured && featuredText !== previousFeatured) {
      reveal(featured);
      reveal(root.querySelector('.story-number'), 60);
    }
    previousFeatured = featuredText;

    const dialog = root.querySelector('dialog');
    const content = dialog?.querySelector('.dialog-content');
    const panelKey = dialog ? [
      dialog.getAttribute('aria-label'),
      dialog.querySelector('.mode.active')?.textContent,
      dialog.querySelector('.reading h3, .listen-preview h3')?.textContent,
    ].join('|') : '';
    if (panelKey && panelKey !== previousPanel) {
      if (previousPanel) {
        reveal(dialog.querySelector('.reading, .listen-preview, .film-preview') || content);
      } else {
        [...content.children].forEach((node, index) => reveal(node, Math.min(index * 65, 260)));
      }
    }
    previousPanel = panelKey;
  }

  const observer = new MutationObserver(sync);
  observer.observe(root, {
    childList: true, subtree: true, characterData: true,
    attributes: true, attributeFilter: ['class', 'aria-label'],
  });
  document.addEventListener('pointermove', onPointer, { passive: true });
  document.documentElement.addEventListener('pointerleave', onLeave);
  document.addEventListener('visibilitychange', sync);
  reduced.addEventListener('change', sync);
  pointer.addEventListener('change', sync);
  function onEntranceEnd(event) {
    if (event.animationName === 'word-reveal' && event.target.classList.contains('word-four')) {
      introComplete = true;
      root.setAttribute('data-entered', '');
    }
  }
  root.addEventListener('animationend', onEntranceEnd);
  sync();

  return () => {
    observer.disconnect();
    ocean.destroy();
    resetLook();
    for (const animation of transitions) animation.cancel();
    document.removeEventListener('pointermove', onPointer);
    document.documentElement.removeEventListener('pointerleave', onLeave);
    document.removeEventListener('visibilitychange', sync);
    reduced.removeEventListener('change', sync);
    pointer.removeEventListener('change', sync);
    root.removeEventListener('animationend', onEntranceEnd);
  };
}
