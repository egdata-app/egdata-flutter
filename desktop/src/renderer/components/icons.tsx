import { ArchiveIcon } from '@phosphor-icons/react/Archive'
import { ArrowCounterClockwiseIcon } from '@phosphor-icons/react/ArrowCounterClockwise'
import { ArrowRightIcon } from '@phosphor-icons/react/ArrowRight'
import { ArrowSquareOutIcon } from '@phosphor-icons/react/ArrowSquareOut'
import { ArrowsClockwiseIcon } from '@phosphor-icons/react/ArrowsClockwise'
import { CaretRightIcon } from '@phosphor-icons/react/CaretRight'
import { CheckIcon } from '@phosphor-icons/react/Check'
import { CloudArrowUpIcon } from '@phosphor-icons/react/CloudArrowUp'
import { FolderOpenIcon } from '@phosphor-icons/react/FolderOpen'
import { FilesIcon } from '@phosphor-icons/react/Files'
import { GearSixIcon } from '@phosphor-icons/react/GearSix'
import { InfoIcon } from '@phosphor-icons/react/Info'
import { HardDriveIcon } from '@phosphor-icons/react/HardDrive'
import { GridFourIcon } from '@phosphor-icons/react/GridFour'
import { ListBulletsIcon } from '@phosphor-icons/react/ListBullets'
import { MagnifyingGlassIcon } from '@phosphor-icons/react/MagnifyingGlass'
import { SlidersHorizontalIcon } from '@phosphor-icons/react/SlidersHorizontal'
import { SortAscendingIcon } from '@phosphor-icons/react/SortAscending'
import { SortDescendingIcon } from '@phosphor-icons/react/SortDescending'
import { PauseIcon } from '@phosphor-icons/react/Pause'
import { PlayIcon } from '@phosphor-icons/react/Play'
import { ShieldCheckIcon } from '@phosphor-icons/react/ShieldCheck'
import { UploadSimpleIcon } from '@phosphor-icons/react/UploadSimple'
import { XIcon } from '@phosphor-icons/react/X'
import type { Icon as PhosphorIcon, IconProps } from '@phosphor-icons/react/lib'

export type IconName =
  | 'archive'
  | 'cloud'
  | 'settings'
  | 'info'
  | 'refresh'
  | 'upload'
  | 'pause'
  | 'play'
  | 'cancel'
  | 'retry'
  | 'external'
  | 'folder'
  | 'shield'
  | 'chevron'
  | 'arrow-right'
  | 'files'
  | 'drive'
  | 'search'
  | 'grid'
  | 'list'
  | 'filters'
  | 'sort-asc'
  | 'sort-desc'
  | 'check'

const icons: Record<IconName, PhosphorIcon> = {
  archive: ArchiveIcon,
  cloud: CloudArrowUpIcon,
  settings: GearSixIcon,
  info: InfoIcon,
  refresh: ArrowsClockwiseIcon,
  upload: UploadSimpleIcon,
  pause: PauseIcon,
  play: PlayIcon,
  cancel: XIcon,
  retry: ArrowCounterClockwiseIcon,
  external: ArrowSquareOutIcon,
  folder: FolderOpenIcon,
  shield: ShieldCheckIcon,
  chevron: CaretRightIcon,
  'arrow-right': ArrowRightIcon,
  files: FilesIcon,
  drive: HardDriveIcon,
  search: MagnifyingGlassIcon,
  grid: GridFourIcon,
  list: ListBulletsIcon,
  filters: SlidersHorizontalIcon,
  'sort-asc': SortAscendingIcon,
  'sort-desc': SortDescendingIcon,
  check: CheckIcon,
}

export function Icon({ name, ...props }: { name: IconName } & IconProps) {
  const Glyph = icons[name]
  return <Glyph aria-hidden="true" focusable="false" weight="regular" {...props} />
}
