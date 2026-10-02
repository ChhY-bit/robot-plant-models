<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useData, useRoute, withBase } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import Home from './components/Home.vue'
import LanguageMenu from './components/LanguageMenu.vue'

const { Layout } = DefaultTheme
const { page, frontmatter } = useData()
const route = useRoute()
const progress = ref(0)
const info = computed(() => (page.value as any).rpm)
const isDocument = computed(() => (frontmatter.value.layout || 'doc') === 'doc')
const breadcrumbs = computed(() => {
  const parts = info.value?.parts || []
  return parts.slice(0, -1).map((part: string, index: number) => ({
    label: part.replace(/[-_]/g, ' '),
    link: index === 0 && part === 'Robots' ? '/Robots/'
      : index === 0 && part === 'Get-Started' ? '/Get-Started/Overview' : ''
  }))
})

function measureProgress() {
  const article = document.querySelector('.VPDoc .content-container')
  if (!article || !isDocument.value) { progress.value = 0; return }
  const start = article.getBoundingClientRect().top + window.scrollY - 96
  const distance = article.scrollHeight - window.innerHeight + 112
  progress.value = distance <= 0 ? 100 : Math.max(0, Math.min(100, (window.scrollY - start) / distance * 100))
}
watch(() => route.path, () => { progress.value = 0 })
onMounted(() => {
  window.addEventListener('scroll', measureProgress, { passive: true })
  window.addEventListener('resize', measureProgress)
  measureProgress()
})
onUnmounted(() => {
  window.removeEventListener('scroll', measureProgress)
  window.removeEventListener('resize', measureProgress)
})
</script>

<template>
  <Layout>
    <template #layout-top>
      <div v-if="isDocument" class="reading-progress" aria-hidden="true" :style="{ width: `${progress}%` }" />
    </template>
    <template #nav-bar-content-after><LanguageMenu /></template>
    <template #nav-screen-content-after><LanguageMenu mobile /></template>
    <template #home-hero-before><Home /></template>
    <template #doc-before>
      <header class="document-heading">
        <nav v-if="breadcrumbs.length" class="breadcrumbs" aria-label="Breadcrumb">
          <span v-for="(crumb, index) in breadcrumbs" :key="index">
            <span v-if="index" class="crumb-divider" aria-hidden="true">/</span>
            <a v-if="crumb.link" :href="withBase(crumb.link)">{{ crumb.label }}</a>
            <span v-else>{{ crumb.label }}</span>
          </span>
        </nav>
        <div class="page-eyebrow">{{ info?.placeholder ? 'DOCUMENTATION · IN PROGRESS' : 'ROBOT PLANT MODELS' }}</div>
        <h1 :id="info?.titleSlug || 'page-title'">{{ info?.title || page.title }}</h1>
        <div v-if="info?.placeholder" class="empty-document" role="note">
          <span class="placeholder-mark" aria-hidden="true">···</span>
          <h2>Documentation in progress</h2>
          <p>This page is reserved for {{ page.title.toLowerCase() }}. Its content has not been written yet.</p>
          <p>Explore the available robot API references while this section is being prepared.</p>
          <p v-if="page.relativePath.includes('Python')">Native Python support is a future consideration, not an available package.</p>
          <a :href="withBase('/Robots/')">Explore the robot models <span aria-hidden="true">→</span></a>
        </div>
      </header>
    </template>
    <template #sidebar-nav-before><div class="sidebar-eyebrow">DOCUMENTATION</div></template>
    <template #aside-outline-after><div class="outline-note">Transparent models.<br />Room to make them yours.</div></template>
  </Layout>
</template>
