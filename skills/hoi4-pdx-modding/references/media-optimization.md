# Media format and footprint rules

Treat an asset path as a contract among the file, its registration, and its
consumer. Extension conversion is therefore a code change, not only image
compression.

## Current portable rules

- Loading and frontend backgrounds remain DDS. A HOI4 1.19.2 runtime test found
  that pixel-equivalent PNG loading screens did not load.
- Explicit generic 2D `texturefile` consumers may accept PNG, but verify the
  exact object class and run the smallest in-game test.
- Model materials, normal/specular maps, cubemaps, arrays, special engine
  textures, and mipmapped DDS files remain DDS unless a current vanilla
  consumer proves another format and the export pipeline preserves semantics.
- Match path case and extension exactly in files and registrations.
- Do not assume PNG is smaller. Compare actual output sizes after preserving
  dimensions, alpha, and decoded pixels.
- Do not call a media file unused solely because a literal path is absent.
  Engine naming conventions and generated consumers exist.

Use the review skill's `workflows/optimize-media.md` and
`scripts/audit-media-footprint.ps1` for an auditable conversion batch.
