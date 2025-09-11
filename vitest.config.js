import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'library' === 'backend' ? 'node' : 'jsdom',
    globals: true,
    setupFiles: './tests/setup.js',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        '*.config.js',
        '*.config.ts'
      ],
      thresholds: {
        branches: 0,
        functions: 0,
        lines: 0,
        statements: 0
      }
    }
  }
});
