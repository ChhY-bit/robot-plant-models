import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'
import { project } from '../.vitepress/site.mjs'

const dist = fileURLToPath(new URL('../.vitepress/dist/', import.meta.url))
if (!existsSync(dist)) throw new Error('Run npm run build before checking generated links.')
function walk(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => entry.isDirectory()
    ? walk(join(directory, entry.name)) : entry.name.endsWith('.html') ? [join(directory, entry.name)] : [])
}
const documents = new Map(walk(dist).map(file => [relative(dist, file).replaceAll('\\', '/'), readFileSync(file, 'utf8')]))
const errors = []
let checked = 0
for (const [file, html] of documents) {
  const url = new URL(`${project.base}${file}`, 'https://local.test')
  const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map(match => match[1])
  if (new Set(ids).size !== ids.length) errors.push(`${file}: duplicate HTML IDs`)
  if (file !== '404.html' && (html.match(/<h1\b/g) || []).length !== 1) errors.push(`${file}: expected exactly one H1`)
  for (const match of html.matchAll(/<a\b[^>]*\bhref="([^"]+)"/g)) {
    const href = match[1].replaceAll('&amp;', '&')
    if (!href || /^(?:https?:|mailto:|tel:)/.test(href)) continue
    const target = new URL(href, url)
    if (!target.pathname.startsWith(project.base)) { errors.push(`${file}: outside configured base: ${href}`); continue }
    const path = decodeURIComponent(target.pathname.slice(project.base.length))
    const candidates = [path, `${path}.html`, `${path.replace(/\/$/, '')}/index.html`]
    if (!path) candidates.unshift('index.html')
    const document = candidates.find(candidate => documents.has(candidate))
    if (!document) { errors.push(`${file}: missing target: ${href}`); continue }
    checked++
    if (target.hash) {
      const id = decodeURIComponent(target.hash.slice(1))
      if (!documents.get(document).includes(`id="${id}"`)) errors.push(`${file}: missing anchor: ${href}`)
    }
  }
}
if (errors.length) {
  console.error(errors.join('\n'))
  process.exitCode = 1
} else {
  console.log(`Validated ${documents.size} HTML pages and ${checked} internal links/anchors; one H1 per page, no duplicate IDs.`)
}
