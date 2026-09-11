# Highlights: crafted object specification

10 September 2026 · Implemented browser design study

## The direction

The collection should feel carefully constructed. Silhouette gives each achievement an identity; the face, edge, and reverse should describe one coherent object. A shared material and lighting vocabulary connects the family while allowing each shape to have a different physical construction.

The prototype uses actual geometry and live lighting. It contains no generated concept images or prerendered badge faces. Lettering is extruded geometry. The locket's default landscape and the fine material textures are drawn procedurally; an optional local image can replace the landscape.

The existing native app remains unchanged. Its semantic color families, deterministic evidence, unit preferences, native routes, accessibility contracts, and full opening turn remain the constraints for a future implementation. This study approximates semantic colors for browser review; it does not replace the native P3 palette or stable color seeds.

## Three reference objects

### Stopwatch

- A lathed titanium body has a deliberately rounded shoulder and fitted rear cap.
- A separate retaining bezel supplies one narrow polished edge.
- The blue enamel dial is recessed into the case.
- Sixty individual solid marks form the chapter ring, with twelve longer marks. They are decorative instrument styling, not additional workout evidence.
- The crown has a neck, rounded cap, and thirty-two physical flutes.
- The distance label and simplified running mark have solid relief.
- The reverse contains a small Daybeat inscription, sample achievement identity, and a synthetic date.
- The exploded view separates the bezel, dial, crown, and reverse components.

The next refinement is a more exact native type treatment and engraved rather than raised reverse text. Test arbitrary distance labels and localization before native integration. Keep exact record/previous-best evidence outside the decorative dial.

### Hourglass

- A continuous lathed glass surface creates both chambers and the narrow neck.
- The glass volume is flattened into a compact collectible profile rather than a large freestanding hourglass.
- Upper/lower caps, polished glass seats, and curved shoulders are separate meshes.
- The rear stays transparent; there is no opaque badge face behind the chambers.
- Upper and lower sand beds are modeled solids with procedural granular texture.
- A finite point stream accompanies the opening turn; the sand settles and rendering stops.
- Sample duration and date inscriptions sit on the metal caps.

The sand sequence is an authored visual transfer, not a volume-conserving or gravity-correct simulation. Glass uses real-time transmission and an environment reflection, not ray-traced optics. Refine the cap inscriptions, internal chamber wall thickness, and sand progression before considering this ready for native production.

### Memory locket

- A curved heart outline supports a beveled metal body and domed reverse.
- Constant-width polygon offsets form the retaining lip and blue enamel gasket. Tight curves are cleaned by a robust polygon-offset operation rather than simply scaling the outer silhouette.
- The front has separate image and protective-window meshes.
- The clear window has a curved surface and responds to the shared light environment.
- A procedural mountain/lake scene provides an immediately usable sample. A local photo can be loaded without network transmission or persistent storage.
- The photo fills most of the face. The reverse reserves space for the actual title/date treatment in a future implementation.

The current local photo crop is centered. A production version needs focal-point preservation, alternate image aspect ratios, and note-only/missing-photo states. The closed locket rotates; it has no opening hinge interaction.

## Shared construction

All dimensions in the code are normalized art-study units. The common object is approximately two units across. They are not claims about a manufactured physical product.

| Element | Implemented direction |
| --- | --- |
| Body | Real depth, curved shoulder or beveled contour, separate surface normals |
| Rim | Narrow modeled profile, with constant-width inset paths on irregular objects |
| Front | Recessed enamel or a curved glass/photo assembly |
| Engraving/marks | Thin solid relief, with darker lettering on the reverse |
| Grain | Fine deterministic procedural bump texture in object UV space |
| Reverse | Modeled surface with a quieter inscription hierarchy |
| Exploded inspection | Real component translation, with an automatic oblique pose and expanded framing |

The three reference objects receive the most distinct construction. Supporting objects are working shape studies and still share some standard body/rim components. The half-year fan uses individual beveled segments; the returning loop is open toroidal geometry; the ribbon and pennant have an actual change in their surface plane.

## Material system

| Material | Prototype behavior |
| --- | --- |
| Satin metal | Metallic reflection, roughness initially 0.32, subtle procedural grain |
| Polished edge | Lower roughness and no visible coarse grain |
| Enamel | Nonmetallic pigment, smooth finish, clearcoat |
| Glass | Transmission, refractive response, thickness, restrained tint |
| Sand | Rough nonmetallic material with granular color and bump variation |
| Lettering | Light alloy-like material with real shallow geometry |
| Clay | A neutral rough material applied to the same meshes for form review |

The roughness slider controls the satin body and proportionally adjusts the polished edge. Material changes never replace a badge with another image. The wireframe control displays the actual triangulation.

## Lighting and presentation

The shared reflection environment contains a broad upper-left source, weaker fill, narrow rear/right source, and quiet lower bounce. A matching directional light rig illuminates the actual geometry. Moving the light changes both the key position and the reflected environment orientation, so front, side, and reverse remain related.

The studio defaults to charcoal and can switch to a subdued semantic backdrop. Shadows are restrained. Brightness is adjustable for inspection. The objects can be inspected singly, as a trio, or as the complete family. Narrow displays arrange the reference trio into two rows and move the inspector below the viewer.

The scene uses ACES tone mapping and sRGB display output. It is not a proof of native P3 appearance. There is no bloom, sparkle overlay, random wear, or moving shine painted onto a badge face.

## Motion and direct manipulation

- The opening turn lasts 1.2 seconds and completes one full revolution with smooth acceleration/deceleration and a small pitch arc.
- Pointer down immediately interrupts the reveal or spring.
- Horizontal movement rotates the objects directly; vertical movement supplies bounded pitch.
- Release settles toward the nearest front or back with a damped spring and bounded release velocity.
- Front, Side, and Reverse are explicit accessible buttons. All controls are ordinary HTML inputs/buttons.
- Reduce Motion disables the opening movement and resolves pose changes immediately.
- A finite sand sequence accompanies the reveal. There is no idle animation loop.
- Rendering is requested only when a control, animation, resize, or interaction changes the scene. It stops after settling and is suspended when the document is hidden.

Haptics and actual device-tilt input are not implemented in this browser study. The moving-light control is the inspection tool for the intended tilt response. Native VoiceOver summaries, keyboard activation, calibrated motion input, and system-respecting haptics belong to a later integration.

## Sixteen kinds

| Kind | Working geometry | Evidence contract for a native version |
| --- | --- | --- |
| Stopwatch | Lathed case, dial, crown, marks | Canonical distance target and exact effort |
| Hourglass | Curved glass chambers, frame, sand solids | Duration independent of decorative sand motion |
| Memory | Domed shell, retaining lip, image, lens | Actual user photo/note and date |
| Energy | Asymmetric flame, convex inset, rising crest | Existing red family and actual calorie evidence |
| Distance | Beveled hexagonal body and convex face | Approved silhouette and canonical unit formatting |
| Sunrise | Half-disc, five rays, raised horizon | First recorded workout, dawn family |
| Pennant | Folded pennant and upper seam | First-distance threshold in canonical meters |
| Returning | Open toroidal band and overlapping arrowhead | Actual return/gap evidence, amber family |
| Week | Seven lobes and seven markers | Complete active week, green family |
| Month | Calendar leaf with 31 July 2026 dots | Correct actual month layout in production |
| Half-year | Six separate beveled fan segments | Actual six-month period, plum family |
| Year | Twelve-lobe seal and twelve month markers | Actual year/period evidence |
| Ribbon | Physically folded ribbon with sample week count | Actual active-week count |
| Activity | Curved/twisted lozenge and opposing contour details | Curve carries no quantitative claim |
| Frequency | Rounded crest with explicit sample threshold | Shape remains stable if threshold changes |
| Collection | Two separate layered crests | Actual count, champagne family |

Every number, period, date, and photo in this artifact is a synthetic fixture. The running mark is a simplified code-built study; use the canonical native activity symbol in the app. No real HealthKit data is read or embedded.

## What still needs design work

The reference objects are interactive prototypes, not finished shipping assets. The supporting family needs individual front/side/reverse refinement, optical sizing, native glyph and type fitting, and an exact check against each canonical period and metric. Reverse inscriptions currently use a shared layout. The memory note-only state is documented but not modeled. The hourglass's sand and real-time glass remain approximations.

The point of this artifact is to let the owner judge the proposed construction directly, move the light, remove the colors, inspect the mesh, and decide which forms deserve the next refinement.

## Route to native implementation

1. Resolve the geometry of the three references in clay, including every edge angle and reverse join.
2. Lock their material response and native semantic color handling at actual grid/detail sizes.
3. Replace study inscriptions and simplified symbols with native typography and canonical activity marks. Exercise long values, alternate units, and missing content.
4. Choose the native rendering path after measuring one completed object on supported devices. Preserve native SwiftUI controls and deterministic evidence ownership.
5. Validate direct manipulation, full turn, Reduced Motion, VoiceOver, app lifecycle suspension, and calibrated tilt/haptics.
6. Extend the proven construction to the remaining kinds, with separate review for every badge.

No native dependency or implementation decision is imposed by this browser prototype. It uses a local Three.js renderer to make the design directly inspectable.
