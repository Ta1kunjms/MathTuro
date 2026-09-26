import dotenv from 'dotenv';
import { existsSync } from 'node:fs';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

// 1. Load workspace local overrides first with highest priority
dotenv.config({ path: '.env.local', override: true });

// 2. Load external secrets file second with fallback priority (override: false)
// Note: path resolution here resolves relative to process.cwd(), not import.meta.url
const externalSecretsPath = resolve(process.env.MATHTURO_SECRETS_PATH || '../.mathturo-secrets/.env');
if (existsSync(externalSecretsPath)) {
  dotenv.config({ path: externalSecretsPath, override: false });
}

// 3. Load default workspace .env last as final fallback (override: false)
dotenv.config({ path: '.env', override: false });

const requiredVariables = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
const missingVariables = requiredVariables.filter((name) => !process.env[name]?.trim());

if (missingVariables.length > 0) {
  throw new Error(`Missing required environment variable(s): ${missingVariables.join(', ')}`);
}

const runtimeConfig = `window.__RUNTIME_CONFIG__ = ${JSON.stringify({
  SUPABASE_URL: process.env.SUPABASE_URL.trim(),
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY.trim()
}, null, 2)};\n`;

const outputPaths = [
  resolve('shared/js/runtime-config.js'),
  resolve('public/shared/js/runtime-config.js')
];

for (const outputPath of outputPaths) {
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, runtimeConfig, 'utf8');
}

console.log(`Generated runtime configuration for ${outputPaths.length} browser config path(s).`);
