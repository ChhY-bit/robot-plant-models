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
  'API-Reference': { label: 'API Reference', order: ['Introduction', 'Properties', 'Methods', 'Utils'] },
  'MATLAB-Installation': { label: 'MATLAB' },
  'Python-Installation': { label: 'Python' },
  'MATLAB-Quickstart': { label: 'MATLAB' },
  'Python-Quickstart': { label: 'Python' },
  'ackermann-robot-model': { label: 'Model theory' },
  'wheel-robot-model': { label: 'Model theory' }
}

const chineseLabels = {
  'Get-Started': '入门指南', Robots: '机器人', Overview: '概述', Installation: '安装',
  Quickstart: '快速开始', 'Ackermann-Robot': '阿克曼机器人', 'Wheel-Robot': '差速轮式机器人',
  'API-Reference': 'API 参考', Introduction: '简介', Properties: '属性', Methods: '方法', Utils: '工具函数',
  Modeling: '模型理论', 'ackermann-robot-model': '模型理论', 'wheel-robot-model': '模型理论',
  'MATLAB-Installation': 'MATLAB', 'Python-Installation': 'Python',
  'MATLAB-Quickstart': 'MATLAB', 'Python-Quickstart': 'Python'
}

export function friendlyName(name, locale = '') {
  return (locale === 'zh' ? chineseLabels[name] : undefined) || presentation[name]?.label || name.replace(/[-_]/g, ' ')
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
        return items.length ? [{ text: friendlyName(entry.name, locale), collapsed: depth > 0, items }] : []
      }
      const text = readFileSync(join(directory, entry.name), 'utf8')
      if (/^sidebar:\s*false\s*$/m.test(text.split(/^---\s*$/m)[1] || '')) return []
      return [{ text: friendlyName(key(entry), locale), link: relativePath.replace(/\.md$/, '') }]
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
  const rawHeading = /^#\s+(.+)$/m.exec(body)?.[1]
  const explicitAnchor = /\{#([^}]+)\}\s*$/.exec(rawHeading || '')?.[1]
  const heading = rawHeading?.replace(/\s*\{#[^}]+\}\s*$/, '').replace(/[`*_]/g, '').trim()
  const title = heading || friendlyName(basename(relativePath, '.md'), relativePath.startsWith('zh/') ? 'zh' : '')
  return {
    title,
    titleSlug: explicitAnchor || headingSlug(title),
    placeholder: !body.trim(),
    parts: relativePath.replace(/\.md$/, '').split('/'),
    labels: relativePath.replace(/\.md$/, '').split('/').map(part => friendlyName(part, relativePath.startsWith('zh/') ? 'zh' : ''))
  }
}
