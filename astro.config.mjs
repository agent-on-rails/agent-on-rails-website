import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://agent-on-rails.suherman.net',
  integrations: [tailwind()],
});
