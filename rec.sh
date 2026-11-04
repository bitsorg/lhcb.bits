package: Rec
description: The LHCb reconstruction
version: "%(tag_basename)s"
tag: "v41r1"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/lhcb/Rec.git
requires:
  # RecDependencies.cmake
  - Lbcom
  - AIDA
  - Boost
  - ROOT
  - blas
  - clhep
  - eigen
  - fastjet
  - fmt
  - GSL
  - jsonmcpp
  - Python
  - Vc
  - vdt
  - xgboost
  - catboost
  - flatbuffers
  - yamlcpp
  - TMVAWeights
  # Python modules its python packages import
  - future
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
setenv FUNCTORFACTORY_COMPILER GNU
setenv FUNCTORFACTORY_PRECOMPILED_HEADER \$PKG_ROOT/include/Functors/JIT_includes.h
EoF
}
