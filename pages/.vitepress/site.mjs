// Public repository and release links.
export const project = {
  name: 'Robot Plant Models',
  repository: 'https://github.com/ChhY-bit/robot-plant-models',
  releases: 'https://github.com/ChhY-bit/robot-plant-models/releases',
  base: process.env.PAGES_BASE || '/robot-plant-models/'
}

// Future translations mirror the English tree under pages/zh/, pages/ja/, etc.
// Add a locale only when its landing page and interface translations are ready.
export { languages } from './languages.mjs'
