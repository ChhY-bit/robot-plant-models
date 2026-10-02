<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'

const props = defineProps<{ variant?: 'ackermann' | 'wheel'; scene?: boolean }>()

const steering = ref(0)
const sceneElement = ref<SVGSVGElement | null>(null)
const compact = ref(false)
let compactQuery: MediaQueryList | undefined
function updateCompact() { compact.value = compactQuery?.matches ?? false }
onMounted(() => {
  compactQuery = window.matchMedia('(max-width: 639px)')
  updateCompact()
  compactQuery.addEventListener('change', updateCompact)
  if (!props.scene) return
  window.addEventListener('pointermove', steer, { passive: true })
  window.addEventListener('pointercancel', resetSteering)
  window.addEventListener('scroll', resetSteering, { passive: true })
  window.addEventListener('blur', resetSteering)
  document.documentElement.addEventListener('pointerleave', resetSteering)
})
onUnmounted(() => {
  compactQuery?.removeEventListener('change', updateCompact)
  window.removeEventListener('pointermove', steer)
  window.removeEventListener('pointercancel', resetSteering)
  window.removeEventListener('scroll', resetSteering)
  window.removeEventListener('blur', resetSteering)
  document.documentElement.removeEventListener('pointerleave', resetSteering)
})
function resetSteering() { steering.value = 0 }
function steer(event: PointerEvent) {
  if (event.pointerType === 'touch' || !sceneElement.value) return
  const bounds = sceneElement.value.getBoundingClientRect()
  // Full viewport width, but only within the scene's vertical band.
  if (event.clientY < bounds.top || event.clientY > bounds.bottom) {
    resetSteering()
    return
  }
  steering.value = Math.max(-1, Math.min(1, event.clientX / document.documentElement.clientWidth * 2 - 1)) * 30
}
</script>

<template>
  <svg v-if="scene" ref="sceneElement" class="robot-scene" :viewBox="compact ? '0 0 530 420' : '0 0 800 420'" role="img" aria-labelledby="robot-scene-title" :data-steering="steering">
    <title id="robot-scene-title">Top-view robot and body coordinate frame. Move the pointer left or right to steer the front wheels.</title>
    <defs>
      <pattern id="scene-grid" width="30" height="30" patternUnits="userSpaceOnUse"><path d="M30 0H0V30" fill="none" stroke="currentColor" stroke-width=".6" opacity=".1" /></pattern>
    </defs>
    <g :transform="compact ? undefined : 'translate(135 0)'">
    <rect :x="compact ? 25 : -110" y="22" :width="compact ? 480 : 750" height="350" rx="18" fill="url(#scene-grid)" />
    <path d="M65 323C150 315 152 243 240 226S360 155 443 77" class="trajectory" fill="none" stroke-width="2.5" stroke-dasharray="6 7" />
    <circle cx="65" cy="323" r="4" class="trajectory-dot" />
    <text x="65" y="349" class="diagram-small">planned motion</text>
    <g transform="translate(267 198) rotate(30)">
      <rect x="-63" y="-100" width="126" height="190" rx="20" class="robot-body" stroke-width="1.5" />
      <rect x="-45" y="-75" width="90" height="132" rx="11" class="robot-inset" />
      <path d="M-72 55H72M-72-62H72" class="robot-axle" stroke-width="2" />
      <g class="robot-wheels">
        <rect x="-83" y="28" width="23" height="55" rx="6" />
        <rect x="60" y="28" width="23" height="55" rx="6" />
        <g transform="translate(-71.5 -62.5)"><g class="front-wheel" :style="{ transform: `rotate(${steering}deg)` }"><rect x="-11.5" y="-27.5" width="23" height="55" rx="6" /></g></g>
        <g transform="translate(71.5 -62.5)"><g class="front-wheel" :style="{ transform: `rotate(${steering}deg)` }"><rect x="-11.5" y="-27.5" width="23" height="55" rx="6" /></g></g>
      </g>
      <!-- Shafts stop inside solid arrowheads; no detached second tip. -->
      <path d="M0 55V-34M0 55H96" class="robot-frame" stroke-width="1.5" fill="none" />
      <path d="M0-42-4.5-32H4.5ZM104 55 94 50.5V59.5Z" class="robot-origin" />
      <circle cy="55" r="5" class="robot-origin" />
    </g>
    <path d="M309 95h80" class="annotation-line" /><text x="357" y="65" class="diagram-small">steering · δ</text>
    <path d="M240 247H119" class="annotation-line" /><text :x="compact ? 25 : -70" y="236" class="diagram-small">pose · [x, y, θ]</text>
    <g transform="translate(80 66)"><path d="M0 34V0M0 34H34" class="annotation-line" fill="none" /><text x="38" y="39" class="diagram-small">x</text><text x="-4" y="-8" class="diagram-small">y</text></g>
    <rect x="275" y="313" width="225" height="47" rx="10" class="diagram-badge" /><circle cx="293" cy="337" r="3" class="trajectory-dot" /><text x="305" y="341" class="diagram-small">PARAMETERS → MOTION</text>
    <text x="265" y="400" text-anchor="middle" class="diagram-caption">A clear view of the model beneath the motion.</text>
    </g>
  </svg>
  <svg v-else class="model-diagram" viewBox="0 0 200 140" role="img" :aria-label="variant === 'wheel' ? 'Differential-drive robot schematic' : 'Ackermann robot schematic'">
    <path d="M21 109H179M35 125V15" class="annotation-line" stroke-dasharray="3 5" opacity=".5" />
    <rect x="66" y="21" width="68" height="98" rx="11" class="robot-body" stroke-width="1.5" />
    <path d="M56 92H144" class="robot-axle" stroke-width="2" />
    <g class="robot-wheels"><rect x="51" y="73" width="13" height="38" rx="3" /><rect x="136" y="73" width="13" height="38" rx="3" /><template v-if="variant !== 'wheel'"><rect x="51" y="26" width="13" height="29" rx="3" transform="rotate(-20 57 40)" /><rect x="136" y="26" width="13" height="29" rx="3" transform="rotate(-20 142 40)" /></template></g>
    <path d="M100 92V46M94 54 100 46 106 54" class="robot-frame" stroke-width="1.8" fill="none" /><circle cx="100" cy="92" r="3.5" class="robot-origin" />
    <circle v-if="variant === 'wheel'" cx="100" cy="40" r="5" class="robot-inset" stroke="currentColor" stroke-width="1" />
  </svg>
</template>
