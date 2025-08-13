# CHANGELOG.md

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- TBD

## [0.1.0] - 2025-08-13
### Added
- `DioToolkitClient` wrapper around Dio with sensible defaults.
- `Result<T>` + unified `ApiException` (network, timeout, 4xx, 5xx, cancelled, unknown).
- `AuthInterceptor` — automatic `Authorization: Bearer <token>` from provider.
- `RefreshInterceptor` — single-flight token refresh on `401`, queued requests, one replay.
- `RetryInterceptor` — retries for timeouts and `502/503/504` with exponential backoff.
- `CacheInterceptor` — opt-in in-memory cache for GET with TTL via `CacheOptions`.
- `LoggingInterceptor` — lightweight stdout logger.
- Example app under `example/`.
- README with Quick Start, configuration, FAQ, and roadmap.

### Fixed
- N/A

### Changed
- N/A

[Unreleased]: https://github.com/ZoomerDeveloper/dio_toolkit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ZoomerDeveloper/dio_toolkit/releases/tag/v0.1.0

---

## Release links

---

## Maintainer notes

To cut the first release and publish on pub.dev:

```bash
git add .
git commit -m "chore: prepare 0.1.0"
# Tag the release
git tag -a v0.1.0 -m "Initial release: typed results, auth, refresh, retry, cache"
git push --follow-tags origin main

# Dry run publish
dart pub publish --dry-run
# Publish
dart pub publish
```

Update `pubspec.yaml` with repository links:

```yaml
homepage: https://github.com/ZoomerDeveloper/dio_toolkit
repository: https://github.com/ZoomerDeveloper/dio_toolkit
issue_tracker: https://github.com/ZoomerDeveloper/dio_toolkit/issues
```

