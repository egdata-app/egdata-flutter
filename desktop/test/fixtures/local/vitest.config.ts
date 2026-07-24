import path from 'node:path'

import { defineConfig } from 'vitest/config'

export default defineConfig({
  root: path.resolve(import.meta.dirname, '../../..'),
  test: {
    environment: 'node',
    include: ['test/contract/local*.test.ts', 'test/integration/upload*.test.ts'],
  },
})
