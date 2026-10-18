# Delegate research without filling the main context

For this workflow, delegate external lookups, broad repository exploration, and API/SDK research to an isolated research subagent. The main agent implements, integrates, and verifies the result; it may read the instructions, exact files it is editing, native test diagnostics, and compact research findings. Do not perform broad research in the main conversation or paste full search logs into it.

## Select the available research model

- **Codex subscription environment:** prefer a currently available **Luna** subagent. Discover the models exposed by the current host/tool; for example, a host advertising `gpt-6-luna` can select it explicitly. Do not infer entitlement from the subscription name, invent a model ID, or silently inherit the main agent's more expensive model for research.
- **Claude Code subscription environment:** use **Haiku** for narrow searches and source lookups. Use **Sonnet** when the question needs harder technical synthesis or conflicting evidence resolved. In Claude Code subagent definitions, the documented model aliases are `model: haiku` and `model: sonnet`; confirm they are available in the user's environment. Per-invocation selection can override a subagent's model. See the official [subagent model guidance](https://code.claude.com/docs/en/sub-agents#choose-a-model).
- **Other agents:** use their available lightweight isolated research worker. Keep the skill usable without a particular provider.

If the requested lightweight model is unavailable, report that and use another confirmed lightweight subagent only if it fits the user's preference. If no suitable subagent exists, continue implementation that needs no research and ask before doing broad research in the main context. Do not silently switch to an inherited high-cost model, start separately billed API jobs, or change global agent settings to satisfy the preference.

## Keep the handoff small

Give the worker one bounded question, the relevant file paths or short excerpts, constraints, and a stopping condition. Start with a fresh context rather than copying the entire conversation. Run workers in parallel only for independent questions; reuse the results instead of repeating searches. Avoid nested research chains.

Ask for a concise return, normally at most 400 words: conclusion, decisive evidence with source links or file/symbol references, uncertainty, and the recommended next action. Keep raw pages and exploration logs in the worker. Stop the worker when the question is answered. The main agent reviews the findings, checks consequential claims where needed, and carries out the implementation and native tests.

Example handoff:

> Research only: find the native mesh/material integration points for one new procedural shape. Read the renderer, asset loader, and settings definitions. Return the necessary symbols, compatibility risks, and a minimal implementation recommendation with file references. Do not edit files, run broad test suites, or delegate again.

Subagents isolate context; delegation still consumes tokens and does not guarantee lower total cost. Use the smallest sufficient scope and avoid dispatching a worker for a fact already established in the task. Claude Code describes its context isolation in the official [subagent documentation](https://code.claude.com/docs/en/sub-agents#manage-subagent-context). Model availability and billing remain properties of the actual host/account, not promises made by this skill.
