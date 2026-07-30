# User Feedback: Push Camera And Hands

- Date: 2026-05-26
- Source: direct user playtest feedback in Codex thread
- Scope: Godot PushLab / current vertical-slice push feel
- Milestone gate status: qualitative PIVOT input only; this is not a filled `playtest-*.md` Human Feel Gate report.

## Observed Issues

- During third-person to first-person transition, arms can read as unnaturally long.
- Hands can visually enter the boulder when aiming toward upper-left contact.
- Push view feels too constrained to judge direction, left/right surroundings, or hand placement.
- Player needs a stable center reference, peripheral awareness, and the ability to look down at hands/contact while pushing.
- Because aim/contact/push direction are not readable enough, the player cannot reliably complete the pushing process by intention.

## Follow-Up Implemented

- Added regression checks for first-person forearm stretch, hand surface clearance, and downward push look.
- Separated physical contact point from visual palm target so palms sit outside the boulder while physics still applies force at the surface contact.
- Clamped first-person forearm visual length so camera transitions cannot stretch arms.
- Loosened push pitch limits and widened push-camera FOV.
- Added a subtle center reticle to PushLab, Main, and VerticalSlice HUDs.
- Follow-up tightened the transition: third-person arms hide early during push-camera blend, first-person hands wait until the camera is close enough, mouse/trackpad input can reach the lower contact view, biased push view backs off slightly for peripheral route reading, and palms sit farther outside the boulder surface.

## Next Core-Loop Focus

- Run the `Push-Feel Retest Focus` section in `representative-human-playtest-worksheet.md` before judging the full representative loop.
- Continue evaluating whether aim-to-contact feels deliberate under live player input, not only in automated/bot push routes.
- Prefer further camera/hand/contact iteration over adding new content or release features until the user can complete the push by intention.
