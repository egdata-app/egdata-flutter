# EGData Windows Focused v2 — Design QA

## Comparison Target

- Source visual truth: `C:\Users\nacho\.codex\generated_images\019f505b-4e8a-7592-b09e-f5c0cd57ed82\exec-2499a17d-2d22-42ef-acb9-c19e84a64029.png`
- Final implementation screenshot: `E:\code\egdata-flutter\egdata_flutter\build\design-qa-home-reference-pass2.png`
- Side-by-side comparison: `E:\code\egdata-flutter\egdata_flutter\build\design-qa-comparison-pass2.png`
- Responsive evidence: `E:\code\egdata-flutter\egdata_flutter\build\design-qa-home-1280x720-top.png` and `E:\code\egdata-flutter\egdata_flutter\build\design-qa-home-1280x720.png`
- Viewport: nominal 1440×1024 reference window (captured client frame 1426×1017) and nominal 1280×720 compact window (captured client frame 1266×713)
- State: Windows Home, dark theme, live installed-game/session data, sync healthy, no current recovery candidates

## Full-view Comparison Evidence

The final side-by-side comparison preserves Option 3's core composition: fixed dark sidebar; greeting and sync state; one dominant Play Next hero; a compact three-game queue; a truthful recent-activity rail; and a bottom quick-action strip. The calm navy/cyan palette, restrained borders, rounded panels, hierarchy, and content density are consistent with the source.

Expected state differences are intentional and data-driven: the source shows a reconnect alert and progress data, while the live implementation had no recoverable drive and no synced completion signal. EGData therefore omits those claims instead of fabricating them. The implementation also includes the real Windows title bar and live Epic artwork/content.

## Focused Region Comparison Evidence

The hero/right-rail region was compared in `build/design-qa-comparison-pass2.png`. The hero and stacked queue/activity rail now terminate on the same baseline, the game-title scale is close to the source, the primary Play action has equivalent prominence, and the quick-action row follows at a consistent 16 px gap. A separate crop was not needed because the combined original-resolution image keeps typography, iconography, borders, and artwork legible.

## Required Fidelity Surfaces

- Fonts and typography: Flutter's existing desktop font stack is retained. Weight, cyan overlines, display-title hierarchy, button weight, line height, truncation, and small metadata text are internally consistent and legible. The final pass increased the hero title from 42 px to 48 px to better match Option 3.
- Spacing and layout rhythm: 36/32 px page insets, 16/20/24 px section gaps, aligned hero/right-rail bottoms, consistent panel radii, and compact card padding match the reference direction. The 1280×720 state keeps navigation persistent and exposes remaining Home content through vertical scrolling.
- Colors and visual tokens: desktop-only navy surfaces, cyan focus/primary states, muted slate text, green success, amber attention, and subtle borders match the source while leaving shared mobile colors unchanged.
- Image quality and asset fidelity: the hero and queue use real Epic metadata artwork with optimized remote sizing and cover crops. Existing logo and Material icons are used; no placeholder drawings, emoji, or fabricated product art appear in the final loaded state.
- Copy and content: headings and action labels are concise and product-specific. Status, progress, activity, installation availability, and recovery messaging are derived from real local state.

## Findings

No actionable P0, P1, or P2 findings remain.

Expected differences classified as acceptable:

- The reconnect banner appears only when validated recovery candidates exist.
- Progress UI appears only when official progress is available.
- The native custom title bar consumes a small amount of vertical space not represented in the source mock.
- Live library art and titles differ from the illustrative source content.

## Comparison History

### Pass 1 — blocked

- [P2] Hero/right-rail baseline mismatch. At the reference viewport, the 522 px hero ended well above the activity rail and created an unintended empty band before quick actions.
- [P2] Hero title scale was too restrained relative to Option 3.
- Evidence: `E:\code\egdata-flutter\egdata_flutter\build\design-qa-comparison-reference.png`

Fixes made:

- Made the large-viewport hero 634 px tall while preserving the 522 px compact breakpoint.
- Increased the hero game title from 42 px to 48 px.
- Kept the smaller breakpoint scrollable instead of compressing controls or hiding content.

### Pass 2 — passed

- The hero and right rail align at the reference viewport.
- The title/CTA hierarchy now reads at the same visual level as the source.
- The quick-action strip follows the main content without the earlier empty band.
- The 1280×720 top and scrolled captures retain usable navigation, visible focus, and access to all Home sections.
- Evidence: `E:\code\egdata-flutter\egdata_flutter\build\design-qa-comparison-pass2.png`

## Interactions Checked

- Sidebar navigation: Home, Library, Activity, Tools, Settings presence
- Library search/sort/view/filter controls and loaded cover grid
- Activity session list and progress-empty state
- Tools cards and Disk Discovery entry
- Disk Discovery empty state, safety copy, drive check, disabled restore, and scan-folder affordance
- Keyboard Tab focus with a visible cyan focus ring on Check drives
- Home vertical scrolling at 1280×720

## Implementation Checklist

- [x] Match Option 3's desktop information hierarchy and visual tokens
- [x] Use truthful live data and conditional recovery/status UI
- [x] Align large-screen hero and supporting rail
- [x] Preserve compact-screen scrolling and persistent navigation
- [x] Verify visible keyboard focus
- [x] Verify Library, Activity, Tools, and recovery entry states

## Follow-up Polish

- [P3] Repeat the recovery-alert visual check with the disposable-drive acceptance fixture so the live validated-candidate state can be captured without fabricating data.

final result: passed
