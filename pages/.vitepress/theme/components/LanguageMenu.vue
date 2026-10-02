<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { languages } from '../../languages.mjs'

defineProps<{ mobile?: boolean }>()
const menu = ref<HTMLDetailsElement>()
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
    <summary aria-label="Select website language">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><circle cx="12" cy="12" r="9" /><ellipse cx="12" cy="12" rx="4" ry="9" /><path d="M3 12h18M5 7h14M5 17h14" /></svg>
      <span>English</span><span class="language-chevron" aria-hidden="true">⌄</span>
    </summary>
    <div class="language-options">
      <button v-for="language in languages" :key="language.code" class="language-option" aria-current="true" @click="menu!.open = false">
        {{ language.label }} <span aria-hidden="true">✓</span>
      </button>
      <p>More languages in the future.</p>
    </div>
  </details>
</template>
