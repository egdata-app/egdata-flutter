import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import { _electron as electron, expect, test } from '@playwright/test'

test('starts without a renderer and recreates a destroyed window', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'egdata-electron-tray-e2e-'))
  const application = await electron.launch({
    args: ['.', '--hidden', `--user-data-dir=${userData}`],
    cwd: join(import.meta.dirname, '../..'),
    env: {
      ...process.env,
      EPIC_CLIENT_ID: '',
      EPIC_CLIENT_SECRET: '',
      EGDATA_API_BASE_URL: 'http://127.0.0.1:9',
    },
  })

  try {
    await expect
      .poll(() => application.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows().length))
      .toBe(0)

    await expect
      .poll(
        () =>
          application.evaluate(({ app, BrowserWindow }) => {
            app.emit('activate')
            return BrowserWindow.getAllWindows().length
          }),
        { timeout: 15_000 },
      )
      .toBe(1)
    await expect
      .poll(() =>
        application.evaluate(({ BrowserWindow }) => {
          const window = BrowserWindow.getAllWindows()[0]
          return Boolean(
            window && !window.webContents.isLoadingMainFrame() && window.webContents.getURL(),
          )
        }),
      )
      .toBe(true)
    expect(
      await application.evaluate(
        ({ BrowserWindow }) => BrowserWindow.getAllWindows()[0]?.getTitle() ?? '',
      ),
    ).toMatch(/egdata/i)

    await application.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows()[0]?.close())
    await expect
      .poll(() => application.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows().length))
      .toBe(0)

    await expect
      .poll(() =>
        application.evaluate(({ app, BrowserWindow }) => {
          app.emit('activate')
          return BrowserWindow.getAllWindows().length
        }),
      )
      .toBe(1)
    await expect
      .poll(() =>
        application.evaluate(({ BrowserWindow }) => {
          const window = BrowserWindow.getAllWindows()[0]
          return Boolean(
            window && !window.webContents.isLoadingMainFrame() && window.webContents.getURL(),
          )
        }),
      )
      .toBe(true)
    expect(
      await application.evaluate(
        ({ BrowserWindow }) => BrowserWindow.getAllWindows()[0]?.getTitle() ?? '',
      ),
    ).toMatch(/egdata/i)
  } finally {
    await application.close()
    await rm(userData, { recursive: true, force: true })
  }
})
