#!/bin/bash
set -e

#CICD_FOLDER need to add this with ssh environment
#sudo DevToolsSecurity -enable Needed on Mac to allow dev tool
BUILDER_HOME=${HOME}/${CICD_FOLDER}/qa

_JAVA_HOME=${BUILDER_HOME}/library/java
JAVA_VERSION=17
JAVA_JDK_URL=https://download.java.net/java/GA/jdk${JAVA_VERSION}.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-${JAVA_VERSION}.0.2_macos-aarch64_bin.tar.gz

_NODE_HOME=${BUILDER_HOME}/library/node
NODE_VERSION=22.21.1
NODE_URL=https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-darwin-arm64.tar.gz

APPIUM_VERSION=2.11.3
APPIUM_DRIVER_VERSION=9.10.5

_BREW_HOME=${BUILDER_HOME}/library/brew
BREW_VERSION=4.6.7
BREW_GIT_URL=https://github.com/Homebrew/brew.git

ZSHRC=${BUILDER_HOME}/.zshrc
[ -f "${ZSHRC}" ] && rm "${ZSHRC}"
touch "${ZSHRC}"

# Java
if [ ! -d "${_JAVA_HOME}/Contents" ]; then
    echo "Installing Java from ${JAVA_JDK_URL}"
    mkdir -p "${_JAVA_HOME}"
    TMPDIR=$(mktemp -d)
    curl -fsSL "${JAVA_JDK_URL}" -o "${TMPDIR}/openjdk.tar.gz"
    tar -xzf "${TMPDIR}/openjdk.tar.gz" -C "${TMPDIR}"
    mv "${TMPDIR}"/jdk-17*/* "${_JAVA_HOME}/"
    rm -rf "${TMPDIR}"
fi

cat >> "${ZSHRC}" <<EOF
JAVA_HOME=${_JAVA_HOME}/Contents/Home
PATH=\${JAVA_HOME}/bin:\$PATH
EOF
source "${ZSHRC}"
java --version

# NodeJs
if [ ! -d "${_NODE_HOME}/bin" ]; then
    echo "Installing NodeJs from ${NODE_URL}"
    mkdir -p "${_NODE_HOME}"
    TMPDIR=$(mktemp -d)
    curl -fsSL "${NODE_URL}" -o "${TMPDIR}/node.tar.gz"
    tar -xzf "${TMPDIR}/node.tar.gz" -C "${TMPDIR}"
    mv "${TMPDIR}/node-"*/* "${_NODE_HOME}/"
    rm -rf "${TMPDIR}"
fi

cat >> "${ZSHRC}" <<EOF
NODE_HOME=${_NODE_HOME}
PATH=\${NODE_HOME}/bin:\$PATH
EOF
source "${ZSHRC}"
echo "node $(node --version)"
echo "npm $(npm --version)"

# Ios
if ! /usr/bin/arch -x86_64 /usr/bin/true &>/dev/null; then
    echo "Installing Rosetta..."
    softwareupdate --install-rosetta --agree-to-license || true
fi

# Appium
CURRENT_APPIUM_VERSION=$(appium --version 2>/dev/null || true)
if [[ -z "$CURRENT_APPIUM_VERSION" ]]; then
    echo "Installing appium@${APPIUM_VERSION}..."
    npm install -g appium@${APPIUM_VERSION}
elif [[ "$CURRENT_APPIUM_VERSION" != "$APPIUM_VERSION" ]]; then
    echo "Warning: Appium version ${CURRENT_APPIUM_VERSION} is installed, but required is ${APPIUM_VERSION}"
fi
echo "appium $(appium --version)"

# Appium driver
CURRENT_APPIUM_DRIVER_VERSION=$(appium driver list --installed --json | jq -r '.xcuitest.version // empty')
if [[ -z "$CURRENT_APPIUM_DRIVER_VERSION" ]]; then
    echo "Installing appium driver xcuitest@${APPIUM_DRIVER_VERSION}..."
    appium driver install xcuitest@${APPIUM_DRIVER_VERSION}
elif [[ "$CURRENT_APPIUM_DRIVER_VERSION" != "$APPIUM_DRIVER_VERSION" ]]; then
    echo "Warning: xcuitest driver version $CURRENT_APPIUM_DRIVER_VERSION is installed, but required is $APPIUM_DRIVER_VERSION"
fi
echo "appium-driver $(appium driver list --installed --json | jq -r '.xcuitest.version // empty')"

# Homebrew
if [ ! -d "${_BREW_HOME}/bin" ]; then
    echo "Installing Homebrew..."
    mkdir -p "${_BREW_HOME}"
    git clone --depth 1 "${BREW_GIT_URL}" "${_BREW_HOME}"
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

# Appium required
if ! brew tap | grep -q "^wix/brew\$"; then
    echo "Tapping wix/brew..."
    brew tap wix/brew
fi

if ! command -v applesimutils &>/dev/null; then
    echo "Installing applesimutils..."
    brew install --build-from-source applesimutils
fi
applesimutils --version

if ! command -v ios-deploy &>/dev/null; then
    echo "Installing ios-deploy..."
    brew install --build-from-source ios-deploy
fi
echo "ios-deploy $(ios-deploy --version)"

if ! command -v set-simulator-location &>/dev/null; then
    echo "Installing set-simulator-location..."
    brew install --build-from-source lyft/formulae/set-simulator-location
fi
echo "set-simulator-location $(command -v set-simulator-location &>/dev/null && echo "ok")"

if ! command -v appium-doctor &>/dev/null; then
    echo "Installing global npm package: appium-doctor@1.16.2..."
    npm install -g appium-doctor@1.16.2
fi
echo "appium-doctor $(appium-doctor --version)"
appium-doctor

echo "setup complete."
