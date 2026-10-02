import test from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { scanSection, flattenNavigation, pageInfo, headingSlug } from '../.vitepress/navigation.mjs'

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
      { text: 'Introduction', link: '/zh/Robots/Introduction' }
    ])
    assert.deepEqual(scanSection(fixture, 'Robots'), [])
  } finally {
    rmSync(fixture, { recursive: true, force: true })
  }
})
