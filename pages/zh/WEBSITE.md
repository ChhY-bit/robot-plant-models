---
sidebar: false
search: false
---

# 网站维护 {#website-maintenance}

本目录保存网站源码，不是 MATLAB 安装包。网站基于 VitePress，并使用定制的 Vue 风格主题。生成的 HTML 和依赖目录不会提交到 Git。

## 本地开发 {#local-development}

使用 Node.js 22 或更新版本。在 `pages/` 目录中执行：

```sh
npm ci
npm run dev
```

打开 VitePress 输出的地址，注意包含 `/robot-plant-models/` 基础路径。生产预览的步骤为：

```sh
npm test
npm run build
npm run check:links
npm run preview
```

PowerShell 若阻止执行 `npm.ps1`，可将命令中的 `npm` 改为 `npm.cmd`，无需修改系统执行策略。

构建输出位于 `.vitepress/dist/`。不要通过 `file://` 直接打开 HTML，应使用预览服务器。

可选的浏览器冒烟测试为 `node tests/browser-smoke.mjs`。它需要单独安装的 Playwright 和浏览器，也可通过 `PLAYWRIGHT_MODULE` 使用主机提供的 Playwright。设置 `BROWSER_CHANNEL=msedge` 可使用现有 Microsoft Edge；`WEBSITE_URL` 指定预览地址；`SCREENSHOT_DIR` 指定截图目录。构建或启动网站不需要这些浏览器测试依赖。

## 修改位置 {#where-to-make-changes}

| 内容 | 源文件 |
| --- | --- |
| 首页文字与特色介绍 | `index.md`、`zh/index.md` 的 frontmatter 与正文 |
| 首页 HTML 模板 | `.vitepress/theme/components/Home.vue` |
| 颜色、字体、响应式布局 | `.vitepress/theme/style.css` |
| GitHub、发布页面、URL 基础路径 | `.vitepress/site.mjs` |
| 顶部导航和网站配置 | `.vitepress/config.mts` |
| 侧栏标签与排序 | `.vitepress/navigation.mjs` |
| 语言注册与切换路径 | `.vitepress/languages.mjs` |
| 常见问题与关于页面 | `FAQ/index.md`、`About/index.md` 及对应中文镜像 |

`site.mjs` 使用仓库 `ChhY-bit/robot-plant-models`。本地默认基础路径为 `/robot-plant-models/`；GitHub 工作流根据实际仓库名设置生产基础路径。仓库再次更名时，应更新 `site.mjs` 中的链接和本地基础路径。使用自定义域名部署到根路径时，在构建前设置 `PAGES_BASE=/`。

## 文档行为 {#documentation-behavior}

左侧栏扫描 `Get-Started/`、`Robots/` 及对应中文目录中的 Markdown 文件。新增文件和子目录会自动纳入，空目录忽略。开发服务器会在文件增删时重启配置。展示映射表提供阅读顺序，未知项目按名称排序；frontmatter 设置 `sidebar: false` 的文档不会进入目录树。

首个 Markdown 一级标题显示为正文上方的主标题，仅从渲染正文中移除，不删除源文件中的标题。右侧目录展示二级、三级标题。上一篇和下一篇按侧栏扫描顺序排列，并限制在当前语言、当前顶层栏目内。已有空文档保留路由，通过明确的“编写中”面板展示状态，无需修改其正文。

相对 Markdown 链接由 VitePress 处理。移动文档仍可能破坏引用和公开 URL，需同步更新引用，必要时提供重定向。`npm run check:links` 检查构建后的页面及标题锚点，包括 API 交叉引用。

## 网站语言 {#website-languages}

英文路径保持不变；翻译版镜像目录示例：

```text
Robots/Ackermann-Robot/API-Reference/Methods.md
zh/Robots/Ackermann-Robot/API-Reference/Methods.md
ja/Robots/Ackermann-Robot/API-Reference/Methods.md
```

网站已启用英语和简体中文。`zh/` 中不需要 `-zh` 后缀。中文镜像包含所有文档路由，也包含本维护指南；英文空页面保持为空的镜像，并显示中文占位提示。

定制语言菜单切换至对应页面，并保留当前标题锚点。中文标题使用显式 `{#original-anchor}` 标识，以保持交叉引用和语言切换有效。翻译时不要改变 API 标识、YAML 键、单位、公式或可执行示例。API 或原文更新后需同步维护两种语言；译文是独立 Markdown 文件，不是在构建时自动生成。

新增语言时，创建完整镜像，在 `.vitepress/languages.mjs` 注册，并在配置和定制主题中加入对应导航及界面文案，同时补充侧栏和标准路径处理。尚未翻译的内容应明确提供英文原文链接，不能将英文冒充译文。修改后运行导航测试、生产构建、链接检查及浏览器冒烟测试。

## GitHub Pages {#github-pages}

仓库包含 `.github/workflows/pages.yml`。网站文件变更的推送和拉取请求会触发构建与校验；只有默认分支推送或该分支上的手动运行会部署。仓库 Settings → Pages 的发布来源应选择 **GitHub Actions**。`github-pages` 环境可能根据仓库设置要求审批。

本地修改不等于线上发布；仍需提交并推送。除非明确要求，不应把远程设置更改视为本地网站开发的一部分。

## 待完善内容 {#items-still-to-be-supplied}

- 完善首页文案和项目视觉素材。
- 补充已有空页面的安装、快速开始和模型推导。
- 编写常见问题、作者介绍、贡献与引用指南，并同步维护许可证说明。
- 维护发布包信息和已验证的 MATLAB 兼容性说明。
- 根据需要增加其他语言，并保持英中文档同步。

当前没有原生 Python/C 独立运行库；不要将未来规划描述为已经提供的安装包。
