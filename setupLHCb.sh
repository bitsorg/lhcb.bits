#!/bin/bash
# setupLHCb.sh - make the bits-built LCG stack the one LHCb's tools build against.
#
# Usage (from bash, after the usual LbEnv setup):
#     source setupLHCb.sh [BINARY_TAG]
#
# LbDevTools picks the toolchain lcg-toolchains/LCG_$LCG_VERSION/$BINARY_TAG.cmake
# from CMAKE_PREFIX_PATH. The bits lcg-view package installs one for its platform
# (and an x86_64_v3 variant); this puts it first and sets BINARY_TAG/LCG_VERSION.
# BINARY_TAG defaults to the x86_64_v3 variant when the CPU supports it.
#
# Environment:
#   BITS_SW    bits install tree (default: sw/ next to this script)
#   BITS_ARCH  install arch holding lcg-view, e.g. x86_64-el9-gcc14-opt
#              (default: the only one found under BITS_SW)
# Source it after LbEnv: LbEnv sets its own BINARY_TAG.

_lb_setup() {
    local sw="${BITS_SW:-$1}" tag="$2" view tc plat
    local views=()
    if [ -n "${BITS_ARCH:-}" ]; then
        [ -d "${sw}/${BITS_ARCH}/lcg-view/latest/lcg-toolchains" ] && views=("${sw}/${BITS_ARCH}/lcg-view/latest")
    else
        for view in "${sw}"/*/lcg-view/latest; do
            [ -d "${view}/lcg-toolchains" ] && views+=("${view}")
        done
    fi
    if [ ${#views[@]} -ne 1 ]; then
        echo "setupLHCb.sh: need exactly one lcg-view under ${sw} (found ${#views[@]}); set BITS_SW/BITS_ARCH" >&2
        return 1
    fi
    view="${views[0]}"
    tc=$(ls -d "${view}"/lcg-toolchains/LCG_* 2>/dev/null | head -1)
    plat=$(ls "${tc}" 2>/dev/null | grep -v '^x86_64_v3-' | head -1)
    plat="${plat%.cmake}"
    if [ -z "${plat}" ]; then
        echo "setupLHCb.sh: no toolchain in ${view}/lcg-toolchains" >&2
        return 1
    fi
    if [ -z "${tag}" ]; then
        tag="${plat}"
        case "${plat}" in
            x86_64-*) /lib64/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q 'x86-64-v3 (supported' \
                          && tag="x86_64_v3-${plat#x86_64-}" ;;
        esac
    fi
    if [ ! -f "${tc}/${tag}.cmake" ]; then
        echo "setupLHCb.sh: no toolchain ${tag} in ${tc}; have: $(ls "${tc}" | sed 's/\.cmake$//' | tr '\n' ' ')" >&2
        return 1
    fi
    command -v lb-run >/dev/null 2>&1 || echo "setupLHCb.sh: note: LbEnv not set up (lb-run not found)" >&2

    export BINARY_TAG="${tag}"
    export LCG_VERSION="${tc##*/LCG_}"
    export LCG_RELEASE_BASE="${view}"
    export CMAKE_PREFIX_PATH="${view}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
    echo "setupLHCb.sh: BINARY_TAG=${BINARY_TAG} LCG_VERSION=${LCG_VERSION} (bits ${view})"
    echo "setupLHCb.sh: for lb-stack-setup (native mode, not docker):"
    echo "    utils/config.py binaryTag ${BINARY_TAG}"
    echo "    utils/config.py lcgVersion ${LCG_VERSION}"
    echo "    utils/config.py cmakePrefixPath '${view}:\$CMAKE_PREFIX_PATH'"
    echo "    utils/config.py useDocker false"
}
if ! _lb_setup "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/sw" "${1:-}"; then
    unset -f _lb_setup
    return 1 2>/dev/null || exit 1
fi
unset -f _lb_setup
