# Licenses and attribution

Original Element Studio source, procedural geometry, generated textures, documentation and agent skills are under [MIT](LICENSE). Each distributable skill includes that license. The iOS app and native Swift authoring package have no third-party runtime package dependencies.

| Material | License and retained notice |
| --- | --- |
| Helvetiker/MgOpen-derived outline font and lettering | [Font license](NativeAuthoring/Resources/FONT-LICENSE.txt); [native fixture notice](Resources/ElementStudio-LICENSE.txt) |
| Historical geometry produced with Three.js 0.180.0 | [Retained MIT notice](Documentation/Licenses/THREE-LICENSE.txt) |
| Historical geometry produced with Clipper 6.4.2 | [Retained Boost/JSBN notices](Documentation/Licenses/CLIPPER-LICENSE.txt) |

Three.js, Clipper, their JavaScript helpers, and the browser toolchain are no longer distributed as executable source. Their notices remain with the preserved historical fixtures. The native geometry implementation uses Swift and Apple CoreGraphics. Retain the font notice when redistributing letter geometry; the repository MIT license does not replace its terms.

NumPy is an optional development dependency for offline environment/normal-map generation. Its upstream license remains applicable. Apple frameworks, tools and system symbols are provided by the platform and are not relicensed here.

The example collection retains Daybeat inscriptions and its original mark as provenance of the study. The code/asset license does not grant rights to represent another product or use its trademarks as your own branding. Replace `NativeAuthoring/Resources/DaybeatMark.json` and regenerate a new edition when adapting the branding. See [asset provenance](Documentation/ASSET-PROVENANCE.md).
