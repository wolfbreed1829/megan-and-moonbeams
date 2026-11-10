import { runGleam } from './gleam.mjs';
import { build } from 'vite';
runGleam(['build']);
await build({ base: process.env.SITE_BASE_PATH || '/' });
