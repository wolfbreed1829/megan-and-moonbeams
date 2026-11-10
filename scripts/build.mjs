import { runGleam } from './gleam.mjs';
import { build } from 'vite';
runGleam(['build']);
const { render_entry } = await import('../build/dev/javascript/megan_and_moonbeams/megan_and_moonbeams.mjs');
const entry = render_entry();
await build({
  base: process.env.SITE_BASE_PATH || '/',
  plugins: [{
    name: 'prerender-lustre-entry',
    transformIndexHtml: {
      order: 'pre',
      handler: html => html.replace('<!--app-html-->', entry),
    },
  }],
});
