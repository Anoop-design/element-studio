# Element Studio agent skills

Reusable instructions for building real, editable 3D objects, distilled from this repository's manual geometry, material, lighting, and interaction refinements. The skills use the open [Agent Skills format](https://agentskills.io/specification): ordinary Markdown with YAML metadata and relative reference files. Optional `agents/openai.yaml` files add display metadata only.

| Skill | Use it for |
| --- | --- |
| [element-studio](element-studio/SKILL.md) | Full authoring and tuning workflow, controls, render lifetime, saved looks, verification |
| [procedural-3d-geometry](procedural-3d-geometry/SKILL.md) | Lathed/swept/beveled forms, concave caps, fitted inscriptions, mesh export |
| [realitykit-materials-lighting](realitykit-materials-lighting/SKILL.md) | PBR roles, HDR light, normal maps, native Metal material shaders |

## Use with any coding agent

An agent does not need a plugin to read these instructions. Give it the skill file and a concrete task, for example:

> Read skills/procedural-3d-geometry/SKILL.md and its relevant references. Build a ceramic folded bookmark with a shallow inscription, inspect its front, side and reverse, and preserve its editable construction parameters.

> Read skills/realitykit-materials-lighting/SKILL.md. Build a native glass capsule around a solid insert, with editable light direction and presence. Verify its native transparency and state the optical approximations.

> Read skills/element-studio/SKILL.md. Add a material control to this app while retaining one live renderer, undo grouping, saved-look compatibility, and idle rendering.

For agents that discover installed skills, copy each complete skill directory to the agent's documented skill location. For example, from this checkout, install into a user-chosen directory with:

```sh
python3 scripts/install-skills.py --destination /path/to/agent/skills
```

The installer copies all three directories and the MIT license, refuses existing names, and never changes agent configuration. To update an installed copy, compare changes and explicitly replace it yourself. A previous personal `element-studio` skill may already exist; inspect it before choosing a destination. No home directory, provider, or private MCP integration is assumed. Each skill's reference links stay inside its own directory, so copying one skill also works. Its knowledge can be read alone; running the reference app requires a repository checkout.

Build and test the native implementation on macOS with full Xcode and an iOS 26+ simulator or connected iPhone. Follow the self-contained [native validation guide](element-studio/references/native-validation.md); browser testing is not part of this workflow. Only optional mesh export needs the pinned Node/Playwright dependencies. Apple signing credentials are needed for physical-device builds. The library of techniques does not require Daybeat, HealthKit, an account, or a specific AI subscription.

## Research model preference

Each skill includes self-contained [research delegation guidance](element-studio/references/research-delegation.md). Research goes to Luna subagents in Codex, or Haiku/Sonnet subagents in Claude Code, when the current environment exposes those models. Workers receive only the bounded question and relevant context, then return concise findings. The main agent handles implementation and native verification. The instructions do not change global settings or assume subscription entitlements.

## What was captured

The references preserve the reasons behind the tweaks: polygon offsets instead of shrinking outlines; conforming subdivision before bending; continuous flame and arrow faces; ordered ribbon-notch rows; curved inscription seating; spatially cached projection; softer normal maps; coordinated reflection/key lighting; native thin-glass limitations; stable camera identity; transient mesh inspection; reversible edits; geometry/material versioning; and actual-alpha export. The original builders, shaders, fixtures, and regeneration scripts remain runnable examples in this repository.

See [the learning map](../Documentation/LEARNING-MAP.md) for source symbols and [the release preparation record](../Documentation/OPEN-SOURCE.md) for validation and publication status. Skills are instructions, not a claim of certification by every agent platform. Visual judgment and supported execution tools are still required.
