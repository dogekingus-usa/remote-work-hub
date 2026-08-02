import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://remoteworkhub.net',
  output: 'static',
  integrations: [tailwind()],
  build: { format: 'directory' },
});
