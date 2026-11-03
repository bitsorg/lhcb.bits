package: Detector
description: The LHCb detector description on DD4hep
version: "%(tag_basename)s"
tag: "v3r17"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/lhcb/Detector.git
requires:
  # DetectorDependencies.cmake (DD4hep with Geant4 units: dd4hep_geant4_units in defaults-lhcb)
  - simple_conddb_cxx
  - DD4hep
  - ROOT
  - fmt
  - yamlcpp
  - rapidyaml
  - jsonmcpp
  - Boost
  - Vc
  - rangev3
  - tbb
build_requires:
  - lcg-toolchains
  - "GCC-Toolchain:(?!osx)"
  - bits-recipe-tools
  - CMake
  - ninja
license: GPL-3.0-only
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
    -DBUILD_TESTING=OFF
}

function PostInstall() {
  cat >> "$MODULEFILE" <<EoF
prepend-path PYTHONPATH        \$PKG_ROOT/python
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path GAUDI_PLUGIN_PATH \$PKG_ROOT/lib
setenv DETECTOR_PROJECT_ROOT   \$PKG_ROOT
EoF
}
