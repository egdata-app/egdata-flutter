import { spawn } from 'node:child_process'
import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import {
  _electron as electron,
  expect,
  test,
  type ElectronApplication,
  type Page,
} from '@playwright/test'

let application: ElectronApplication
let page: Page
let userData: string

test.beforeAll(async () => {
  userData = await mkdtemp(join(tmpdir(), 'egdata-electron-e2e-'))
  application = await electron.launch({
    args: ['.', `--user-data-dir=${userData}`],
    cwd: join(import.meta.dirname, '../..'),
    env: {
      ...process.env,
      EPIC_CLIENT_ID: '',
      EPIC_CLIENT_SECRET: '',
      EGDATA_API_BASE_URL: 'http://127.0.0.1:9',
    },
  })
  page =
    application.windows().find((candidate) => !candidate.url().startsWith('devtools://')) ??
    (await application.waitForEvent('window', {
      predicate: (candidate) => !candidate.url().startsWith('devtools://'),
    }))
  await page.waitForLoadState('domcontentloaded')
})

test.afterAll(async () => {
  await application?.close()
  if (userData) await rm(userData, { recursive: true, force: true })
})

test('starts on onboarding with an isolated renderer', async () => {
  await expect(page).toHaveTitle(/egdata/i)
  await expect(page.getByRole('heading', { name: /contribute what epic/i })).toBeVisible()
  await expect(page.locator('.window-titlebar')).toHaveCSS('height', '32px')
  if (process.platform === 'win32') {
    const menuBarVisible = await application.evaluate(({ BrowserWindow }) => {
      const window = BrowserWindow.getAllWindows()[0]
      return window?.isMenuBarVisible()
    })
    expect(menuBarVisible).toBe(false)
    const overlay = await page.evaluate(() => {
      const navigatorWithOverlay = navigator as Navigator & {
        windowControlsOverlay?: {
          visible: boolean
          getTitlebarAreaRect(): DOMRect
        }
      }
      const windowControlsOverlay = navigatorWithOverlay.windowControlsOverlay
      if (!windowControlsOverlay) return null
      const bounds = windowControlsOverlay.getTitlebarAreaRect()
      return { visible: windowControlsOverlay.visible, height: bounds.height }
    })
    expect(overlay).toEqual({ visible: true, height: 32 })
  }
  const overflowX = await page
    .locator('.onboarding')
    .evaluate((element) => getComputedStyle(element).overflowX)
  expect(overflowX).toBe('hidden')
  const documentWidth = await page.evaluate(() => ({
    client: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth,
  }))
  expect(documentWidth.scroll).toBe(documentWidth.client)
  const globals = await page.evaluate(() => ({
    nodeProcess: typeof (globalThis as { process?: unknown }).process,
    nodeRequire: typeof (globalThis as { require?: unknown }).require,
    bridge: typeof (globalThis as unknown as { desktopApi?: unknown }).desktopApi,
  }))
  expect(globals).toEqual({ nodeProcess: 'undefined', nodeRequire: 'undefined', bridge: 'object' })
})

test('keeps one window when the application is launched again', async () => {
  const secondary = spawn(application.process().spawnfile, ['.', `--user-data-dir=${userData}`], {
    cwd: join(import.meta.dirname, '../..'),
    env: {
      ...process.env,
      EPIC_CLIENT_ID: '',
      EPIC_CLIENT_SECRET: '',
      EGDATA_API_BASE_URL: 'http://127.0.0.1:9',
    },
    stdio: 'ignore',
  })
  await new Promise<void>((resolve, reject) => {
    const timeout = setTimeout(() => {
      secondary.kill()
      reject(new Error('The secondary application instance did not exit.'))
    }, 10_000)
    secondary.once('error', (error) => {
      clearTimeout(timeout)
      reject(error)
    })
    secondary.once('exit', () => {
      clearTimeout(timeout)
      resolve()
    })
  })

  const applicationWindowCount = await application.evaluate(
    ({ BrowserWindow }) =>
      BrowserWindow.getAllWindows().filter(
        (window) => !window.webContents.getURL().startsWith('devtools://'),
      ).length,
  )
  expect(applicationWindowCount).toBe(1)
})

test('navigates through the focused desktop surfaces', async () => {
  await page.getByRole('button', { name: 'Continue without consent' }).click()
  await expect(page.getByRole('heading', { name: 'Local manifests' })).toBeVisible()
  await expect(page.locator('#main-content')).toHaveClass(/page-scroll-contained/)
  const localPageOverflow = await page
    .locator('#main-content')
    .evaluate((element) => getComputedStyle(element).overflowY)
  expect(localPageOverflow).toBe('hidden')

  await page.getByRole('link', { name: '02 Cloud Epic library' }).click()
  await expect(page.getByRole('heading', { name: 'Cloud manifests' })).toBeVisible()

  await page.getByRole('link', { name: '03 Library tools Move & recover' }).click()
  await expect(page.getByRole('heading', { name: 'Library tools' })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Launcher installations' })).toBeVisible()

  await application.evaluate(({ ipcMain }) => {
    const cards = [
      {
        id: 'windrose',
        title: 'Windrose',
        appName: 'WindroseApp',
        artworkUrl: null,
        developer: 'Example Studio',
        publisher: 'Example Publisher',
        type: 'BASE_GAME',
        platforms: ['Windows'],
        installed: true,
        epicOwned: true,
        addOnCount: 2,
        releaseDate: '2025-01-01T00:00:00.000Z',
        lastModified: '2026-06-01T00:00:00.000Z',
        metadataAvailable: true,
        genres: ['action'],
        features: ['coop'],
        subscriptions: [],
      },
      {
        id: 'death-stranding',
        title: 'Death Stranding',
        appName: 'DeathStranding',
        artworkUrl: null,
        developer: 'Kojima Productions',
        publisher: '505 Games',
        type: 'BASE_GAME',
        platforms: ['Windows'],
        installed: false,
        epicOwned: true,
        addOnCount: 0,
        releaseDate: '2020-07-14T00:00:00.000Z',
        lastModified: '2026-05-01T00:00:00.000Z',
        metadataAvailable: true,
        genres: ['adventure'],
        features: ['achievements'],
        subscriptions: ['epic-plus'],
      },
      {
        id: 'fortnite',
        title: 'Fortnite',
        appName: 'Fortnite',
        artworkUrl: null,
        developer: 'Epic Games',
        publisher: 'Epic Games',
        type: 'BASE_GAME',
        platforms: ['Windows', 'macOS'],
        installed: true,
        epicOwned: true,
        addOnCount: 0,
        releaseDate: '2017-07-21T00:00:00.000Z',
        lastModified: '2026-07-01T00:00:00.000Z',
        metadataAvailable: true,
        genres: ['action'],
        features: ['coop', 'cross-platform'],
        subscriptions: [],
      },
    ]
    const publicCard = (card: (typeof cards)[number]) => {
      const { genres: _genres, features: _features, subscriptions: _subscriptions, ...value } = card
      return value
    }
    const status = {
      state: 'ready',
      total: cards.length,
      owned: cards.length,
      installed: cards.filter((card) => card.installed).length,
      partialMetadata: 0,
      signedIn: true,
      localScanState: 'complete',
      lastRefreshedAt: '2026-07-21T08:00:00.000Z',
      taxonomyUpdatedAt: '2026-07-21T08:00:00.000Z',
      warnings: [],
    }
    ipcMain.removeHandler('library:get-status')
    ipcMain.removeHandler('library:query')
    ipcMain.removeHandler('library:get-details')
    ipcMain.removeHandler('library:refresh')
    ipcMain.handle('library:get-status', () => status)
    ipcMain.handle('library:query', (_event, request: Record<string, unknown>) => {
      const text = typeof request.text === 'string' ? request.text.toLowerCase() : ''
      const installed = request.installed
      const selected = (key: string) =>
        Array.isArray(request[key])
          ? request[key].filter((value): value is string => typeof value === 'string')
          : []
      const matches = cards.filter((card) => {
        if (
          text &&
          ![card.title, card.appName, card.developer, card.publisher]
            .join(' ')
            .toLowerCase()
            .includes(text)
        )
          return false
        if (installed === 'installed' && !card.installed) return false
        if (installed === 'not-installed' && card.installed) return false
        const facets = [
          [selected('genreIds'), card.genres],
          [selected('featureIds'), card.features],
          [selected('typeIds'), ['base-game']],
          [selected('platformIds'), card.platforms.map((value) => value.toLowerCase())],
          [selected('subscriptionIds'), card.subscriptions],
        ]
        return facets.every(
          ([choices, values]) =>
            choices.length === 0 || choices.some((choice) => values.includes(choice)),
        )
      })
      const page = typeof request.page === 'number' ? request.page : 1
      const pageSize = typeof request.pageSize === 'number' ? request.pageSize : 48
      return {
        items: matches.map(publicCard),
        total: matches.length,
        page,
        pageSize,
        hasMore: false,
        facets: {
          genres: [
            { id: 'action', label: 'Action', count: 2 },
            { id: 'adventure', label: 'Adventure', count: 1 },
          ],
          features: [
            { id: 'achievements', label: 'Achievements', count: 1 },
            { id: 'coop', label: 'Co-op', count: 2 },
            { id: 'cross-platform', label: 'Cross platform', count: 1 },
          ],
          types: [{ id: 'base-game', label: 'BASE_GAME', count: 3 }],
          platforms: [
            { id: 'windows', label: 'Windows', count: 3 },
            { id: 'macos', label: 'macOS', count: 1 },
          ],
          subscriptions: [{ id: 'epic-plus', label: 'Epic Plus', count: 1 }],
        },
        status,
      }
    })
    ipcMain.handle('library:get-details', (_event, request: { id?: string }) => {
      const card = cards.find((candidate) => candidate.id === request.id) ?? cards[0]!
      return {
        ...publicCard(card),
        description: `${card.title} is available in your egdata.app Library.`,
        longDescription: '',
        genres: card.genres.map((value) => (value === 'action' ? 'Action' : 'Adventure')),
        features: card.features.map((value) => value.replace('-', ' ')),
        subscriptions: card.subscriptions.map(() => 'Epic Plus'),
        identifiers: [card.appName],
        addOns:
          card.id === 'windrose'
            ? [
                {
                  id: 'addon-one',
                  title: 'Soundtrack',
                  installed: true,
                  epicOwned: true,
                  type: 'ADD_ON',
                },
                {
                  id: 'addon-two',
                  title: 'Art book',
                  installed: false,
                  epicOwned: true,
                  type: 'ADD_ON',
                },
              ]
            : [],
      }
    })
    ipcMain.handle('library:refresh', () => ({ status, warnings: [] }))
  })

  await page.getByRole('link', { name: '04 Library Owned & installed' }).click()
  await expect(page.getByRole('heading', { name: 'Library', exact: true })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Grid view' })).toHaveAttribute(
    'aria-pressed',
    'true',
  )
  await expect
    .poll(() =>
      page.locator('.library-grid').evaluate((element) => {
        return getComputedStyle(element).gridTemplateColumns.trim().split(/\s+/).length
      }),
    )
    .toBe(4)
  await page.getByRole('button', { name: 'List view' }).click()
  await expect(page.getByRole('button', { name: 'List view' })).toHaveAttribute(
    'aria-pressed',
    'true',
  )
  await page.getByRole('button', { name: 'Grid view' }).click()
  const firstCard = page.getByRole('button', { name: 'Open Death Stranding details' })
  await firstCard.focus()
  await page.keyboard.press('Enter')
  await expect(page.getByRole('dialog', { name: 'Death Stranding details' })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Death Stranding' })).toBeVisible()
  await page.keyboard.press('Escape')
  await expect(page.getByRole('dialog')).toBeHidden()
  await expect(firstCard).toBeFocused()

  await page.getByRole('button', { name: 'Genre' }).click()
  await page.locator('.library-filter-option').filter({ hasText: 'Action' }).click()
  await expect(page.getByRole('button', { name: 'Open Death Stranding details' })).toBeHidden()
  await page.getByRole('button', { name: 'Reset' }).click()
  await expect(page.getByRole('button', { name: 'Open Death Stranding details' })).toBeVisible()

  await page.evaluate(() => {
    window.location.hash = '#/catalog'
  })
  await expect(page.getByRole('heading', { name: 'Library', exact: true })).toBeVisible()
  await expect.poll(() => page.evaluate(() => window.location.hash)).toBe('#/library')

  await page.setViewportSize({ width: 1000, height: 720 })
  await page.getByRole('button', { name: 'Open filters' }).click()
  await expect(page.getByRole('complementary', { name: 'Library filters' })).toHaveClass(/is-open/)
  await expect(page.getByRole('button', { name: 'Installed', exact: true })).toBeVisible()
  await page
    .getByRole('complementary', { name: 'Library filters' })
    .getByRole('button', { name: 'Close filters' })
    .click()
  await page.setViewportSize({ width: 1280, height: 720 })

  await page.getByRole('link', { name: 'Settings' }).click()
  await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible()

  await page.getByRole('link', { name: 'About' }).click()
  await expect(page.getByRole('heading', { name: /about egdata/i })).toBeVisible()
})

test('configures and persists automatic upload schedules accessibly', async () => {
  await page.getByRole('link', { name: 'Settings' }).click()
  const automaticUploads = page.getByRole('switch', { name: /Upload manifests automatically/ })
  const localInterval = page.getByRole('button', {
    name: 'Local manifests automatic upload interval',
  })
  const cloudInterval = page.getByRole('button', {
    name: 'Cloud manifests automatic upload interval',
  })

  await expect(automaticUploads).toBeChecked()
  await expect(localInterval).toContainText('Every 6 hours')
  await expect(cloudInterval).toContainText('Every 24 hours')

  await automaticUploads.focus()
  await page.keyboard.press('Space')
  await expect(localInterval).toBeDisabled()
  await expect(cloudInterval).toBeDisabled()
  await page.keyboard.press('Space')

  await cloudInterval.focus()
  await page.keyboard.press('Enter')
  await page.getByRole('option', { name: 'Every 3 days' }).click()
  await expect(cloudInterval).toContainText('Every 3 days')

  await page.reload()
  await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible()
  await expect(
    page.getByRole('button', { name: 'Cloud manifests automatic upload interval' }),
  ).toContainText('Every 3 days')
})
