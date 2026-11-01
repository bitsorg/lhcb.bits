package: Gaudi
description: The Gaudi event-processing framework
version: "%(tag_basename)s"
tag: "v40r5"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/gaudi/Gaudi.git
requires:
  # GaudiDependencies.cmake
  - lcg-view
  - Boost
  - Python
  - ROOT
  - tbb
  - uuid
  - zlib
  - rangev3
  - cppgsl
  - fmt
  - jsonmcpp
  - AIDA
  - HepPDT
  - clhep
  - XercesC
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
    -DBUILD_TESTING=OFF \
    -DGAUDI_USE_DOXYGEN=OFF
}

function PostInstall() {
  cat >> "$MODULEFILE" <<EoF
prepend-path PYTHONPATH        \$PKG_ROOT/python
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path GAUDI_PLUGIN_PATH \$PKG_ROOT/lib
EoF
}
