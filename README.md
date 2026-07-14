# Docker Images for [Flutter](https://flutter.dev/)

[![Build Flutter][build_badge]][build_link]
[![Build Android SDK][android_badge]][android_link]
[![Build Flutter Fastlane][fastlane_badge]][fastlane_link]

Multi-arch (`linux/amd64`, `linux/arm64`) Docker images for [Flutter](https://flutter.dev/),
published to [GitHub Container Registry](#github-container-registry) as
`ghcr.io/steffensenchyna/flutter`.

This repo publishes three packages:

| Package                                                                                                                                | Built from                                               | Rebuilt                                           |
|----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|---------------------------------------------------|
| [`ghcr.io/steffensenchyna/flutter`](https://github.com/SteffenSenchyna/docker-images-flutter/pkgs/container/flutter)                   | [`sdk/Dockerfile`](sdk/Dockerfile)                       | On every Flutter version bump                     |
| [`ghcr.io/steffensenchyna/android-sdk`](https://github.com/SteffenSenchyna/docker-images-flutter/pkgs/container/android-sdk)           | [`android-sdk/Dockerfile`](android-sdk/Dockerfile)      | Only when the Android SDK changes (rare)          |
| [`ghcr.io/steffensenchyna/flutter-fastlane`](https://github.com/SteffenSenchyna/docker-images-flutter/pkgs/container/flutter-fastlane) | [`flutter-fastlane/Dockerfile`](flutter-fastlane/Dockerfile) | When the Flutter image or its own tooling changes |

They stack: `android-sdk` → `flutter` (adds Flutter) → `flutter-fastlane` (adds
Node.js/firebase-tools + Ruby/bundler for app CI/CD). Splitting them keeps the
frequent Flutter rebuilds fast — each layer pulls the cached one below instead of
rebuilding it. `flutter-fastlane` is meant as the CI image for app pipelines
(e.g. GitLab) so those jobs don't reinstall a toolchain on every run.

## Usage

Run any Flutter command against your project by mounting the current directory:

```bash
docker run --rm -it -v ${PWD}:/build --workdir /build ghcr.io/steffensenchyna/flutter:stable flutter test
```

The example above mounts the current working directory and runs `flutter test`.

### Tags

| Tag                 | Tracks                                    |
|---------------------|-------------------------------------------|
| `stable` / `latest` | Latest Flutter **stable** release         |
| `beta`              | Latest Flutter **beta** release           |
| `<version>`         | A specific Flutter version, e.g. `3.44.0` |

## GitHub Container Registry

https://github.com/SteffenSenchyna/docker-images-flutter/pkgs/container/flutter

## How it works

The image is defined in [`sdk/Dockerfile`](sdk/Dockerfile) and is version-agnostic —
the Flutter version is passed in as a build arg. Which version each tag ships is
declared in [`versions.json`](versions.json), the single source of truth:

```json
{
  "latest": "3.44.5",
  "stable": "3.44.5",
  "beta": "3.46.0-0.3.pre"
}
```

The Android SDK base is defined in [`android-sdk/Dockerfile`](android-sdk/Dockerfile),
which installs the Android command-line tools and SDK packages on top of
`eclipse-temurin:17-jdk`. Its versions are pinned as `ARG` defaults in that file.

Four GitHub Actions workflows keep everything current:

- **[Check Flutter versions](.github/workflows/check-flutter-versions.yml)** runs every
  2 hours, updates `versions.json` with the newest stable/beta releases, and opens a
  pull request if anything changed.
- **[Build Flutter](.github/workflows/build.yml)** runs on every push to `main`
  that touches the Flutter image. It builds each channel for `linux/amd64` and
  `linux/arm64` on **native runners** (no QEMU — Flutter's Dart VM aborts under
  emulation), pushes each architecture by digest, then merges them into a single
  multi-arch manifest per channel and publishes to GHCR.
- **[Build Android SDK](.github/workflows/build-android-sdk.yml)** runs only
  when `android-sdk/**` changes (or manually), and publishes the base image.
- **[Build Flutter Fastlane](.github/workflows/build-flutter-fastlane.yml)** runs when
  `flutter-fastlane/**` changes (or after the Flutter image is rebuilt), and publishes
  the CI toolchain image.

All workflows push using the repository's built-in `GITHUB_TOKEN` — no personal
access token required.

The build workflows are **chained** with `workflow_run` triggers so the stack stays
in sync automatically: republishing `android-sdk` triggers a `flutter` rebuild, which
in turn triggers a `flutter-fastlane` rebuild. Each downstream image re-tags both its
`:stable` and its pinned `:<version>` tag, so a Flutter version bump propagates all the
way up without any manual step.

## Building locally

Images are built with [`build.sh`](build.sh), which reads the version for each channel
from `versions.json`. It requires [`jq`](https://jqlang.github.io/jq/).

```bash
# Build one or more channels for your host architecture and load into Docker:
./build.sh stable

# Build every channel:
./build.sh

# Build multi-arch images and push to the registry (requires `docker login ghcr.io`):
PUSH=true ./build.sh stable
```

Local builds default to your host architecture and are loaded into Docker. Setting
`PUSH=true` switches to a multi-arch build and pushes to the registry, which requires
a prior `docker login ghcr.io` with a token that has the `write:packages` scope.

Note: a local `PUSH=true` build cross-compiles the non-host architecture under QEMU,
and Flutter's Dart VM is unreliable under emulation (it can abort mid-build). For
publishing multi-arch images, prefer the CI workflow, which builds each architecture
on a native runner. Local single-arch `--load` builds are unaffected.

`build.sh` builds the Flutter image, which pulls the published Android SDK base. To
build the base image itself, use Docker directly:

```bash
docker buildx build --load --tag ghcr.io/steffensenchyna/android-sdk:37 android-sdk
```

[build_badge]: https://github.com/SteffenSenchyna/docker-images-flutter/actions/workflows/build.yml/badge.svg

[build_link]: https://github.com/SteffenSenchyna/docker-images-flutter/actions/workflows/build.yml

[android_badge]: https://github.com/SteffenSenchyna/docker-images-flutter/actions/workflows/build-android-sdk.yml/badge.svg

[android_link]: https://github.com/SteffenSenchyna/docker-images-flutter/actions/workflows/build-android-sdk.yml

[fastlane_badge]: https://github.com/SteffenSenchyna/docker-images-flutter/actions/workflows/build-flutter-fastlane.yml/badge.svg

[fastlane_link]: https://github.com/SteffenSenchyna/docker-images-flutter/actions/workflows/build-flutter-fastlane.yml
