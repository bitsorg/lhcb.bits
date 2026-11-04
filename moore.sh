package: Moore
description: The LHCb trigger and sprucing applications
version: "%(tag_basename)s"
tag: "v60r1"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/lhcb/Moore.git
requires:
  # MooreDependencies.cmake
  - Allen
  - Python
  - AppConfig
  - FieldMap
  - ParamFiles
  - PRConfig
  - RawEventFormat
  - HltTCK
  - TMVAWeights
  - SprucingConfig
  # Python modules its python packages import
  - cachetools
  - pydantic
  - scikitlearn
  - matplotlib
build_requires:
  - lhcb-toolchains
  - "GCC-Toolchain:(?!osx)"
  - bits-recipe-tools
  - CMake
  - ninja
  # its tests: gaudi_add_pytest collects them at build time
  - pytest
license: GPL-3.0-only
---
#!/bin/bash -e
. $(bits-include CMakeRecipe)
MODULE_OPTIONS="--bin --lib --cmake"

function Configure() {
  # LHCb's flags for the platform (opt, dbg, opt+g) decide, CMAKE_BUILD_TYPE unset; the
  # externals are this package's dependencies. Tests are on (built, not run): Allen's
  # installed AllenDependencies.cmake sets BUILD_TESTING ON for all its consumers anyway.
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
