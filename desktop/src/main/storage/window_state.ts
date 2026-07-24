import type { WindowBounds } from '../../shared'

export interface DisplayArea {
  readonly x: number
  readonly y: number
  readonly width: number
  readonly height: number
}

const DEFAULT_WIDTH = 1200
const DEFAULT_HEIGHT = 800
const MIN_VISIBLE_PIXELS = 100

export function boundWindowState(
  saved: WindowBounds | undefined,
  displayAreas: readonly DisplayArea[],
  primaryDisplay: DisplayArea,
): WindowBounds {
  const target =
    saved && isVisible(saved, displayAreas) ? closestArea(saved, displayAreas) : primaryDisplay
  const width = Math.min(Math.max(saved?.width ?? DEFAULT_WIDTH, 640), target.width)
  const height = Math.min(Math.max(saved?.height ?? DEFAULT_HEIGHT, 480), target.height)
  const fallbackX = target.x + Math.round((target.width - width) / 2)
  const fallbackY = target.y + Math.round((target.height - height) / 2)

  return {
    x: clamp(
      saved && isVisible(saved, displayAreas) ? saved.x : fallbackX,
      target.x,
      target.x + target.width - width,
    ),
    y: clamp(
      saved && isVisible(saved, displayAreas) ? saved.y : fallbackY,
      target.y,
      target.y + target.height - height,
    ),
    width,
    height,
  }
}

function isVisible(bounds: WindowBounds, areas: readonly DisplayArea[]): boolean {
  return areas.some((area) => {
    const overlapWidth = Math.max(
      0,
      Math.min(bounds.x + bounds.width, area.x + area.width) - Math.max(bounds.x, area.x),
    )
    const overlapHeight = Math.max(
      0,
      Math.min(bounds.y + bounds.height, area.y + area.height) - Math.max(bounds.y, area.y),
    )
    return overlapWidth >= MIN_VISIBLE_PIXELS && overlapHeight >= MIN_VISIBLE_PIXELS
  })
}

function closestArea(bounds: WindowBounds, areas: readonly DisplayArea[]): DisplayArea {
  const centerX = bounds.x + bounds.width / 2
  const centerY = bounds.y + bounds.height / 2
  return areas.reduce((closest, area) => {
    const distance = distanceToArea(centerX, centerY, area)
    const closestDistance = distanceToArea(centerX, centerY, closest)
    return distance < closestDistance ? area : closest
  })
}

function distanceToArea(x: number, y: number, area: DisplayArea): number {
  const dx = Math.max(area.x - x, 0, x - (area.x + area.width))
  const dy = Math.max(area.y - y, 0, y - (area.y + area.height))
  return dx * dx + dy * dy
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(Math.max(value, minimum), maximum)
}
