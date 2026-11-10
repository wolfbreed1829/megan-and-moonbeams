import { watch } from 'node:fs';
import { createServer } from 'vite';
import { runGleam } from './gleam.mjs';
runGleam(['build']);
const server = await createServer({ server: { host: '127.0.0.1', port: 5173, strictPort: true } });
await server.listen();
server.printUrls();
let timer;
watch('src', { recursive: true }, (_event, filename) => {
  if (!filename || !/\.(gleam|mjs)$/.test(filename)) return;
  clearTimeout(timer);
  timer = setTimeout(() => {
    if (runGleam(['build'], false)) server.ws.send({ type: 'full-reload' });
  }, 180);
});
