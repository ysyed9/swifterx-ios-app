# SwifterX iOS Prototype Validation

## Visual Checks
- Confirm section spacing and card padding on iPhone SE and iPhone 15/16 simulators.
- Confirm typography hierarchy (`title`, `sectionTitle`, `body`, `caption`) is consistent.
- Confirm surface/background/border/accent colors align with Figma intent.
- Confirm card corner radii and button radii are consistent across screens.

## Interaction Checks
- Home tab: category selection updates highlighted card.
- Home tab: tapping recommendation opens detail screen.
- Detail screen: quantity stepper updates button price text.
- Cart tab: quantity stepper updates total.
- Profile tab: notification and dark mode toggles update local state.

## Known Scope Limits (UI Prototype)
- No backend calls, authentication, or payment integration.
- Uses mock service/category data only.
