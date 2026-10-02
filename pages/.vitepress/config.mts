import { defineConfig } from 'vitepress'
import { fileURLToPath } from 'node:url'
import { project, languages } from './site.mjs'
import { scanSection, pageInfo, flattenNavigation, headingSlug } from './navigation.mjs'

const root = fileURLToPath(new URL('../', import.meta.url))
const sidebar = {
  '/Get-Started/': scanSection(root, 'Get-Started'),
  '/Robots/': scanSection(root, 'Robots')
}

export default defineConfig({
  title: project.name,
  description: 'Open, customizable MATLAB models for mobile robot simulation.',
  lang: 'en',
  base: project.base,
  cleanUrls: true,
  lastUpdated: false,
  head: [['link', { rel: 'icon', type: 'image/svg+xml', href: `${project.base}mark.svg` }]],
  locales: Object.fromEntries(languages.map(language => [language.code, {
    label: language.label, lang: language.lang
  }])),
  themeConfig: {
    logo: '/mark.svg',
    siteTitle: 'Robot Plant Models',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Get Started', link: '/Get-Started/Overview', activeMatch: '/Get-Started/' },
      { text: 'Robots', link: '/Robots/', activeMatch: '/Robots/' },
      { text: 'FAQ', link: '/FAQ/' },
      { text: 'Releases', link: project.releases },
      { text: 'About', link: '/About/' }
    ],
    sidebar,
    outline: { level: [2, 3], label: 'On this page' },
    search: {
      provider: 'local',
      options: {
        detailedView: true,
        _render(source, env, md) {
          const html = md.render(source, env)
          const info = pageInfo(root, env.relativePath)
          if (env.frontmatter?.search === false || info.placeholder) return ''
          // Search indexes need the removed H1 to distinguish identically named
          // methods in different robot references. This HTML is not page prose.
          const home = env.frontmatter?.layout === 'home'
          const title = md.utils.escapeHtml(home ? project.name : info.title)
          const anchor = home ? 'home-title' : info.titleSlug
          return `<h1>${title}<a href="#${anchor}"></a></h1>\n${html}`
        }
      }
    },
    socialLinks: [{ icon: 'github', link: project.repository, ariaLabel: 'Project on GitHub' }],
    docFooter: { prev: 'Previous page', next: 'Next page' },
    footer: { message: 'Robot Plant Models · Open models. Make them yours.' }
  },
  markdown: {
    math: true,
    anchor: { slugify: headingSlug },
    config(md) {
      // Remove only the first H1 from rendered prose; the layout renders it once.
      // Keep it in source so GitHub and ordinary Markdown readers remain usable.
      md.core.ruler.after('inline', 'rpm-main-title', state => {
        const index = state.tokens.findIndex(token => token.type === 'heading_open' && token.tag === 'h1')
        if (index >= 0) state.tokens.splice(index, 3)
      })
    }
  },
  transformPageData(page) {
    const info = pageInfo(root, page.relativePath)
    if (!page.frontmatter.title) page.title = info.title
    page.rpm = info
    const section = page.relativePath.startsWith('Get-Started/') ? '/Get-Started/'
      : page.relativePath.startsWith('Robots/') ? '/Robots/' : ''
    const documents = section ? flattenNavigation(sidebar[section]) : []
    const current = `/${page.relativePath.replace(/\.md$/, '')}`
    const position = documents.findIndex(item => item.link === current)
    if (position >= 0) {
      page.frontmatter.prev ??= documents[position - 1] || false
      page.frontmatter.next ??= documents[position + 1] || false
    }
  },
  vite: {
    server: {
      watch: { ignored: ['**/.vitepress/cache/**', '**/.vitepress/dist/**'] }
    },
    plugins: [{
      name: 'rpm-directory-refresh',
      configureServer(server) {
        // Dev HTML is initially blank; serve the browser's early favicon request.
        server.middlewares.use((request, response, next) => {
          if (request.url === '/favicon.ico') {
            response.statusCode = 302
            response.setHeader('Location', `${project.base}mark.svg`)
            response.end()
          } else next()
        })
        // Regenerate sidebars when Markdown files are added or removed.
        for (const event of ['add', 'unlink', 'addDir', 'unlinkDir']) {
          server.watcher.on(event, path => {
            if (!path.includes('.vitepress') && !path.includes('node_modules') &&
                (path.endsWith('.md') || event.endsWith('Dir'))) void server.restart()
          })
        }
      }
    }]
  }
})
