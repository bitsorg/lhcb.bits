#!/bin/bash
# setupLHCb.sh - make the bits-built LCG stack the one LHCb's tools build against.
#
# Usage (from bash, after the usual LbEnv setup):
#     source setupLHCb.sh [BINARY_TAG]
#
# LbDevTools picks the toolchain lcg-toolchains/LCG_$LCG_VERSION/$BINARY_TAG.cmake
# from CMAKE_PREFIX_PATH. The bits lcg-view package installs one for its platform
# (and an x86_64_v3 variant); this puts it first, drops LbEnv's LCG and contrib
# trees from CMAKE_PREFIX_PATH and sets BINARY_TAG/LCG_VERSION/LCG_RELEASE_BASE.
# BINARY_TAG defaults to the x86_64_v3 variant when the CPU supports it.
#
# Environment:
#   BITS_SW            bits work dir (default: sw/ next to this script)
#   BITS_ARCH          the arch of lcg-view, e.g. x86_64-el9-gcc14-opt
#                      (default: the only one in BITS_SW, else on CVMFS)
#   BITS_CVMFS_PREFIX  where the community publishes (default: prefix: in
#                      cvmfs.yaml here; empty: never CVMFS)
# lcg-view comes from BITS_SW when built there, else from CVMFS
# ({prefix}/{arch}/Packages/lcg-view/<newest>, as in cvmfs.yaml).

_lb_setup() {
    local here="$1" tag="$2" sw="${BITS_SW:-$1/sw}" cvmfs view tc plat d
    local views=()
    if [ -n "${BITS_CVMFS_PREFIX+set}" ]; then
        cvmfs="${BITS_CVMFS_PREFIX}"
    else
        cvmfs=$(sed -n 's/^prefix: *"\{0,1\}\([^"# ]*\).*$/\1/p' "${here}/cvmfs.yaml" 2>/dev/null)
    fi
    # The local build first; else the newest published one of each arch.
    for d in "${sw}"/${BITS_ARCH:-*}/lcg-view/latest; do
        [ -d "${d}/lcg-toolchains" ] && views+=("${d}")
    done
    if [ ${#views[@]} -eq 0 ] && [ -n "${cvmfs}" ]; then
        for d in "${cvmfs}"/${BITS_ARCH:-*}/Packages/lcg-view; do
            d="${d}/$(ls "${d}" 2>/dev/null | sort -V | tail -1)"
            [ -d "${d}/lcg-toolchains" ] && views+=("${d}")
        done
    fi
    if [ ${#views[@]} -ne 1 ]; then
        echo "setupLHCb.sh: need exactly one lcg-view${BITS_ARCH:+ for ${BITS_ARCH}} in ${sw}${cvmfs:+ or ${cvmfs}} (found ${#views[@]}); set BITS_SW or BITS_ARCH" >&2
        return 1
    fi
    view=$(CDPATH= cd -P "${views[0]}" && pwd)   # the real path, not latest
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

    # LbEnv's .../lib/lcg and .../lib/contrib would win for anything the view lacks.
    local keep=() p
    local - IFS=:
    set -f   # no globbing of the entries (local -: restored on return)
    for p in ${CMAKE_PREFIX_PATH:-}; do
        case "${p}" in */lib/lcg|*/lib/lcg/*|*/lib/contrib|*/lib/contrib/*) ;; *) keep+=("${p}") ;; esac
    done
    export CMAKE_PREFIX_PATH="${view}${keep[*]:+:${keep[*]}}"
    unset IFS
    export BINARY_TAG="${tag}"
    export LCG_VERSION="${tc##*/LCG_}"
    export LCG_RELEASE_BASE="${view}"
    echo "setupLHCb.sh: BINARY_TAG=${BINARY_TAG} LCG_VERSION=${LCG_VERSION}"
    echo "setupLHCb.sh: lcg-view ${view}"
    echo "setupLHCb.sh: for lb-stack-setup (native mode, not docker):"
    echo "    utils/config.py binaryTag ${BINARY_TAG}"
    echo "    utils/config.py lcgVersion ${LCG_VERSION}"
    echo "    utils/config.py cmakePrefixPath '${CMAKE_PREFIX_PATH}'"
    echo "    utils/config.py useDocker false"
}
if ! _lb_setup "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)" "${1:-}"; then
    unset -f _lb_setup
    return 1 2>/dev/null || exit 1
fi
unset -f _lb_setup
