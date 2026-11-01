package: Allen
description: The LHCb HLT1 on GPUs, built for the CPU
version: "%(tag_basename)s"
tag: "v9r1"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/lhcb/Allen.git
requires:
  # AllenDependencies.cmake; TARGET_DEVICE is CPU without a CUDA compiler
  - Rec
  - lcg-view
  - AIDA
  - tbb
  - fmt
  - zeromq
  - libsodium
  - libgit2
  - cppzmq
  - Python
  - Catch2
  - jsonmcpp
  - Boost
  - rangev3
  - yamlcpp
  - pybind11
  - ROOT
build_requires:
  - lcg-toolchains
  - "GCC-Toolchain:(?!osx)"
  - bits-recipe-tools
  - CMake
  - ninja
license: Apache-2.0
---
#!/bin/bash -e
. $(bits-include CMakeRecipe)
MODULE_OPTIONS="--bin --lib --cmake"

function Configure() {
  # As lb-stack-setup builds it: the LHCb toolchain lcg-view made for the platform
  # (its compilation_flags set the build type from it: opt, dbg, opt+g).
  local plat=${LCG_PLATFORM:-$EFFECTIVE_ARCHITECTURE}
  local tc=("$LCG_VIEW_ROOT"/lcg-toolchains/LCG_*/"$plat".cmake)
  [[ -f ${tc[0]} ]] || { echo "no LHCb toolchain for $plat in $LCG_VIEW_ROOT" >&2; exit 1; }
  cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="${tc[0]}" \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DBUILD_TESTING=OFF -DSTANDALONE=OFF   # Allen turns its tests on anyway (Catch2)
}

function PostInstall() {
  cat >> "$MODULEFILE" <<EoF
prepend-path PYTHONPATH        \$PKG_ROOT/python
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path GAUDI_PLUGIN_PATH \$PKG_ROOT/lib
setenv ALLEN_INSTALL_DIR       \$PKG_ROOT
EoF
}
