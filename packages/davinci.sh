package: DaVinci
description: The LHCb analysis application
version: "%(tag_basename)s"
tag: "v68r1"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/lhcb/DaVinci.git
requires:
  # DaVinciDependencies.cmake
  - Moore
  - Boost
  - Python
  - AppConfig
  - FieldMap
  - ParamFiles
  - QMTestFiles
  - PRConfig
  - HltTCK
  # Python modules its python packages import
  - pydantic
  - Jinja2
build_requires:
  - lhcb-toolchains
  - "GCC-Toolchain:(?!osx)"
  - bits-recipe-tools
  - CMake
  - ninja
  # its tests: gaudi_add_pytest
  - pytest
license: GPL-3.0-only
---
#!/bin/bash -e
. $(bits-include CMakeRecipe)
MODULE_OPTIONS="--bin --lib --cmake"

function Configure() {
  # LHCb's flags for the platform (opt, dbg, opt+g) decide, CMAKE_BUILD_TYPE unset; the
  # externals are this package's dependencies. Tests are configured (built, not run):
  # with BUILD_TESTING=OFF its CMakeLists use test targets Gaudi never creates.
  env -u CMAKE_BUILD_TYPE cmake -S "$BITS_CMAKE_SRC" -B "$BITS_CMAKE_BUILD" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$LCG_TOOLCHAINS_DIR/bits-toolchain.cmake" \
    -DLCG_PLATFORM="${LCG_PLATFORM:-$EFFECTIVE_ARCHITECTURE}" \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DBUILD_TESTING=ON -DBUILD_FUNCTOR_CACHE=OFF
}

function PostInstall() {
  cat >> "$MODULEFILE" <<EoF
prepend-path PYTHONPATH        \$PKG_ROOT/python
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path GAUDI_PLUGIN_PATH \$PKG_ROOT/lib
EoF
}
