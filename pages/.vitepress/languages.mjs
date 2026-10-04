// Browser-safe language metadata. Translations use mirrored locale directories.
export const languages = [
  { code: 'root', label: 'English', lang: 'en' },
  { code: 'zh', label: '简体中文', lang: 'zh-CN' }
]

// Canonical document paths and anchors are identical in each language mirror.
export function languageLink(relativePath, code, hash = '') {
  const canonical = relativePath.replace(/^zh\//, '').replace(/\.md$/, '').replace(/(^|\/)index$/, '$1')
  return `/${code === 'root' ? '' : `${code}/`}${canonical}${hash}`
}
