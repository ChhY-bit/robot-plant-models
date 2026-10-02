import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join, basename } from 'node:path'

// Optional presentation metadata. Unknown documents are still discovered.
export const presentation = {
  'Get-Started': { label: 'Get Started', order: ['Overview', 'Installation', 'Quickstart'] },
  'Robots': { label: 'Robots', order: ['Ackermann-Robot', 'Wheel-Robot'] },
  'Installation': { label: 'Installation', order: ['MATLAB-Installation', 'Python-Installation'] },
  'Quickstart': { label: 'Quickstart', order: ['MATLAB-Quickstart', 'Python-Quickstart'] },
  'Ackermann-Robot': { label: 'Ackermann Robot', order: ['API-Reference', 'Modeling'] },
  'Wheel-Robot': { label: 'Wheel Robot', order: ['API-Reference', 'Modeling'] },
  'API-Reference': { label: 'API Reference', order: ['Introduction', 'Properties', 'Methods'] },
  'MATLAB-Installation': { label: 'MATLAB' },
  'Python-Installation': { label: 'Python' },
  'MATLAB-Quickstart': { label: 'MATLAB' },
  'Python-Quickstart': { label: 'Python' },
  'ackermann-robot-model': { label: 'Model theory' },
  'wheel-robot-model': { label: 'Model theory' }
}

export function friendlyName(name) {
  return presentation[name]?.label || name.replace(/[-_]/g, ' ')
}

// Keep existing GitHub-style links in the API Markdown valid on the website.
export function headingSlug(text) {
  return text.toLowerCase().trim().replace(/<[^>]*>/g, '')
    .replace(/[^\p{L}\p{N}\p{M}_\-\s]/gu, '').replace(/\s/g, '-')
}

export function scanSection(root, section, locale = '') {
  const source = join(root, locale, section)
  if (!existsSync(source)) return []
  const walk = (directory, relative, depth = 0) => {
    const entries = readdirSync(directory, { withFileTypes: true })
      .filter(entry => !entry.name.startsWith('.') && !entry.name.startsWith('_'))
      .filter(entry => entry.isDirectory() || entry.name.endsWith('.md'))
    const order = presentation[basename(directory)]?.order || []
    const key = entry => entry.name.replace(/\.md$/, '')
    const rank = entry => order.includes(key(entry)) ? order.indexOf(key(entry)) : order.length
    entries.sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name, 'en'))
    return entries.flatMap(entry => {
      const relativePath = `${relative}/${entry.name}`
      if (entry.isDirectory()) {
        const items = walk(join(directory, entry.name), relativePath, depth + 1)
        return items.length ? [{ text: friendlyName(entry.name), collapsed: depth > 0, items }] : []
      }
      const text = readFileSync(join(directory, entry.name), 'utf8')
      if (/^sidebar:\s*false\s*$/m.test(text.split(/^---\s*$/m)[1] || '')) return []
      return [{ text: friendlyName(key(entry)), link: relativePath.replace(/\.md$/, '') }]
    })
  }
  return walk(source, `${locale ? `/${locale}` : ''}/${section}`)
}

export function flattenNavigation(items) {
  return items.flatMap(item => item.link ? [item] : flattenNavigation(item.items || []))
}

export function pageInfo(root, relativePath) {
  const source = readFileSync(join(root, relativePath), 'utf8')
  const body = source.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '')
  const heading = /^#\s+(.+)$/m.exec(body)?.[1].replace(/[`*_]/g, '').trim()
  const title = heading || basename(relativePath, '.md').replace(/[-_]/g, ' ')
  return {
    title,
    titleSlug: headingSlug(title),
    placeholder: !body.trim(),
    parts: relativePath.replace(/\.md$/, '').split('/')
  }
}
