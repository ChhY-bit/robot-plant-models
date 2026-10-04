<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'
import ModelCards from './ModelCards.vue'
import RobotDiagram from './RobotDiagram.vue'

const { frontmatter, page } = useData()
const zh = computed(() => page.value.relativePath.startsWith('zh/'))
const prefix = computed(() => zh.value ? '/zh' : '')
</script>

<template>
  <main class="rpm-home">
    <section class="home-hero" aria-labelledby="home-title">
      <div class="hero-copy">
        <div class="hero-eyebrow"><span aria-hidden="true" />{{ frontmatter.rpmHero.eyebrow }}</div>
        <h1 id="home-title">{{ frontmatter.rpmHero.name }} <span>{{ frontmatter.rpmHero.accent }}</span></h1>
        <p class="hero-tagline">{{ frontmatter.rpmHero.tagline }}</p>
        <p class="hero-description">{{ frontmatter.rpmHero.description }}</p>
        <div class="hero-actions"><a class="action-primary" :href="withBase(`${prefix}/Robots/`)">{{ frontmatter.rpmHero.primary }} <span aria-hidden="true">→</span></a><a class="action-secondary" :href="withBase(`${prefix}/Get-Started/Overview`)">{{ frontmatter.rpmHero.secondary }}</a></div>
        <div class="hero-footnote"><span>MATLAB</span><span>{{ zh ? 'YAML 参数配置' : 'YAML parameters' }}</span><span>{{ zh ? '可自由定制的源码' : 'Source you can customize' }}</span></div>
      </div>
      <div class="hero-visual"><RobotDiagram scene /></div>
    </section>
    <section class="home-features" :aria-label="zh ? '项目理念' : 'Project approach'">
      <article v-for="feature in frontmatter.rpmFeatures" :key="feature.number"><span class="feature-number">{{ feature.number }}</span><h2>{{ feature.title }}</h2><p>{{ feature.text }}</p></article>
    </section>
    <section class="home-models" aria-labelledby="models-heading">
      <div class="section-heading"><div><div class="page-eyebrow">{{ zh ? '机器人模型集' : 'THE MODEL COLLECTION' }}</div><h2 id="models-heading">{{ zh ? '探索机器人运动。' : 'Explore robot motion.' }}</h2></div><a :href="withBase(`${prefix}/Robots/`)">{{ zh ? '浏览模型' : 'Browse models' }} <span aria-hidden="true">→</span></a></div>
      <ModelCards />
    </section>
    <div class="home-status"><span class="status-dot" aria-hidden="true" /><span>{{ zh ? '文档预览' : 'Documentation preview' }}</span><span class="status-divider">/</span><span>{{ zh ? 'API 参考已提供 · 入门指南编写中' : 'API references available · Guides in progress' }}</span></div>
  </main>
</template>
