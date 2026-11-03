package: Allen
description: The LHCb HLT1 on GPUs, built for the CPU
version: "%(tag_basename)s"
tag: "v9r1"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/lhcb/Allen.git
requires:
  # AllenDependencies.cmake; TARGET_DEVICE is CPU without a CUDA compiler
  - Rec
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
  # Python modules its python packages import
  - pyeda
  - lxml
build_requires:
  - lhcb-toolchains
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
  # LHCb's compilation flags for the platform (opt, dbg, opt+g), with the defaults'
  # CMAKE_BUILD_TYPE unset so they decide; the externals are this package's dependencies.
  env -u CMAKE_BUILD_TYPE cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$LCG_TOOLCHAINS_DIR/bits-toolchain.cmake" \
    -DLCG_PLATFORM="${LCG_PLATFORM:-$EFFECTIVE_ARCHITECTURE}" \
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
