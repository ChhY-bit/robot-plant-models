import { readFileSync } from 'node:fs'

// The root file is shared with MATLAB queries and release packaging.
const version = readFileSync(new URL('../../VERSION', import.meta.url), 'utf8').trim()
if (!/^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$/.test(version)) {
  throw new Error('VERSION must contain a numeric major.minor.patch value.')
}

// Build-time metadata; browser components receive it through VitePress config.
export const project = {
  name: 'Robot Plant Models',
  version,
  repository: 'https://github.com/ChhY-bit/robot-plant-models',
  releases: 'https://github.com/ChhY-bit/robot-plant-models/releases',
  base: process.env.PAGES_BASE || '/robot-plant-models/'
}

// Future translations mirror the English tree under pages/zh/, pages/ja/, etc.
// Add a locale only when its landing page and interface translations are ready.
export { languages } from './languages.mjs'
