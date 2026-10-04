<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'
import RobotDiagram from './RobotDiagram.vue'

const { page } = useData()
const zh = computed(() => page.value.relativePath.startsWith('zh/'))
const models = computed(() => zh.value ? [
  { key: 'ackermann', name: '阿克曼机器人', folder: 'Ackermann-Robot', category: '前轮转向 · 后轮驱动', description: '虚拟转向与驱动动态，映射为实际车轮转角和转速。', states: '5 个动态状态', actuator: '转向 + 驱动' },
  { key: 'wheel', name: '差速轮式机器人', folder: 'Wheel-Robot', category: '差速驱动', description: '左右车轮独立动态，并记录累计车轮转角。', states: '7 个动态状态', actuator: '左轮 + 右轮' }
] : [
  { key: 'ackermann', name: 'Ackermann Robot', folder: 'Ackermann-Robot', category: 'FRONT-STEERED · REAR-DRIVEN', description: 'Virtual steering and drive dynamics, mapped to physical wheel angles and speeds.', states: '5 dynamic states', actuator: 'Steering + drive' },
  { key: 'wheel', name: 'Wheel Robot', folder: 'Wheel-Robot', category: 'DIFFERENTIAL DRIVE', description: 'Independent left and right wheel dynamics, with accumulated wheel rotation.', states: '7 dynamic states', actuator: 'Left + right wheels' }
])
</script>

<template>
  <div class="model-cards">
    <a v-for="model in models" :key="model.key" class="model-card" :href="withBase(`${zh ? '/zh' : ''}/Robots/${model.folder}/API-Reference/Introduction`)">
      <div class="model-card-top"><span class="model-category">{{ model.category }}</span><span class="model-arrow" aria-hidden="true">↗</span></div>
      <RobotDiagram :variant="model.key as 'ackermann' | 'wheel'" />
      <h3>{{ model.name }}</h3>
      <p>{{ model.description }}</p>
      <div class="model-card-meta"><span>{{ model.states }}</span><span>{{ model.actuator }}</span></div>
      <div class="model-card-link">{{ zh ? '查阅 API' : 'Explore the API' }} <span aria-hidden="true">→</span></div>
    </a>
  </div>
</template>
