import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';

export default defineConfig({
  site: 'https://remoteworkhub.net',
  output: 'static',
  integrations: [tailwind(), mdx()],
  build: {
    format: 'file',
  },
});
