#!/bin/bash
set -e

#CICD_FOLDER need to add this with ssh environment

BUILDER_HOME="${HOME}/${CICD_FOLDER}/builder"
_BREW_HOME="${BUILDER_HOME}/library/brew"
_ANDROID_HOME="${BUILDER_HOME}/library/android"

BREW_VERSION="4.6.7"
JAVA_VERSION="17"

COMMAND_LINE_TOOL_VERSION=13114758
BUILD_TOOLS_VERSION="36.0.0"
ANDROID_SDK_VERSION="android-36"

XCODE_VERSION="16.4"
RUBY_VERSION="3.3"

ZSHRC="${BUILDER_HOME}/.zshrc"
[ -f "${ZSHRC}" ] && rm "${ZSHRC}"
touch "${ZSHRC}"

cat >> "${ZSHRC}" <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
EOF

# Homebrew
if [ ! -d "${_BREW_HOME}" ]; then
    echo "Installing Homebrew..."
    mkdir -p "${_BREW_HOME}"
    git clone --depth 1 https://github.com/Homebrew/brew.git "${_BREW_HOME}"
    git -C "${_BREW_HOME}" fetch --tags --depth 1 --quiet
    git -C "${_BREW_HOME}" -c advice.detachedHead=false checkout "refs/tags/${BREW_VERSION}"
fi

cat >> "${ZSHRC}" <<EOF
BREW_HOME=${_BREW_HOME}
NONINTERACTIVE=1
HOMEBREW_PREFIX=\${BREW_HOME}
HOMEBREW_CELLAR=\${BREW_HOME}/Cellar
HOMEBREW_REPOSITORY=\${BREW_HOME}/Library/Homebrew
HOMEBREW_CACHE=\${BREW_HOME}/cache
HOMEBREW_TEMP=\${BREW_HOME}/tmp
HOMEBREW_CASK_OPTS=\${BREW_HOME}/Applications
HOMEBREW_NO_ENV_HINTS=1
HOMEBREW_NO_AUTO_UPDATE=1
HOMEBREW_DEVELOPER=1
PATH=\${BREW_HOME}/bin:\${BREW_HOME}/sbin:\$PATH
EOF
source "${ZSHRC}"
brew --version

# Android Command Line Tools
if [ ! -d "${_ANDROID_HOME}/cmdline-tools/latest" ]; then
    echo "Installing Android Command Line Tools..."
    mkdir -p "${_ANDROID_HOME}/tmp"
    TMP_ZIP="${_ANDROID_HOME}/tmp/cmdline-tools.zip"
    echo "Downloading command line tools..."
    curl -L -o "${TMP_ZIP}" "https://dl.google.com/android/repository/commandlinetools-mac-${COMMAND_LINE_TOOL_VERSION}_latest.zip"
    echo "Extracting..."
    mkdir -p "${_ANDROID_HOME}/cmdline-tools/latest"
    unzip -q "${TMP_ZIP}" -d "${_ANDROID_HOME}/tmp"
    mv "${_ANDROID_HOME}/tmp/cmdline-tools/"* "${_ANDROID_HOME}/cmdline-tools/latest/"
    rm -rf "${_ANDROID_HOME}/tmp"
fi

cat >> "${ZSHRC}" <<EOF
ANDROID_HOME=${_ANDROID_HOME}
ANDROID_SDK_HOME=${_ANDROID_HOME}
ANDROID_SDK_ROOT=${_ANDROID_HOME}
ANDROID_SDK=${_ANDROID_HOME}
PATH=\${ANDROID_HOME}/cmdline-tools/latest/bin:\${ANDROID_HOME}/platform-tools:\${ANDROID_HOME}/tools:\${ANDROID_HOME}/tools/bin:\$PATH
PATH=${_ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}:\$PATH
EOF
source "${ZSHRC}"
sdkmanager --list_installed

# Java
if ! brew list --formula | grep -q "^openjdk@${JAVA_VERSION}\$"; then
    echo "Installing OpenJDK ${JAVA_VERSION}"
    brew install openjdk@${JAVA_VERSION} || true
fi

_JAVA_HOME="$(brew --prefix openjdk@${JAVA_VERSION})"
cat >> "${ZSHRC}" <<EOF
JAVA_HOME=${_JAVA_HOME}
PATH=\${JAVA_HOME}/bin:\$PATH
EOF
source "${ZSHRC}"
java --version

# Android SDK components
components=("platform-tools" "build-tools;${BUILD_TOOLS_VERSION}" "platforms;${ANDROID_SDK_VERSION}")
needs_install=()
for comp in "${components[@]}"; do
    if ! sdkmanager --list_installed | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' | grep -qx "${comp}"; then
        needs_install+=("${comp}")
    fi
done
if [ ${#needs_install[@]} -gt 0 ]; then
    yes | sdkmanager --licenses
    for comp in "${needs_install[@]}"; do
        echo "Installing ${comp}..."
        sdkmanager "${comp}"
    done
fi

# Ruby
if ! brew list "ruby@${RUBY_VERSION}" &>/dev/null; then
    echo "Installing Ruby ${RUBY_VERSION}..."
    brew install "ruby@${RUBY_VERSION}" || true
fi

_RUBY_HOME="$(brew --prefix "ruby@${RUBY_VERSION}")"
cat >> "${ZSHRC}" <<EOF
RUBY_HOME=${_RUBY_HOME}
PATH=\${RUBY_HOME}/bin:\$PATH
EOF
source "${ZSHRC}"
ruby --version

_GEM_ROOT=$(ruby -e 'require "rubygems"; print Gem.bindir')
cat >> "${ZSHRC}" <<EOF
PATH=${_GEM_ROOT}:\$PATH
EOF
source "${ZSHRC}"

if ! command -v bundler &>/dev/null; then
    echo "Installing Bundler..."
    gem install bundler
fi
bundler --version

# Ios Command Line Tools
if ! command -v xcode-select &>/dev/null; then
    echo "xcode-select is not installed. Please install it."
    exit 1
fi
xcode-select --version

if ! command -v xcodebuild &>/dev/null; then
    echo "xcodebuild is not installed. Please install it by installing Xcode or xcode-select --install"
    exit 1
fi
source "${ZSHRC}"
xcodebuild -version

if ! command -v xcversion &>/dev/null; then
    echo "Installing Xcversion..."
    gem install xcode-install
fi
echo "xcversion $(xcversion --version)"

if [[ "$(xcodebuild -version | head -n1 | awk '{print $2}')" != "${XCODE_VERSION}" ]]; then
    if ! "${_XCVERSION_PATH}" installed | awk '{print $1}' | grep -qx "${XCODE_VERSION}"; then
        echo "Xcode ${XCODE_VERSION} is not installed. Attempting installation..."
        xcversion install "${XCODE_VERSION}" || {
            # Can work because it ask to developper account credential
            # Add a container with volume that contain pre download xcode.xib
            echo "Failed to install Xcode ${XCODE_VERSION}." 
            exit 1
        }
    fi
    echo "Selecting Xcode ${XCODE_VERSION}..."
    XCODE_PATH=$("$_XCVERSION_PATH" select "${XCODE_VERSION}" --print-path)
    xcode-select -s "${XCODE_PATH}"
fi

echo "setup complete."
