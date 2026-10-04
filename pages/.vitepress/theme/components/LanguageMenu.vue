<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useData, useRouter, withBase } from 'vitepress'
import { languages, languageLink } from '../../languages.mjs'

defineProps<{ mobile?: boolean }>()
const menu = ref<HTMLDetailsElement>()
const { page } = useData()
const router = useRouter()
const current = computed(() => page.value.relativePath.startsWith('zh/') ? 'zh' : 'root')
const label = computed(() => languages.find(language => language.code === current.value)?.label)
function destination(code: string) {
  return withBase(languageLink(page.value.relativePath, code))
}
function selectLanguage(event: MouseEvent, code: string) {
  menu.value!.open = false
  // Keep anchors on normal clicks; modified clicks retain standard link behavior.
  if (!event.ctrlKey && !event.metaKey && !event.shiftKey && !event.altKey) {
    event.preventDefault()
    void router.go(withBase(languageLink(page.value.relativePath, code, window.location.hash)))
  }
}
function dismiss(event: Event) {
  if (menu.value && !menu.value.contains(event.target as Node)) menu.value.open = false
}
function escape(event: KeyboardEvent) {
  if (event.key === 'Escape' && menu.value?.open) {
    menu.value.open = false
    menu.value.querySelector('summary')?.focus()
  }
}
onMounted(() => { document.addEventListener('click', dismiss); document.addEventListener('keydown', escape) })
onUnmounted(() => { document.removeEventListener('click', dismiss); document.removeEventListener('keydown', escape) })
</script>

<template>
  <details ref="menu" class="language-menu" :class="{ mobile }">
    <summary :aria-label="current === 'zh' ? '选择网站语言' : 'Select website language'">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><circle cx="12" cy="12" r="9" /><ellipse cx="12" cy="12" rx="4" ry="9" /><path d="M3 12h18M5 7h14M5 17h14" /></svg>
      <span>{{ label }}</span><span class="language-chevron" aria-hidden="true">⌄</span>
    </summary>
    <div class="language-options">
      <a v-for="language in languages" :key="language.code" class="language-option vp-raw" :href="destination(language.code)" :hreflang="language.lang" :aria-current="language.code === current ? 'true' : undefined" @click="selectLanguage($event, language.code)">
        {{ language.label }} <span v-if="language.code === current" aria-hidden="true">✓</span>
      </a>
    </div>
  </details>
</template>
