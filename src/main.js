import { main } from '../build/dev/javascript/megan_and_moonbeams/megan_and_moonbeams.mjs';
import { setupAtmosphere } from './atmosphere.js';

// Native dialogs supply focus containment and make the background inert.
// The observer only bridges browser behavior; Gleam owns all application state.
let activeDialog = null;
let returnFocus = null;
let activeTitle = '';
let disposeAtmosphere;
const observer = new MutationObserver(() => {
  const experience = document.querySelector('.experience');
  if (experience && !disposeAtmosphere) disposeAtmosphere = setupAtmosphere(experience);
  const dialog = document.querySelector('dialog[data-dialog]');
  if (dialog && dialog !== activeDialog) {
    returnFocus = document.activeElement;
    activeDialog = dialog;
    activeTitle = dialog.getAttribute('aria-label');
    dialog.addEventListener('cancel', event => event.preventDefault());
    dialog.showModal();
    document.body.classList.add('dialog-open');
  } else if (!dialog && activeDialog) {
    activeDialog = null;
    document.body.classList.remove('dialog-open');
    if (returnFocus?.isConnected) returnFocus.focus({ preventScroll: true });
    else document.querySelector('.enter-button')?.focus({ preventScroll: true });
  } else if (dialog && activeTitle !== dialog.getAttribute('aria-label')) {
    activeTitle = dialog.getAttribute('aria-label');
    dialog.scrollTop = 0;
    dialog.querySelector('.close-button')?.focus({ preventScroll: true });
  }
});
observer.observe(document.getElementById('app'), { childList: true, subtree: true, attributes: true, attributeFilter: ['aria-label'] });
main();

if (import.meta.hot) import.meta.hot.dispose(() => {
  observer.disconnect();
  disposeAtmosphere?.();
});
