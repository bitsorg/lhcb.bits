package: LHCb
description: The LHCb core software (event model, conditions, I/O)
version: "%(tag_basename)s"
tag: "v60r1"   # LHCb stack RTA/2026.08.30 (LCG 108c)
source: https://gitlab.cern.ch/lhcb/LHCb.git
requires:
  # LHCbDependencies.cmake
  - Gaudi
  - Detector
  - DD4hep
  - AIDA
  - Boost
  - clhep
  - eigen
  - fmt
  - GSL
  - jsonmcpp
  - onnxruntime
  - OpenSSL
  - Python
  - rangev3
  - ROOT
  - tbb
  - Vc
  - vdt
  - XercesC
  - yamlcpp
  - libgit2
  - zeromq
  - libsodium
  - cppzmq
  - zstd
  - RELAX
  - blas
  - torch
  - FieldMap
  - ParamFiles
  - PRConfig
  - RawEventFormat
  - HltTCK
  # Python modules its python packages import
  - PyYAML
  - click
  - pydot
  - pydantic
  - wrapt
  - future
build_requires:
  - lhcb-toolchains
  - "GCC-Toolchain:(?!osx)"
  - bits-recipe-tools
  - CMake
  - ninja
  # its tests: LHCbDependencies.cmake (Catch2), gaudi_add_pytest (pytest)
  - Catch2
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
    -DBUILD_TESTING=ON
}

function PostInstall() {
  cat >> "$MODULEFILE" <<EoF
prepend-path PYTHONPATH        \$PKG_ROOT/python
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path GAUDI_PLUGIN_PATH \$PKG_ROOT/lib
setenv PYTHONHASHSEED       0
setenv OPENBLAS_NUM_THREADS 1
setenv OMP_THREAD_LIMIT     1
EoF
}
