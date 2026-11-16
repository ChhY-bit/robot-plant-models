// Browser-safe language metadata. Translations use mirrored locale directories.
export const languages = [
  { code: 'root', label: 'English', lang: 'en' },
  { code: 'zh', label: '简体中文', lang: 'zh-CN' }
]

// English models use Models/ while the Chinese tree still uses Robots/.
export function languageLink(relativePath, code, hash = '') {
  const canonical = relativePath.replace(/^zh\//, '').replace(/^(?:Models|Robots)\//, code === 'root' ? 'Models/' : 'Robots/')
    .replace(/\.md$/, '').replace(/(^|\/)index$/, '$1')
  return `/${code === 'root' ? '' : `${code}/`}${canonical}${hash}`
}
