# Media footprint optimization

Use this workflow when a mod is large because of images or audio. Optimize by
consumer and measured result, not by file extension alone.

## 1. Establish the inventory

Run Mod Doctor with `-AuditMedia`, then run
`scripts/audit-media-footprint.ps1`. Record total bytes by extension, exact
duplicates, explicit references, DDS metadata, and the largest unreferenced
candidates. Read GFX, GUI, asset, music, database, and code consumers before
classifying a file as unused.

Automatic discovery is common. Flags, achievements, main themes, generated
sprite names, models, and dependency callbacks may not contain a literal path.
An absent text reference is a lead, never deletion authority.

## 2. Create a rollback point

Before conversion or deletion, make a dedicated Git commit or tag containing
only the media baseline. Confirm `git status` and preserve unrelated work. Keep
a manifest containing original path, hash, size, dimensions, format, mip count,
consumer, replacement path, replacement hash, and measured savings.

## 3. Classify consumers

Keep DDS unless the current consumer has been verified to accept another
format when any of these apply:

- loading and frontend backgrounds;
- model materials, normal/specular maps, cubemaps, arrays, volume textures, or
  exported engine assets;
- mipmapped textures where the replacement pipeline would discard mip levels;
- a consumer that discovers an exact filename or extension;
- an asset whose alpha mode, block compression, or GPU-ready layout matters.

HOI4 1.19.2 runtime testing showed that loading-screen PNG files failed even
when the decoded pixels and registration were otherwise equivalent. Loading
screens stay DDS. This does not imply that every 2D sprite must use DDS.

Generic 2D sprites with an explicit `texturefile` path are candidates for a
controlled PNG comparison. Validate the exact UI/object consumer first.

## 4. Convert in a temporary directory

Never overwrite the source during the experiment. For each candidate:

1. decode the original with a trusted local library;
2. preserve width, height, alpha, and visible pixels;
3. write the candidate with deterministic settings;
4. decode both files and compare dimensions, color mode, alpha coverage, and a
   pixel-buffer hash;
5. compare actual byte sizes;
6. keep the candidate only when it is smaller and the consumer contract permits
   the format.

PNG is not inherently smaller. DXT1/DXT5 DDS can be smaller than PNG for some
art, while an uncompressed DDS may be much larger. Measured savings decide.

## 5. Apply a coherent batch

Move accepted files, update exact registrations and references, and search for
stale old paths and case mismatches. Keep conversions grouped by consumer class
so a failed runtime test can be reverted without touching unrelated media.

For exact duplicates, do not replace one path with another until every consumer
is known. Shared texture paths save space but can create cross-feature coupling.

## 6. Verify

- rerun Mod Doctor with `-AuditMedia`;
- run the base HOI4 validator and `git diff --check`;
- inspect changed GFX/GUI/music/model registrations;
- compare before/after manifest totals;
- ask whether the user wants an isolated in-game test;
- exercise menus, loading screens, ideas, decisions, portraits, map icons,
  models, and audio categories touched by the batch;
- inspect the fresh `error.log` and restore the checkpoint on failure.

Static pixel equality proves image conversion fidelity, not engine acceptance.
Report both separately.
