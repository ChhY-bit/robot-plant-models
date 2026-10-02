import assert from 'node:assert/strict'
import { createRequire } from 'node:module'
import { mkdirSync } from 'node:fs'
import { join } from 'node:path'

// Use a regular Playwright installation or the host's bundled runtime.
const require = createRequire(import.meta.url)
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright')
const url = process.env.WEBSITE_URL || 'http://127.0.0.1:4173/robot-plant-models/'
const output = process.env.SCREENSHOT_DIR
if (output) mkdirSync(output, { recursive: true })
const browser = await chromium.launch({ headless: true, ...(process.env.BROWSER_CHANNEL ? { channel: process.env.BROWSER_CHANNEL } : {}) })
const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, colorScheme: 'light', permissions: ['clipboard-read', 'clipboard-write'] })
const page = await context.newPage()
const errors = []
page.on('pageerror', error => { errors.push(error.message); console.error(error.message) })
page.on('console', message => { if (message.type() === 'error') { errors.push(message.text()); console.error(`${message.text()} ${message.location().url}`) } })
page.on('response', response => { if (response.status() >= 400) console.error(`HTTP ${response.status()}: ${response.url()}`) })
async function screenshot(name, fullPage = false) {
  if (output) await page.screenshot({ path: join(output, name), fullPage })
}
async function noOverflow() {
  assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1), `Horizontal overflow at ${page.url()}`)
}
async function codeHeaderSeparated(block) {
  const layout = await block.evaluate(element => {
    const button = element.querySelector('button.copy')
    const label = element.querySelector('span.lang')
    const code = element.querySelector('pre code .line')
    const buttonBounds = button.getBoundingClientRect()
    const labelBounds = label.getBoundingClientRect()
    const codeBounds = code.getBoundingClientRect()
    const tooltip = getComputedStyle(button, '::before')
    const tooltipWidth = button.classList.contains('copied')
      ? parseFloat(tooltip.width) + parseFloat(tooltip.paddingLeft) + parseFloat(tooltip.paddingRight) + 2 : 0
    return {
      separate: labelBounds.right + 8 < buttonBounds.left - tooltipWidth,
      aboveCode: labelBounds.bottom + 6 <= codeBounds.top,
      visible: getComputedStyle(label).opacity === '1',
      compactFeedback: !button.classList.contains('copied') || tooltip.height === '26px'
    }
  })
  assert.deepEqual(layout, { separate: true, aboveCode: true, visible: true, compactFeedback: true }, 'Code language label, copy button/feedback and source must not overlap')
}
try {
  await page.goto(url, { waitUntil: 'networkidle' })
  await page.waitForSelector('#home-title')
  assert.equal(await page.locator('h1').count(), 1)
  assert.equal(await page.locator('.DocSearch-Button-Keys').isVisible(), false)
  assert.equal(await page.locator('.model-card').count(), 2)
  assert.equal(await page.locator('.hero-description').evaluate(el => getComputedStyle(el).fontSize), '19px')
  assert.equal(await page.locator('.VPNavBar').evaluate(el => el.getBoundingClientRect().height), 80)
  assert.equal(await page.locator('#home-title > span').textContent(), 'Models')
  assert.ok(await page.locator('#home-title').evaluate(el => getComputedStyle(el.querySelector('span')).fontSize === getComputedStyle(el).fontSize))
  assert.equal(await page.locator('#home-title br').count(), 0)
  assert.ok(await page.locator('#home-title').evaluate(el => el.getBoundingClientRect().height < parseFloat(getComputedStyle(el).fontSize) * 1.5), 'Desktop title must fit on a single line')

  const scene = page.locator('.robot-scene')
  await scene.scrollIntoViewIfNeeded()
  await page.waitForTimeout(100)
  const diagramBounds = await scene.boundingBox()
  assert.ok(diagramBounds)
  const viewportWidth = await page.evaluate(() => document.documentElement.clientWidth)
  const bounds = { ...diagramBounds, x: 0, width: viewportWidth }
  const copyBounds = await page.locator('.hero-copy').boundingBox()
  assert.ok(bounds.y >= copyBounds.y + copyBounds.height, 'Diagram must have its own row below the introduction')
  assert.ok(bounds.width > diagramBounds.width, 'Interaction must extend beyond the drawing')
  assert.ok(bounds.width * 0.05 < diagramBounds.x && bounds.width * 0.95 > diagramBounds.x + diagramBounds.width, 'Left/right tests must be in the blank margins outside the SVG')
  assert.equal(await scene.locator('marker').count(), 0)
  assert.equal(await scene.locator('path[d="M-9-18 0-30 9-18"]').count(), 0)
  assert.equal(await scene.locator('.front-wheel').count(), 2)
  const transforms = []
  for (const [position, expected] of [[0.05, -27], [0.5, 0], [0.95, 27]]) {
    await page.mouse.move(bounds.x + bounds.width * position, bounds.y + bounds.height / 2)
    await page.waitForFunction(expected => Math.abs(Number(document.querySelector('.robot-scene').dataset.steering) - expected) < 0.01, expected)
    await page.waitForTimeout(150)
    transforms.push(await scene.locator('.front-wheel').first().evaluate(el => getComputedStyle(el).transform))
    assert.ok(await scene.locator('.front-wheel').evaluateAll(elements => elements.every(el => el.style.transform !== '')))
    await screenshot(`steering-${expected}.png`)
  }
  assert.equal(new Set(transforms).size, 3, 'Front-wheel transforms must actually change')
  await page.mouse.move(10, bounds.y - 10)
  await page.waitForFunction(() => document.querySelector('.robot-scene').dataset.steering === '0')
  await page.emulateMedia({ reducedMotion: 'reduce' })
  await page.mouse.move(bounds.x + bounds.width * 0.95, bounds.y + bounds.height / 2)
  await page.waitForFunction(() => Number(document.querySelector('.robot-scene').dataset.steering) > 25)
  assert.equal(await scene.locator('.front-wheel').first().evaluate(el => getComputedStyle(el).transitionDuration), '0s')
  await page.mouse.move(10, bounds.y - 10)
  await page.emulateMedia({ reducedMotion: 'no-preference' })
  console.log('Verified: 80px header; 19px Home text; single-line desktop title; full-width diagram; front wheels turn left/straight/right and return to center.')
  await page.evaluate(() => window.scrollTo({ top: 0, behavior: 'instant' }))
  await screenshot('home-desktop.png', true)
  await noOverflow()

  const language = page.locator('.VPNavBar .language-menu')
  await language.locator('summary').click()
  assert.equal(await language.locator('.language-option').count(), 1)
  assert.equal(await language.locator('.language-option').textContent(), 'English ✓')
  await page.keyboard.press('Escape')
  await page.waitForFunction(() => !document.querySelector('.VPNavBar .language-menu')?.open)

  await page.locator('.VPNavBarAppearance button').click()
  assert.ok(await page.locator('html').evaluate(element => element.classList.contains('dark')))
  await screenshot('home-dark.png', true)
  await page.reload({ waitUntil: 'networkidle' })
  assert.ok(await page.locator('html').evaluate(element => element.classList.contains('dark')))
  await page.locator('.VPNavBarAppearance button').click()

  await page.goto(new URL('Robots/Ackermann-Robot/API-Reference/Methods', url).href, { waitUntil: 'networkidle' })
  assert.equal(await page.locator('.document-heading h1').textContent(), 'Ackermann-Robot Methods')
  assert.equal(await page.locator('.vp-doc h1').count(), 0)
  assert.ok(await page.locator('.VPDocAsideOutline .outline-link').count() > 20)
  assert.equal(await page.locator('.VPDocAsideOutline a[href="#ackermann-robot-methods"]').count(), 0)
  assert.ok(await page.locator('mjx-container').count() > 0)
  assert.equal(await page.locator('.vp-doc').evaluate(el => getComputedStyle(el).fontSize), '19px')
  const copySize = await page.locator('.vp-doc button.copy').first().evaluate(el => {
    const style = getComputedStyle(el)
    return { width: style.width, height: style.height, icon: parseFloat(style.backgroundSize) }
  })
  assert.deepEqual(copySize, { width: '26px', height: '26px', icon: 14 })
  console.log('Verified: 19px document text; copy button 26 x 26px with 14px icon.')
  await screenshot('methods-desktop.png')
  await noOverflow()

  const firstCodeBlock = page.locator('.vp-doc div.language-matlab').first()
  await codeHeaderSeparated(firstCodeBlock)
  await firstCodeBlock.hover()
  await codeHeaderSeparated(firstCodeBlock)
  await screenshot('copy-button.png')
  await page.locator('.vp-doc button.copy').first().click()
  await page.waitForFunction(() => document.querySelector('.vp-doc button.copy.copied'))
  await codeHeaderSeparated(firstCodeBlock)
  await screenshot('copy-feedback.png')
  assert.ok((await page.evaluate(() => navigator.clipboard.readText())).includes('ackermann_robot'))

  await page.locator('.vp-doc a[href="./Properties#3-params"]').first().click()
  await page.waitForURL('**/Properties#3-params')
  await page.waitForFunction(() => document.getElementById('3-params') !== null)
  await page.waitForTimeout(250)
  const position = await page.locator('[id="3-params"]').boundingBox()
  assert.ok(position && position.y >= 50 && position.y < 250, `Anchor offset: ${position?.y}`)
  assert.ok(await page.locator('.reading-progress').evaluate(element => parseFloat(element.style.width) > 0))
  assert.ok(await page.locator('.VPDocFooter a.prev').count())
  assert.ok(await page.locator('.VPDocFooter a.next').count())

  await page.locator('.DocSearch-Button').click()
  await page.locator('#localsearch-input').fill('getWheelSpeed')
  await page.waitForSelector('.VPLocalSearchBox .results li')
  assert.ok(await page.locator('.VPLocalSearchBox .results li').count() > 0)
  assert.ok((await page.locator('.VPLocalSearchBox .results').textContent()).includes('Wheel-Robot'))
  await screenshot('search.png')
  await page.keyboard.press('Escape')

  await page.goto(new URL('Get-Started/Overview', url).href, { waitUntil: 'networkidle' })
  assert.ok(await page.locator('.empty-document').isVisible())
  await screenshot('placeholder.png')

  for (const width of [1280, 1024, 820, 768, 390]) {
    await page.setViewportSize({ width, height: 900 })
    await page.goto(url, { waitUntil: 'networkidle' })
    await noOverflow()
    console.log(`Home layout: ${width}px OK`)
  }
  await screenshot('home-mobile.png', true)
  await page.goto(new URL('Robots/Wheel-Robot/API-Reference/Methods', url).href, { waitUntil: 'networkidle' })
  assert.equal(await page.locator('.vp-doc').evaluate(el => getComputedStyle(el).fontSize), '18px')
  await codeHeaderSeparated(page.locator('.vp-doc div.language-matlab').first())
  await noOverflow()
  assert.ok(await page.locator('.VPLocalNav').isVisible())
  await page.locator('.VPLocalNav button.menu').click()
  await page.waitForFunction(() => {
    const sidebar = document.querySelector('.VPSidebar')
    return sidebar?.classList.contains('open') && Math.abs(sidebar.getBoundingClientRect().x) < 1
  })
  await screenshot('mobile-sidebar.png')
  await page.locator('.VPBackdrop').click({ position: { x: 370, y: 300 } })
  await page.waitForFunction(() => getComputedStyle(document.querySelector('.VPSidebar')).opacity === '0')
  await screenshot('methods-mobile.png')
  await page.locator('.VPLocalNavOutlineDropdown > button').click()
  await page.waitForSelector('.VPLocalNavOutlineDropdown .outline-link')
  assert.ok(await page.locator('.VPLocalNavOutlineDropdown .outline-link').count() > 20)
  await page.keyboard.press('Escape')
  await page.locator('.VPNavBarHamburger').click()
  await page.waitForSelector('.VPNavScreen')
  await page.locator('.VPNavScreen .language-menu summary').click()
  assert.ok(await page.locator('.VPNavScreen .language-option').isVisible())
  assert.deepEqual(errors, [])
  console.log('Browser checks passed: Home, language, persistent theme, Markdown title, outline, formulas, copy, cross-page anchors, progress, pagination, search, placeholders, responsive layouts, and mobile sidebar.')
} finally {
  await context.close()
  await browser.close()
}
