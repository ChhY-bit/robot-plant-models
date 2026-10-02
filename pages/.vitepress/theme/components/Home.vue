<script setup lang="ts">
import { useData, withBase } from 'vitepress'
import ModelCards from './ModelCards.vue'
import RobotDiagram from './RobotDiagram.vue'

const { frontmatter } = useData()
</script>

<template>
  <main class="rpm-home">
    <section class="home-hero" aria-labelledby="home-title">
      <div class="hero-copy">
        <div class="hero-eyebrow"><span aria-hidden="true" />{{ frontmatter.rpmHero.eyebrow }}</div>
        <h1 id="home-title">{{ frontmatter.rpmHero.name }} <span>{{ frontmatter.rpmHero.accent }}</span></h1>
        <p class="hero-tagline">{{ frontmatter.rpmHero.tagline }}</p>
        <p class="hero-description">{{ frontmatter.rpmHero.description }}</p>
        <div class="hero-actions"><a class="action-primary" :href="withBase('/Robots/')">{{ frontmatter.rpmHero.primary }} <span aria-hidden="true">→</span></a><a class="action-secondary" :href="withBase('/Get-Started/Overview')">{{ frontmatter.rpmHero.secondary }}</a></div>
        <div class="hero-footnote"><span>MATLAB</span><span>YAML parameters</span><span>Source you can customize</span></div>
      </div>
      <div class="hero-visual"><RobotDiagram scene /></div>
    </section>
    <section class="home-features" aria-label="Project approach">
      <article v-for="feature in frontmatter.rpmFeatures" :key="feature.number"><span class="feature-number">{{ feature.number }}</span><h2>{{ feature.title }}</h2><p>{{ feature.text }}</p></article>
    </section>
    <section class="home-models" aria-labelledby="models-heading">
      <div class="section-heading"><div><div class="page-eyebrow">THE MODEL COLLECTION</div><h2 id="models-heading">Explore robot motion.</h2></div><a :href="withBase('/Robots/')">Browse models <span aria-hidden="true">→</span></a></div>
      <ModelCards />
    </section>
    <div class="home-status"><span class="status-dot" aria-hidden="true" /><span>Documentation preview</span><span class="status-divider">/</span><span>API references available · Guides in progress</span></div>
  </main>
</template>
