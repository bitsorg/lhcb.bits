package: Gaudi
description: The Gaudi event-processing framework
version: "%(tag_basename)s"
tag: "v40r5"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/gaudi/Gaudi.git
requires:
  # GaudiDependencies.cmake
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
  # Python modules its python packages import
  - PyYAML
  - networkx
build_requires:
  - lhcb-toolchains
  - "GCC-Toolchain:(?!osx)"
  - bits-recipe-tools
  - CMake
  - ninja
  # its tests: Catch2 (CMakeLists.txt), gaudi_add_pytest (pytest; coverage for GaudiConfiguration)
  - Catch2
  - pytest
  - coverage
license: Apache-2.0
---
#!/bin/bash -e
. $(bits-include CMakeRecipe)
MODULE_OPTIONS="--bin --lib --cmake"

function Configure() {
  # LHCb's flags for the platform (opt, dbg, opt+g) decide, CMAKE_BUILD_TYPE unset; the
  # externals are this package's dependencies. Tests are configured (built, not run):
  # LHCb's test code links GaudiTestSuiteLib, which Gaudi builds only with its tests.
  env -u CMAKE_BUILD_TYPE cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$LCG_TOOLCHAINS_DIR/bits-toolchain.cmake" \
    -DLCG_PLATFORM="${LCG_PLATFORM:-$EFFECTIVE_ARCHITECTURE}" \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DBUILD_TESTING=ON \
    -DGAUDI_USE_DOXYGEN=OFF
}

function PostInstall() {
  cat >> "$MODULEFILE" <<EoF
prepend-path PYTHONPATH        \$PKG_ROOT/python
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path GAUDI_PLUGIN_PATH \$PKG_ROOT/lib
EoF
}
