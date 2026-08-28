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

## Audio rules

- Treat `.ogg` as a container. Inspect the codec and every stream before
  deciding that two files have the same runtime contract.
- Keep in-game music-player/station tracks as Ogg Vorbis. HOI4 1.19.2 runtime
  testing found that Ogg Opus could play as frontend/main-theme music but not
  through the in-game player; those are separate consumers.
- Prefer one encode from a lossless source, normally at 44.1 kHz for music.
  Strip cover art, video, subtitles, data, chapters, and unnecessary metadata,
  and preserve the intended channel layout.
- Vorbis quality values and Opus target bitrates do not guarantee a smaller
  file. Compare actual bytes and audible quality. Codec efficiency is irrelevant
  when the target consumer rejects the codec.
- Keep rollback originals and source mappings outside the release mod. Test the
  exact main-menu and in-game-player paths separately before publishing a batch.

## Animated texture rules

- A GUI animation is a frame sheet consumed by `frameAnimatedSpriteType`, not
  an MP4/GIF played directly by the engine.
- Choose BC1 DDS for opaque animation and BC3 only when real alpha is needed.
  PNG may be smaller on disk but normally expands to RGB/RGBA texture memory,
  so it can use several times the GPU memory of an equal BC sheet.
- Trim repeated frames, crop unused transparent/static edges, and scale for the
  actual consumer. If only a small region moves, a static base plus animated
  crop is a candidate only after seam and layer testing.
- Keep source media, extracted frames, scripts, manifests, and comparison files
  out of the release root. Consolidate related sprite registrations by owning
  subsystem instead of creating one `.gfx` file per animation.

Use the review skill's `workflows/optimize-media.md` and
`scripts/audit-media-footprint.ps1` for an auditable conversion batch.
