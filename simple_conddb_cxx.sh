package: simple_conddb_cxx
description: LHCb's conditions database reader (C++ over Rust), used by Detector
version: "%(tag_basename)s"
tag: "v0.1.0"
source: https://gitlab.cern.ch/lhcb/simple_conddb_cxx.git
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - bits-recipe-tools
  - CMake
  # Its CMake fetches Corrosion and CLI11 and cargo the crates: the build needs network.
  - rust
license: Apache-2.0
---
#!/bin/bash -e
. $(bits-include CMakeRecipe)
MODULE_OPTIONS="--bin --lib --cmake"
