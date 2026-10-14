# Beautiful UI reference

Use [Beautiful UI](https://www.beautifului.dev/) as a source of interaction
anatomy and copy-paste React/Tailwind code for AI-native product surfaces. It is
not a visual identity and must not override the project's DESIGN.md.

## Use it when the interaction matches

- Loading, thinking, or streaming response states
- Human-in-the-loop approval
- Tool activity, task progress, and recommendations
- Chat composers and prompt bars
- Context, diff, records, and filterable data views
- Search, code display, fine-tuning, and selection actions

Open the live catalog before implementation because its component list and code
may change. Copy the smallest coherent component that satisfies the real flow,
including its keyboard behavior, ARIA semantics, loading/error states, and
reduced-motion treatment. Do not copy demo-only timers, fake data, or ornamental
behavior into production.

## Adaptation gate

1. Map colors, type, radii, spacing, shadows, and motion to DESIGN.md tokens.
2. Keep interaction anatomy and state transitions only when they improve the
   task; remove showcase controls and effects.
3. Integrate with the project's existing primitives before adding dependencies.
4. Test keyboard use, screen-reader labels, focus, touch targets, overflow,
   dark mode when supported, and `prefers-reduced-motion`.
5. Verify the real data lifecycle: idle, pending, streaming/progress, success,
   rejection/cancel, empty, error, retry, and interruption where applicable.
6. Re-run the zero-tolerance list. A polished source can still be the wrong fit.

## License and credit

Beautiful UI states that its components are released under the
[MIT License](https://www.beautifului.dev/license), copyright 2026 Shane
Levine. Preserve the required notice when copying a component and credit
Beautiful UI in the PR description.
