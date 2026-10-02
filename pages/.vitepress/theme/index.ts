import DefaultTheme from 'vitepress/theme'
import Layout from './Layout.vue'
import ModelCards from './components/ModelCards.vue'
import './style.css'

export default {
  extends: DefaultTheme,
  Layout,
  enhanceApp({ app }) {
    app.component('ModelCards', ModelCards)
  }
}
