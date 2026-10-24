# Cinema home

## Visual authority
The owner explicitly selected an Apple TV / tvOS inspired direction, a cinematic
landscape, and large icons. This takes priority over generic phone interface
rules or alternate aesthetic exploration in design skills.

## Surface
Operate: choose and launch an application with a D-pad. Preserve the existing
native navigation, long-press organization, settings and accessibility labels.

## Composition and tokens
Full bleed coastal landscape; a quiet upper vista and stronger lower scrim.
56dp safe horizontal margins; two authored 24dp icons in 48dp focus targets
beside Inicio. City and weather form a group with the right aligned clock/date.
Icons have accessible Spanish labels and contrasting focus tints.
Selected application title provides orientation above the application grid.
Tiles retain the actual apps' supplied artwork and proportions, with 14dp corners.
White focus edge, 1.07 scale and 180ms decelerating focus transition, disabled
when the system animator scale is zero. Use the platform sans for native labels.
White primary text, light blue-white secondary text, midnight fallback surface.
ARC remains hidden; no new launchable app is shown as a content tile.
Weather occupies a compact, non-focusable header block with up to three lines.
It stays hidden until a city is configured, shows a clear unavailable state on
failure, and does not block app loading or D-pad navigation.

## Verification
Compile a signed APK and verify its package/signature. Install alongside the
original. Capture the connected TV at 1920x1080, inspect focus and landscape,
test D-pad navigation and application launch/return. Preserve snapshots of the
old HOME service for restoration; only Cinema's Guard is bound after activation.
