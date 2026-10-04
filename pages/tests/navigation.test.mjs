import test from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, readdirSync, readFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { scanSection, flattenNavigation, pageInfo, headingSlug } from '../.vitepress/navigation.mjs'
import { languageLink } from '../.vitepress/languages.mjs'

const root = fileURLToPath(new URL('../', import.meta.url))

test('heading slugs preserve the existing API link conventions', () => {
  assert.equal(headingSlug('3.* Params'), '3-params')
  assert.equal(headingSlug('Config.wrap_heading'), 'configwrap_heading')
  assert.equal(headingSlug('stateDerivative(z, u, t)'), 'statederivativez-u-t')
  assert.equal(headingSlug('stateDerivative(z,u,t)'), 'statederivativezut')
})

test('guides follow reading order rather than alphabetical order', () => {
  const sections = scanSection(root, 'Get-Started')
  assert.deepEqual(sections.map(item => item.text), ['Overview', 'Installation', 'Quickstart'])
  assert.equal(flattenNavigation(sections).length, 5)
})

test('robot references keep Introduction, Properties, Methods together', () => {
  const robots = scanSection(root, 'Robots')
  assert.deepEqual(robots.map(item => item.text), ['Ackermann Robot', 'Wheel Robot'])
  assert.deepEqual(robots[0].items[0].items.map(item => item.text), ['Introduction', 'Properties', 'Methods'])
  assert.equal(flattenNavigation(robots).length, 8)
  assert.ok(flattenNavigation(robots).every(item => !item.link.endsWith('/index')))
})

test('empty documents retain routes and an explicit placeholder state', () => {
  const info = pageInfo(root, 'Get-Started/Overview.md')
  assert.equal(info.title, 'Overview')
  assert.equal(info.placeholder, true)
})

test('page title is extracted from the Markdown H1', () => {
  const info = pageInfo(root, 'Robots/Ackermann-Robot/API-Reference/Methods.md')
  assert.equal(info.title, 'Ackermann-Robot Methods')
  assert.equal(info.placeholder, false)
})

test('new documents and nested folders are discovered without a theme change', () => {
  const fixture = mkdtempSync(join(tmpdir(), 'rpm-navigation-'))
  try {
    mkdirSync(join(fixture, 'Robots', 'New-Robot', 'Examples'), { recursive: true })
    writeFileSync(join(fixture, 'Robots', 'New-Robot', 'Examples', 'Drive.md'), '# Drive\n')
    writeFileSync(join(fixture, 'Robots', 'New-Robot', 'Hidden.md'), '---\nsidebar: false\n---\n# Hidden')
    assert.deepEqual(flattenNavigation(scanSection(fixture, 'Robots')), [
      { text: 'Drive', link: '/Robots/New-Robot/Examples/Drive' }
    ])
  } finally {
    // Remove only this test's freshly generated temporary fixture.
    rmSync(fixture, { recursive: true, force: true })
  }
})

test('a language mirror produces language-prefixed routes without mixing English', () => {
  const fixture = mkdtempSync(join(tmpdir(), 'rpm-language-'))
  try {
    mkdirSync(join(fixture, 'zh', 'Robots'), { recursive: true })
    writeFileSync(join(fixture, 'zh', 'Robots', 'Introduction.md'), '# 简介')
    assert.deepEqual(flattenNavigation(scanSection(fixture, 'Robots', 'zh')), [
      { text: '简介', link: '/zh/Robots/Introduction' }
    ])
    assert.deepEqual(scanSection(fixture, 'Robots'), [])
  } finally {
    rmSync(fixture, { recursive: true, force: true })
  }
})

test('language switches preserve the canonical document and anchor', () => {
  assert.equal(languageLink('index.md', 'zh'), '/zh/')
  assert.equal(languageLink('zh/Robots/index.md', 'root'), '/Robots/')
  assert.equal(languageLink('Robots/Wheel-Robot/API-Reference/Methods.md', 'zh', '#getstates'), '/zh/Robots/Wheel-Robot/API-Reference/Methods#getstates')
  assert.equal(languageLink('zh/Robots/Wheel-Robot/API-Reference/Methods.md', 'root', '#getstates'), '/Robots/Wheel-Robot/API-Reference/Methods#getstates')
})

test('Chinese sidebars and page titles are localized without crossing languages', () => {
  const robots = scanSection(root, 'Robots', 'zh')
  assert.deepEqual(robots.map(item => item.text), ['阿克曼机器人', '差速轮式机器人'])
  assert.deepEqual(robots[0].items[0].items.map(item => item.text), ['简介', '属性', '方法'])
  assert.ok(flattenNavigation(robots).every(item => item.link.startsWith('/zh/Robots/')))
  const info = pageInfo(root, 'zh/Robots/Ackermann-Robot/API-Reference/Methods.md')
  assert.equal(info.title, '阿克曼机器人方法')
  assert.equal(info.titleSlug, 'ackermann-robot-methods')
  assert.equal(pageInfo(root, 'zh/Get-Started/Overview.md').placeholder, true)
  assert.equal(pageInfo(root, 'zh/Get-Started/Overview.md').title, '概述')
})

test('every public English document has a Chinese mirror with unchanged examples and equations', () => {
  function documents(directory, prefix = '') {
    return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
      if (entry.name.startsWith('.') || ['node_modules', 'zh', 'tests', 'scripts'].includes(entry.name)) return []
      const name = `${prefix}${entry.name}`
      return entry.isDirectory() ? documents(join(directory, entry.name), `${name}/`)
        : entry.name.endsWith('.md') && name !== 'WEBSITE.md' ? [name] : []
    })
  }
  for (const name of documents(root)) {
    const source = readFileSync(join(root, name), 'utf8')
    const translation = readFileSync(join(root, 'zh', name), 'utf8')
    const examples = text => [...text.matchAll(/```[\s\S]*?```/g)].map(match => match[0])
    const equations = text => [...text.matchAll(/\$\$[\s\S]*?\$\$/g)].map(match => match[0])
    assert.deepEqual(examples(translation), examples(source), `${name}: changed code example`)
    assert.deepEqual(equations(translation), equations(source), `${name}: changed equation`)
    if (name.endsWith('/Properties.md')) {
      const defaults = text => text.split(/\r?\n/).filter(line => /^- \*\*(?:default:|默认值：)\*\*/.test(line)).map(line => [...line.matchAll(/`([^`]+)`/g)].map(match => match[1]))
      assert.deepEqual(defaults(translation), defaults(source), `${name}: changed default value`)
    }
  }
})
