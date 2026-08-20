import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  base: './',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  build: {
    outDir: path.resolve(__dirname, '../html'),
    emptyOutDir: true,
    assetsDir: 'assets',
    sourcemap: false,
    minify: true,
  },
  server: {
    port: 5173,
    strictPort: true,
  },
});
