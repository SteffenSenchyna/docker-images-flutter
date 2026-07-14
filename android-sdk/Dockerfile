# Android SDK base image for the Flutter images.
#
# Published as its own package (ghcr.io/steffensenchyna/android-sdk) so the
# frequently-rebuilt Flutter image can simply pull it instead of rebuilding the
# SDK on every Flutter version bump. Rebuilt only when the versions below change.
#
FROM eclipse-temurin:17-jdk

LABEL org.opencontainers.image.source=https://github.com/SteffenSenchyna/docker-images-flutter

# Overridable at build time. Defaults track Android API 37.
ARG android_sdk_tools_version=13114758
ARG android_platform_version=37.0
ARG android_build_tools_version=37.0.0
ARG android_ndk_version=28.2.13676358
ARG android_cmake_version=3.22.1

ENV ANDROID_HOME=/opt/android-sdk-linux \
    ANDROID_SDK_TOOLS_VERSION=$android_sdk_tools_version \
    ANDROID_PLATFORM_VERSION=$android_platform_version \
    ANDROID_BUILD_TOOLS_VERSION=$android_build_tools_version \
    ANDROID_NDK_VERSION=$android_ndk_version \
    ANDROID_CMAKE_VERSION=$android_cmake_version
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# Tools required by the Android command-line tools and by Flutter itself.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libglu1-mesa \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Install the Android command-line tools into cmdline-tools/latest.
RUN curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" -o /tmp/cmdline-tools.zip \
    && mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm /tmp/cmdline-tools.zip

# Accept licenses, then install the SDK packages.
RUN yes | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses > /dev/null \
    && sdkmanager --sdk_root="${ANDROID_HOME}" \
        "platform-tools" \
        "platforms;android-${ANDROID_PLATFORM_VERSION}" \
        "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
        "ndk;${ANDROID_NDK_VERSION}" \
        "cmake;${ANDROID_CMAKE_VERSION}"
