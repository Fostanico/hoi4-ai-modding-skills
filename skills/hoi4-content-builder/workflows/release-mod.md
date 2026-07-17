# Release a mod or skill-backed change

1. Confirm target game version, required DLCs/dependencies, supported bookmark,
   descriptor metadata, thumbnail, and `replace_path` behavior.
2. Remove sample placeholders, staging files, private paths, secrets, logs,
   caches, backups, and unrelated source assets from the release tree.
3. Run target validators, encoding checks, conflict/stale-ID searches, override
   audit, and repository diff checks. Record runtime evidence separately.
4. Ensure user-facing localisation, licenses, third-party attribution, and
   redistribution rights cover every bundled code and asset. Do not redistribute
   Paradox or third-party game assets merely because they were verification
   sources.
5. Package from a clean manifest with relative paths and inspect the archive
   listing before publishing. Hash the final archive and record the version.
6. Publish source and tagged releases from a repository when possible so users
   can review history and install only the intended skill/mod directories.
