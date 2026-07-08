# CI toolchain image for building and deploying Flutter apps (e.g. RockTrak).
#
# Adds the tools that Flutter app pipelines otherwise reinstall on every run:
#   - Node.js + firebase-tools  (Crashlytics symbol upload, Firebase Hosting)
#   - Ruby + bundler            (fastlane, for Google Play deploys)
#
# Built on top of the Flutter image so those pipelines can just pull this and
# get straight to work. Published as ghcr.io/steffensenchyna/flutter-fastlane.
FROM ghcr.io/steffensenchyna/flutter:stable

LABEL org.opencontainers.image.source=https://github.com/SteffenSenchyna/docker-images-flutter

# Node.js + firebase-tools. firebase-tools is baked in; if a job needs the very
# latest, it can still run `npm install -g firebase-tools` (fast, Node is present).
ARG node_major=22
RUN curl -fsSL "https://deb.nodesource.com/setup_${node_major}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g firebase-tools \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

# Ruby + bundler + build tools for fastlane.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ruby \
        ruby-dev \
    && gem install bundler \
    && rm -rf /var/lib/apt/lists/*
