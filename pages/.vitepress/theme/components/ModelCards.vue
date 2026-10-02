<script setup lang="ts">
import { withBase } from 'vitepress'
import RobotDiagram from './RobotDiagram.vue'

const models = [
  { key: 'ackermann', name: 'Ackermann Robot', folder: 'Ackermann-Robot', category: 'FRONT-STEERED · REAR-DRIVEN', description: 'Virtual steering and drive dynamics, mapped to physical wheel angles and speeds.', states: '5 dynamic states', actuator: 'Steering + drive' },
  { key: 'wheel', name: 'Wheel Robot', folder: 'Wheel-Robot', category: 'DIFFERENTIAL DRIVE', description: 'Independent left and right wheel dynamics, with accumulated wheel rotation.', states: '7 dynamic states', actuator: 'Left + right wheels' }
]
</script>

<template>
  <div class="model-cards">
    <a v-for="model in models" :key="model.key" class="model-card" :href="withBase(`/Robots/${model.folder}/API-Reference/Introduction`)">
      <div class="model-card-top"><span class="model-category">{{ model.category }}</span><span class="model-arrow" aria-hidden="true">↗</span></div>
      <RobotDiagram :variant="model.key as 'ackermann' | 'wheel'" />
      <h3>{{ model.name }}</h3>
      <p>{{ model.description }}</p>
      <div class="model-card-meta"><span>{{ model.states }}</span><span>{{ model.actuator }}</span></div>
      <div class="model-card-link">Explore the API <span aria-hidden="true">→</span></div>
    </a>
  </div>
</template>
