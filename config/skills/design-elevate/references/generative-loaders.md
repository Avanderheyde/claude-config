# Generative Loaders reference

Use [Generative Loaders](https://generativeloaders.com/) as an implementation
option for genuine text, inline, or image generation waits in React. It is not
a general loading system and must not override the project's DESIGN.md.

## Admission gate

Add it only when every answer is yes:

1. Is the user waiting for an actual generative operation, rather than routine
   navigation, validation, or data fetching?
2. Does the product expose a real pending or streaming state to drive it?
3. Will motion make the state easier to understand without moving readable
   content or implying fake progress?
4. Does DESIGN.md allow this amount and character of motion?
5. Can the project accept a React dependency and its required stylesheet?

If any answer is no, use the project's existing status treatment, a restrained
skeleton, or plain status copy instead. Do not install a component merely to
make a quiet screen busier.

## Choose by semantic role

- **TextLoader**: generated copy where the component receives the complete
  accumulated response. Pass the full value, not only the latest token.
- **InlineLoader**: compact generation status beside a label, control, or
  conversation turn. Avoid duplicate announcements.
- **ImageLoader**: an image-generation frame whose geometry is known before
  the result arrives. Preserve dimensions to prevent layout shift.

Choose the quietest variant that communicates the state. Map color, type,
timing, density, and geometry to DESIGN.md tokens.

## Integration and verification

1. Install `generative-loaders` and import its stylesheet once at the app root.
2. Wire it to the real lifecycle: pending, streaming when applicable, success,
   cancel, error, retry, and interruption.
3. Verify live-region behavior so nested components do not announce twice.
4. Test `prefers-reduced-motion`, SSR, slow and failed requests, localization,
   and the final-content handoff.
5. Confirm that removing animation still leaves a meaningful waiting state.

## License and credit

Generative Loaders is published under the
[MIT License](https://github.com/kasturikhanke/generative-loaders/blob/main/LICENSE),
copyright Kasturi Khanke and contributors. Preserve its required notice and
credit the source in the PR description when adopting it.
