import { existsSync, mkdirSync, readdirSync, symlinkSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

export const gleam = process.env.GLEAM_BIN || (existsSync(fileURLToPath(new URL('../.tools/gleam/gleam.exe', import.meta.url)))
  ? fileURLToPath(new URL('../.tools/gleam/gleam.exe', import.meta.url)) : 'gleam');

export function runGleam(args, fatal = true) {
  // Directory junctions let Gleam build on Windows without elevated symlink
  // privileges. All links stay inside the disposable build directory.
  if (process.platform === 'win32' && ['build', 'check'].includes(args[0])) {
    if (!existsSync('build/packages/lustre')) runGleam(['deps', 'download']);
    for (const entry of readdirSync('build/packages', { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const source = resolve('build/packages', entry.name, 'priv');
      const target = resolve('build/dev/javascript', entry.name, 'priv');
      if (existsSync(source) && !existsSync(target)) {
        mkdirSync(resolve(target, '..'), { recursive: true });
        symlinkSync(source, target, 'junction');
      }
    }
  }
  const result = spawnSync(gleam, args, { stdio: 'inherit' });
  if (result.error) console.error('Install Gleam or set GLEAM_BIN to its executable.', result.error.message);
  if (result.status !== 0 && fatal) process.exit(result.status || 1);
  return result.status === 0;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) runGleam(process.argv.slice(2));
