# Departure Mono reference

Use [Departure Mono](https://departuremono.com/) as a candidate when a product
needs a deliberately lo-fi, pixel-technical typographic voice. Helena Zhang
describes it as a monospaced pixel font inspired by early command-line and
graphical interfaces, tiny late-90s/early-00s pixel fonts, and science-fiction
concepts from film and television.

It is a typeface option, not a ready-made identity. Do not adopt it merely
because the product involves code, AI, terminals, or developer tools.

## Admission gate

1. Name the role it fills in DESIGN.md: display, wordmark, metadata, labels,
   code, or another explicit register. Do not use it as an unexamined body face.
2. Build a real specimen with the product's longest labels, numerals,
   punctuation, mixed case, code when relevant, and representative prose.
3. Compare it against at least two structurally different directions. Pixel
   nostalgia must support the memorable thing, not become the memorable thing
   by accident.
4. Test legibility at every intended size, weight contrast against the body
   face, Windows/macOS rendering, and high-DPI and low-DPI screens.
5. Verify glyph and language coverage before committing it to user-generated
   or localized content. Provide a deliberate fallback stack.

## Implementation notes

- The family is published as a regular, single-weight face in OTF, WOFF, and
  WOFF2 formats. Do not synthesize bold or italic styles.
- The project recommends font sizes in 11px increments for pixel-perfect
  results and invites deliberate tracking adjustments. Treat that as a
  specimen starting point, not permission to make text too small.
- Self-host the smallest required webfont format, preload only when it is
  critical above the fold, and keep the total font budget within the skill's
  100KB compressed gate.
- Preserve tabular alignment where the mono role encodes data, but do not use
  monospace as a substitute for actual grid alignment.

## License and credit

The font is copyright 2022–2024 Helena Zhang and licensed under the
[SIL Open Font License 1.1](https://github.com/rektdeckard/departure-mono/blob/main/public/assets/LICENSE).
It may be used, embedded, bundled, and redistributed under the OFL conditions;
keep the copyright notice and license with redistributed font files. The
website code has a separate MIT license.
